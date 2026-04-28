import os
import json
import torch
import torch.nn as nn
from torch.utils.data import DataLoader
from torch.optim import AdamW
from transformers import AutoTokenizer, AutoModelForSequenceClassification, get_scheduler
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix, f1_score
from tqdm.auto import tqdm
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt
from collections import Counter
import copy

# --- Matplotlib 한글 폰트 설정 ---
plt.rc('font', family='Malgun Gothic')
plt.rc('axes', unicode_minus=False)

# --- 0. 설정 (Configuration) ---
MODEL_NAME = "monologg/koelectra-small-v3-discriminator"
TRAIN_JSON_PATH = 'aihub_data.json'
VALIDATION_JSON_PATH = 'aihub.data.Validation.json'
SAVE_PATH = "./fine-tuned-koelectra-emotion-model-small-best-v14" # v14로 경로 변경

# 하이퍼파라미터
EPOCHS = 30
BATCH_SIZE = 16
# [⭐️ 최종 변경] 학습률을 낮춰 더 세밀하게 최적점을 탐색합니다.
LEARNING_RATE = 1e-5
WEIGHT_DECAY = 0.1
LABEL_SMOOTHING = 0.1
PATIENCE = 5
DROPOUT_RATE = 0.3

# device 설정
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# 저장 디렉토리 미리 생성
if not os.path.exists(SAVE_PATH):
    os.makedirs(SAVE_PATH)
print(f"저장 경로: {SAVE_PATH}")

# --- 1. 모델 및 토크나이저 준비 ---
print("\n--- 1. 모델 및 토크나이저 로딩 ---")
emotion_labels = ["분노", "슬픔", "불안", "상처", "당황", "기쁨"]
num_labels = len(emotion_labels)
label_to_id = {label: i for i, label in enumerate(emotion_labels)}
id_to_label = {i: label for i, label in enumerate(emotion_labels)}

tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)
model = AutoModelForSequenceClassification.from_pretrained(
    MODEL_NAME, num_labels=num_labels, id2label=id_to_label, label2id=label_to_id
)

model.classifier.dropout.p = DROPOUT_RATE
print(f"모델 분류기 드롭아웃이 {DROPOUT_RATE}으로 설정되었습니다.")

model.to(device)
print(f"모델이 {num_labels}개의 클래스로 설정되었습니다: {emotion_labels}")

# --- 2. 데이터셋 준비 ---
print("\n--- 2. 데이터 준비 및 전처리 ---")
emotion_code_to_id = {
    **{f'E{i}': label_to_id['분노'] for i in range(10, 20)},
    **{f'E{i}': label_to_id['슬픔'] for i in range(20, 30)},
    **{f'E{i}': label_to_id['불안'] for i in range(30, 40)},
    **{f'E{i}': label_to_id['상처'] for i in range(40, 50)},
    **{f'E{i}': label_to_id['당황'] for i in range(50, 60)},
    **{f'E{i}': label_to_id['기쁨'] for i in range(60, 70)},
}

def load_data_from_json(file_path, code_map):
    texts, labels = [], []
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        for item in data:
            emotion_code = item.get('profile', {}).get('emotion', {}).get('type')
            
            content = item.get('talk', {}).get('content', {})
            user_utterances = [content.get(f'HS0{i}') for i in range(1, 4)]
            full_text = " ".join(t for t in user_utterances if t and t.strip())

            if emotion_code in code_map and full_text:
                texts.append(full_text)
                labels.append(code_map[emotion_code])
        print(f"'{file_path}' 파일에서 {len(texts)}개의 유효 샘플을 로드했습니다. (전체 대화 맥락 사용)")
        return texts, labels
    except FileNotFoundError:
        print(f"오류: '{file_path}' 파일을 찾을 수 없습니다.")
        return None, None

train_texts, train_labels = load_data_from_json(TRAIN_JSON_PATH, emotion_code_to_id)
val_texts, val_labels = load_data_from_json(VALIDATION_JSON_PATH, emotion_code_to_id)

if not train_texts or not val_texts:
    print("\n🚨 학습 또는 검증 데이터가 없습니다. JSON 파일 경로를 확인해주세요.")
    exit()

print("\n--- 2.5. 학습 데이터 분포 확인 및 가중치 계산 ---")
label_counts = Counter(train_labels)
print("각 감정별 학습 데이터 개수:")
for label_id, count in sorted(label_counts.items()):
    print(f"  {id_to_label[label_id]}: {count}개")

class_counts_list = [label_counts.get(i, 0) for i in range(num_labels)]
class_weights = [len(train_labels) / count if count > 0 else 0 for count in class_counts_list]
class_weights_tensor = torch.tensor(class_weights, dtype=torch.float).to(device)
print(f"\n계산된 클래스 가중치: {class_weights_tensor.cpu().numpy()}")

train_encodings = tokenizer(train_texts, truncation=True, padding=True, max_length=128)
val_encodings = tokenizer(val_texts, truncation=True, padding=True, max_length=128)

class EmotionDataset(torch.utils.data.Dataset):
    def __init__(self, encodings, labels):
        self.encodings = encodings
        self.labels = labels
    
    def __getitem__(self, idx):
        item = {key: torch.tensor(val[idx]) for key, val in self.encodings.items()}
        item['labels'] = torch.tensor(self.labels[idx])
        return item
    
    def __len__(self):
        return len(self.labels)

train_dataset = EmotionDataset(train_encodings, train_labels)
val_dataset = EmotionDataset(val_encodings, val_labels)

train_loader = DataLoader(train_dataset, batch_size=BATCH_SIZE, shuffle=True)
val_loader = DataLoader(val_dataset, batch_size=BATCH_SIZE)
print("데이터셋 및 데이터로더 준비 완료.\n")

# --- 3. 모델 미세 조정 ---
print("--- 3. 모델 미세 조정 시작 ---")
print(f"학습 디바이스: {device}")
print(f"라벨 스무딩: {LABEL_SMOOTHING}")
print(f"학습률: {LEARNING_RATE}")
print(f"가중치 감쇠: {WEIGHT_DECAY}")
print(f"드롭아웃: {DROPOUT_RATE}")

optimizer = AdamW(model.parameters(), lr=LEARNING_RATE, weight_decay=WEIGHT_DECAY)

num_training_steps = EPOCHS * len(train_loader)
num_warmup_steps = int(num_training_steps * 0.1)

lr_scheduler = get_scheduler(
    name="linear", 
    optimizer=optimizer,
    num_warmup_steps=num_warmup_steps, 
    num_training_steps=num_training_steps
)
print(f"스케줄러: linear")

progress_bar = tqdm(range(num_training_steps), desc="Training Progress")

loss_fct = nn.CrossEntropyLoss(
    weight=class_weights_tensor,
    label_smoothing=LABEL_SMOOTHING
)
print(f"손실 함수: CrossEntropyLoss (클래스 가중치, 라벨 스무딩 적용)")

best_val_loss = float('inf')
best_val_f1 = 0.0

history = {
    'train_loss': [],
    'val_loss': [],
    'val_f1': [],
    'val_accuracy': []
}

patience = PATIENCE
patience_counter = 0
best_model_state = None

for epoch in range(EPOCHS):
    # === 학습 단계 ===
    model.train()
    total_train_loss = 0
    
    for batch in train_loader:
        input_ids = batch['input_ids'].to(device)
        attention_mask = batch['attention_mask'].to(device)
        labels = batch['labels'].to(device)
        
        outputs = model(input_ids=input_ids, attention_mask=attention_mask)
        logits = outputs.logits
        loss = loss_fct(logits, labels)
        
        total_train_loss += loss.item()
        
        loss.backward()
        optimizer.step()
        lr_scheduler.step()
        optimizer.zero_grad()
        progress_bar.update(1)
    
    avg_train_loss = total_train_loss / len(train_loader)
    
    # === 검증 단계 ===
    model.eval()
    total_val_loss = 0
    val_preds = []
    val_true = []
    
    with torch.no_grad():
        for batch in val_loader:
            input_ids = batch['input_ids'].to(device)
            attention_mask = batch['attention_mask'].to(device)
            labels = batch['labels'].to(device)
            
            outputs = model(input_ids=input_ids, attention_mask=attention_mask)
            logits = outputs.logits
            loss = loss_fct(logits, labels)
            total_val_loss += loss.item()
            
            predictions = torch.argmax(logits, dim=-1)
            val_preds.extend(predictions.cpu().numpy())
            val_true.extend(labels.cpu().numpy())
    
    avg_val_loss = total_val_loss / len(val_loader)
    
    val_f1 = f1_score(val_true, val_preds, average='macro', zero_division=0)
    val_accuracy = accuracy_score(val_true, val_preds)
    
    history['train_loss'].append(avg_train_loss)
    history['val_loss'].append(avg_val_loss)
    history['val_f1'].append(val_f1)
    history['val_accuracy'].append(val_accuracy)
    
    print(f"\nEpoch {epoch+1}/{EPOCHS}")
    print(f"  Train Loss: {avg_train_loss:.4f} | Val Loss: {avg_val_loss:.4f}")
    print(f"  Val F1: {val_f1:.4f} | Val Accuracy: {val_accuracy:.4f}")
    
    if val_f1 > best_val_f1:
        best_val_f1 = val_f1
        best_val_loss = avg_val_loss
        patience_counter = 0
        best_model_state = copy.deepcopy(model.state_dict())
        print(f"  ✓ 성능 개선! Best F1: {best_val_f1:.4f}, Val Loss: {best_val_loss:.4f}")
    else:
        patience_counter += 1
        print(f"  ✗ 개선 없음. Patience: {patience_counter}/{patience}")
        
        if patience_counter >= patience:
            print(f"\n{patience}회 연속 개선 없음 → 조기 종료!")
            break

if best_model_state:
    model.load_state_dict(best_model_state)
    print(f"\n최적 모델 로드 완료 (Best F1: {best_val_f1:.4f})\n")

# --- 3.5. 학습 과정 시각화 ---
print("--- 3.5. 학습 과정 시각화 ---")
epochs_ran = len(history['train_loss'])
x_axis = range(1, epochs_ran + 1)

fig, axes = plt.subplots(1, 2, figsize=(16, 6))

axes[0].plot(x_axis, history['train_loss'], 'bo-', label='Train Loss', linewidth=2, markersize=4)
axes[0].plot(x_axis, history['val_loss'], 'ro-', label='Val Loss', linewidth=2, markersize=4)
axes[0].set_title(f'학습 손실 그래프 (LR: {LEARNING_RATE}, WD: {WEIGHT_DECAY}, Dropout: {DROPOUT_RATE})', fontsize=14, fontweight='bold')
axes[0].set_xlabel('Epochs', fontsize=12)
axes[0].set_ylabel('Loss', fontsize=12)
axes[0].legend(fontsize=11)
axes[0].grid(True, alpha=0.3)
if epochs_ran <= 30:
    axes[0].set_xticks(x_axis)

axes[1].plot(x_axis, history['val_f1'], 'go-', label='Val F1-Score', linewidth=2, markersize=4)
axes[1].plot(x_axis, history['val_accuracy'], 'mo-', label='Val Accuracy', linewidth=2, markersize=4)
axes[1].set_title('검증 성능 그래프', fontsize=14, fontweight='bold')
axes[1].set_xlabel('Epochs', fontsize=12)
axes[1].set_ylabel('Score', fontsize=12)
axes[1].legend(fontsize=11)
axes[1].grid(True, alpha=0.3)
axes[1].set_ylim([0.4, 1.0])
if epochs_ran <= 30:
    axes[1].set_xticks(x_axis)

plt.tight_layout()

graph_save_path = os.path.join(SAVE_PATH, 'training_graphs_v14.png')
plt.savefig(graph_save_path, dpi=150, bbox_inches='tight')
print(f"학습 그래프를 '{graph_save_path}'에 저장했습니다.")
plt.show()

# --- 4. 모델 성능 평가 ---
print("\n--- 4. 검증 데이터셋으로 모델 성능 평가 ---")
model.eval()
all_preds, all_labels = [], []

with torch.no_grad():
    for batch in val_loader:
        batch = {k: v.to(device) for k, v in batch.items()}
        outputs = model(input_ids=batch['input_ids'], attention_mask=batch['attention_mask'])
        logits = outputs.logits
        predictions = torch.argmax(logits, dim=-1)
        all_preds.extend(predictions.cpu().numpy())
        all_labels.extend(batch['labels'].cpu().numpy())

accuracy = accuracy_score(all_labels, all_preds)
macro_f1 = f1_score(all_labels, all_preds, average='macro', zero_division=0)
report = classification_report(all_labels, all_preds, target_names=emotion_labels, zero_division=0)

print(f"\n📊 최종 성능")
print(f"  정확도 (Accuracy): {accuracy:.4f}")
print(f"  Macro F1-Score: {macro_f1:.4f}")
print("\n분류 리포트:")
print(report)

# --- 4.5. Confusion Matrix 시각화 ---
print("\n--- 4.5. Confusion Matrix 생성 ---")
cm = confusion_matrix(all_labels, all_preds)

plt.figure(figsize=(12, 10))
sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', 
            xticklabels=emotion_labels, yticklabels=emotion_labels,
            cbar_kws={'label': '샘플 수'})
plt.title(f'Confusion Matrix (F1: {macro_f1:.4f})', fontsize=16, fontweight='bold')
plt.ylabel('실제 값 (True Labels)', fontsize=12)
plt.xlabel('예측 값 (Predicted Labels)', fontsize=12)

cm_save_path = os.path.join(SAVE_PATH, 'confusion_matrix_v14.png')
plt.savefig(cm_save_path, dpi=150, bbox_inches='tight')
print(f"Confusion Matrix를 '{cm_save_path}'에 저장했습니다.")
plt.show()

# --- 5. 모델 저장 및 최종 테스트 ---
print("\n--- 5. 모델 저장 및 최종 테스트 ---")
model.save_pretrained(SAVE_PATH)
tokenizer.save_pretrained(SAVE_PATH)
print(f"미세 조정된 모델을 '{SAVE_PATH}'에 저장했습니다.")

history_save_path = os.path.join(SAVE_PATH, 'training_history_v14.json')
training_info = {
    'history': history,
    'best_val_f1': best_val_f1,
    'best_val_loss': best_val_loss,
    'final_accuracy': float(accuracy),
    'final_macro_f1': float(macro_f1),
    'hyperparameters': {
        'epochs': EPOCHS,
        'batch_size': BATCH_SIZE,
        'learning_rate': LEARNING_RATE,
        'weight_decay': WEIGHT_DECAY,
        'label_smoothing': LABEL_SMOOTHING,
        'dropout_rate': DROPOUT_RATE,
        'patience': patience,
        'scheduler': 'linear',
        'loss_function': 'CrossEntropyLoss'
    },
    'model_name': MODEL_NAME,
    'emotion_labels': emotion_labels,
}

with open(history_save_path, 'w', encoding='utf-8') as f:
    json.dump(training_info, f, indent=4, ensure_ascii=False)
print(f"학습 기록을 '{history_save_path}'에 저장했습니다.")

# 최종 테스트
from transformers import pipeline
classifier = pipeline(
    "text-classification",
    model=SAVE_PATH,
    tokenizer=SAVE_PATH,
    device=0 if torch.cuda.is_available() else -1
)

test_sentences = [
    "오늘 너무 행복한 하루였어.",
    "아무것도 하기 싫고 우울해.",
    "짜증나 진짜! 왜 이렇게 안 풀리는 거야.",
    "갑자기 왜 그래? 너무 당황스럽다.",
    "그런 말을 들으니 상처받았어.",
    "좀 걱정돼서 잠도 안 와."
]

print("\n--- 최종 테스트 ---")
result = classifier(test_sentences)
for sentence, pred in zip(test_sentences, result):
    print(f"  '{sentence}'")
    print(f"    → {pred['label']} (신뢰도: {pred['score']:.4f})")

print(f"\n✅ 학습 완료! 최고 F1-Score: {best_val_f1:.4f}")