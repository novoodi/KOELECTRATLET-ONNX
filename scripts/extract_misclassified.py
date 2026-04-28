import os
import json
import torch
from torch.utils.data import DataLoader
from transformers import AutoTokenizer, AutoModelForSequenceClassification
from tqdm.auto import tqdm

# --- 1. 설정 (Configuration) ---
# 가장 성능이 좋았던 모델의 경로를 지정합니다.
MODEL_PATH = "./fine-tuned-koelectra-emotion-model-small-best-v12" 
VALIDATION_JSON_PATH = 'aihub.data.Validation.json'
OUTPUT_FILE_HURT_AS_SAD = 'misclassified_hurt_as_sad.json'
OUTPUT_FILE_FLUSTERED_AS_ANXIOUS = 'misclassified_flustered_as_anxious.json'
NUM_SAMPLES_TO_EXTRACT = 100

# Device 설정
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(f"Using device: {device}")

# --- 도우미 클래스 및 함수 (기존 코드에서 가져옴) ---
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
        print(f"'{file_path}'에서 {len(texts)}개의 유효 샘플 로드 완료.")
        return texts, labels
    except FileNotFoundError:
        print(f"오류: '{file_path}' 파일을 찾을 수 없습니다.")
        return None, None

def save_samples_to_json(filepath, samples):
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(samples, f, indent=4, ensure_ascii=False)
    print(f"총 {len(samples)}개의 샘플을 '{filepath}' 파일에 저장했습니다.")

# --- 2. 메인 스크립트 실행 ---
if __name__ == "__main__":
    print("\n--- 1. 모델 및 토크나이저 로딩 ---")
    if not os.path.exists(MODEL_PATH):
        print(f"오류: 모델 경로 '{MODEL_PATH}'를 찾을 수 없습니다. v12 모델을 학습했는지 확인해주세요.")
        exit()
        
    tokenizer = AutoTokenizer.from_pretrained(MODEL_PATH)
    model = AutoModelForSequenceClassification.from_pretrained(MODEL_PATH)
    model.to(device)
    model.eval() # 평가 모드로 설정

    label_to_id = model.config.label2id
    id_to_label = model.config.id2label

    # 감정 코드 맵 (기존 코드와 동일하게)
    emotion_code_to_id = {
        **{f'E{i}': label_to_id['분노'] for i in range(10, 20)},
        **{f'E{i}': label_to_id['슬픔'] for i in range(20, 30)},
        **{f'E{i}': label_to_id['불안'] for i in range(30, 40)},
        **{f'E{i}': label_to_id['상처'] for i in range(40, 50)},
        **{f'E{i}': label_to_id['당황'] for i in range(50, 60)},
        **{f'E{i}': label_to_id['기쁨'] for i in range(60, 70)},
    }

    print("\n--- 2. 검증 데이터 로딩 및 전처리 ---")
    val_texts, val_labels = load_data_from_json(VALIDATION_JSON_PATH, emotion_code_to_id)
    if not val_texts:
        exit()

    val_encodings = tokenizer(val_texts, truncation=True, padding=True, max_length=128)
    val_dataset = EmotionDataset(val_encodings, val_labels)
    val_loader = DataLoader(val_dataset, batch_size=16)

    print("\n--- 3. 검증 데이터셋 전체 예측 수행 ---")
    all_preds = []
    with torch.no_grad():
        for batch in tqdm(val_loader, desc="Predicting"):
            input_ids = batch['input_ids'].to(device)
            attention_mask = batch['attention_mask'].to(device)
            
            outputs = model(input_ids=input_ids, attention_mask=attention_mask)
            logits = outputs.logits
            predictions = torch.argmax(logits, dim=-1)
            all_preds.extend(predictions.cpu().numpy())

    print("\n--- 4. 오분류 샘플 추출 ---")
    # 찾고자 하는 라벨의 ID 값을 미리 변수로 저장
    hurt_id = label_to_id['상처']
    sad_id = label_to_id['슬픔']
    flustered_id = label_to_id['당황']
    anxious_id = label_to_id['불안']

    misclassified_hurt_as_sad = []
    misclassified_flustered_as_anxious = []

    for i in range(len(val_texts)):
        true_label_id = val_labels[i]
        pred_label_id = all_preds[i]

        # 조건 1: 실제는 '상처'인데 '슬픔'으로 예측된 경우
        if true_label_id == hurt_id and pred_label_id == sad_id:
            if len(misclassified_hurt_as_sad) < NUM_SAMPLES_TO_EXTRACT:
                sample = {
                    'index': i,
                    'text': val_texts[i],
                    'true_label': id_to_label[true_label_id],
                    'predicted_label': id_to_label[pred_label_id]
                }
                misclassified_hurt_as_sad.append(sample)

        # 조건 2: 실제는 '당황'인데 '불안'으로 예측된 경우
        if true_label_id == flustered_id and pred_label_id == anxious_id:
            if len(misclassified_flustered_as_anxious) < NUM_SAMPLES_TO_EXTRACT:
                sample = {
                    'index': i,
                    'text': val_texts[i],
                    'true_label': id_to_label[true_label_id],
                    'predicted_label': id_to_label[pred_label_id]
                }
                misclassified_flustered_as_anxious.append(sample)
        
        # 두 리스트가 모두 찼으면 루프 종료
        if len(misclassified_hurt_as_sad) >= NUM_SAMPLES_TO_EXTRACT and \
           len(misclassified_flustered_as_anxious) >= NUM_SAMPLES_TO_EXTRACT:
            break

    print("\n--- 5. 추출 결과 저장 ---")
    save_samples_to_json(OUTPUT_FILE_HURT_AS_SAD, misclassified_hurt_as_sad)
    save_samples_to_json(OUTPUT_FILE_FLUSTERED_AS_ANXIOUS, misclassified_flustered_as_anxious)

    print("\n✅ 모든 작업이 완료되었습니다.")