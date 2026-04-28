import torch
from transformers import ElectraTokenizer, ElectraForSequenceClassification
import tensorflow as tf
import numpy as np
import time

# --- 1. 설정 ---
PYTORCH_MODEL_PATH = "./fine-tuned-koelectra-emotion-model-small-best-v12"
TFLITE_MODEL_PATH = "./tflite-model/model.quant.tflite"
TEST_SENTENCE = "오늘은 너무 행복한 하루였어!" 

print("모델과 토크나이저를 로드합니다...")
# --- 원본 PyTorch 모델 로드 ---
tokenizer = ElectraTokenizer.from_pretrained(PYTORCH_MODEL_PATH)
pt_model = ElectraForSequenceClassification.from_pretrained(PYTORCH_MODEL_PATH)
pt_model.eval()

# --- TFLite 모델 로드 ---
interpreter = tf.lite.Interpreter(model_path=TFLITE_MODEL_PATH)

# ⭐️⭐️⭐️ [수정] 입력 크기 강제 재조정 (Resize) ⭐️⭐️⭐️
# 모델이 [1, 1]로 되어있으므로 [1, 128]로 늘려줍니다.
print("TFLite 입력 텐서 크기를 (1, 128)로 재조정합니다...")
input_details = interpreter.get_input_details()
for detail in input_details:
    interpreter.resize_tensor_input(detail['index'], [1, 128])

# ⭐️ Resize 후에 할당해야 합니다.
interpreter.allocate_tensors()

output_details = interpreter.get_output_details()

print("\n--- TFLite 모델 입력 정보 (Resize 후) ---")
print(interpreter.get_input_details())
print("----------------------------\n")

# --- 2. 입력 데이터 준비 ---
inputs = tokenizer(
    TEST_SENTENCE,
    return_tensors="np", 
    padding="max_length",
    truncation=True,
    max_length=128
)

# TFLite 입력용 데이터 (int32)
input_ids_tflite = inputs['input_ids'].astype(np.int32)
attention_mask_tflite = inputs['attention_mask'].astype(np.int32)
token_type_ids_tflite = np.zeros_like(input_ids_tflite, dtype=np.int32) 

# PyTorch 입력용 데이터 (int64)
input_ids_pt = torch.tensor(inputs['input_ids'], dtype=torch.long)
attention_mask_pt = torch.tensor(inputs['attention_mask'], dtype=torch.long)
token_type_ids_pt = torch.zeros_like(input_ids_pt, dtype=torch.long)


# --- 3. 원본 PyTorch 모델 추론 ---
print(f"테스트 문장: \"{TEST_SENTENCE}\"")
print("\n--- 1. 원본 (PyTorch) 모델 추론 ---")
start_time = time.time()
with torch.no_grad():
    outputs_pt = pt_model(
        input_ids=input_ids_pt,
        attention_mask=attention_mask_pt,
        token_type_ids=token_type_ids_pt
    )
logits_pt = outputs_pt.logits[0].numpy()
pred_pt = np.argmax(logits_pt)
end_time = time.time()
print(f"  예측된 클래스 (Logits): {np.argmax(logits_pt)}")
print(f"  전체 Logits: {logits_pt}")
print(f"  추론 시간: {(end_time - start_time) * 1000:.2f} ms")


# --- 4. 양자화 TFLite 모델 추론 ---
print("\n--- 2. 양자화 (TFLite) 모델 추론 ---")
start_time = time.time()

# 입력 맵 생성
input_map = {
    "input_ids": input_ids_tflite,
    "attention_mask": attention_mask_tflite,
    "token_type_ids": token_type_ids_tflite
}

# 입력 데이터 설정
for detail in input_details:
    input_name = detail['name'].split(':')[0].replace('serving_default_', '')
    if input_name in input_map:
        interpreter.set_tensor(detail['index'], input_map[input_name])

# 추론 실행
interpreter.invoke()

# 출력 데이터 가져오기
logits_tflite = interpreter.get_tensor(output_details[0]['index'])[0]
pred_tflite = np.argmax(logits_tflite)
end_time = time.time()

print(f"  예측된 클래스 (Logits): {pred_tflite}")
print(f"  전체 Logits: {logits_tflite}")
print(f"  추론 시간: {(end_time - start_time) * 1000:.2f} ms")

# --- 5. 결과 비교 ---
print("\n--- 3. 결과 비교 ---")
if pred_pt == pred_tflite:
    print("✅ 성공: 두 모델의 예측 결과(클래스)가 동일합니다!")
else:
    print("❌ 실패: 두 모델의 예측 결과가 다릅니다.")
    
print(f"  (PyTorch: {pred_pt} vs TFLite: {pred_tflite})")

# Softmax
def softmax(x):
    e_x = np.exp(x - np.max(x))
    return e_x / e_x.sum(axis=0)

probs_pt = softmax(logits_pt)
probs_tflite = softmax(logits_tflite)

print("\n--- 예측 확률 비교 (Softmax) ---")
print(f"  PyTorch  : {np.round(probs_pt, 4)}")
print(f"  TFLite   : {np.round(probs_tflite, 4)}")
print(f"  최대 확률 차이: {np.max(np.abs(probs_pt - probs_tflite)):.6f}")