import onnxruntime as ort
import torch
from transformers import ElectraTokenizer, ElectraForSequenceClassification
import numpy as np
import os

# --- 1. 설정 ---
MODEL_PATH = "./fine-tuned-koelectra-emotion-model-small-best-v12"
ONNX_PATH = "./onnx-model/model.onnx"
TEST_SENTENCE = "오늘 날씨가 너무 좋아서 기분이 날아갈 것 같아!"

print("ONNX 모델 검증을 시작합니다...")

# --- 2. 원본 PyTorch 모델 및 토크나이저 로드 ---
print(f"원본 PyTorch 모델 로드: {MODEL_PATH}")
tokenizer = ElectraTokenizer.from_pretrained(MODEL_PATH)
pt_model = ElectraForSequenceClassification.from_pretrained(MODEL_PATH)
pt_model.eval() # 반드시 추론 모드로 설정

# --- 3. ONNX 런타임 세션 로드 ---
print(f"ONNX 모델 로드: {ONNX_PATH}")
ort_session = ort.InferenceSession(ONNX_PATH, providers=['CPUExecutionProvider'])

# ONNX 모델의 입력 이름 확인 (chage.py에서 정의한 이름)
onnx_input_names = [inp.name for inp in ort_session.get_inputs()]
print(f"ONNX가 필요로 하는 입력: {onnx_input_names}")

# --- 4. 동일한 입력 데이터 준비 ---
print(f"테스트 문장: '{TEST_SENTENCE}'")
inputs = tokenizer(
    TEST_SENTENCE, 
    return_tensors="pt", 
    padding="max_length", # 변환 시 사용한 옵션과 동일하게
    truncation=True, 
    max_length=128
)
input_ids = inputs['input_ids']
attention_mask = inputs['attention_mask']

# --- 5. 원본(PyTorch) 모델 추론 ---
print("PyTorch 모델 추론 중...")
with torch.no_grad():
    pt_outputs = pt_model(input_ids=input_ids, attention_mask=attention_mask)
    pt_logits = pt_outputs.logits.numpy() # 비교를 위해 numpy로 변환

# --- 6. ONNX 모델 추론 ---
print("ONNX 모델 추론 중...")
# ONNX 런타임은 입력을 딕셔너리 형태의 numpy 배열로 받습니다.
onnx_inputs = {
    'input_ids': input_ids.numpy(),
    'attention_mask': attention_mask.numpy()
}
onnx_outputs = ort_session.run(None, onnx_inputs)
onnx_logits = onnx_outputs[0] # 출력은 리스트 형태이므로 첫 번째 요소를 사용

# --- 7. 결과 비교 ---
print("\n--- 결과 비교 ---")
print(f"PyTorch Logits (첫 5개): {pt_logits[0][:5]}")
print(f"ONNX Logits (첫 5개):    {onnx_logits[0][:5]}")

# np.allclose를 사용하여 두 부동소수점 배열이 매우 가까운지 확인
# atol (absolute tolerance) 값을 1e-5 (0.00001) 정도로 설정
if np.allclose(pt_logits, onnx_logits, atol=1e-5):
    print("\n✅ [성공] PyTorch와 ONNX의 출력 값이 거의 동일합니다!")
    print("ONNX 모델이 성공적으로 검증되었습니다.")
else:
    print("\n❌ [실패] PyTorch와 ONNX의 출력 값이 다릅니다!")
    max_diff = np.abs(pt_logits - onnx_logits).max()
    print(f"최대 차이: {max_diff}")

# 최종 예측 클래스 비교
id_to_label = pt_model.config.id2label
pt_pred_id = np.argmax(pt_logits, axis=1)[0]
onnx_pred_id = np.argmax(onnx_logits, axis=1)[0]

print("\n--- 최종 예측 비교 ---")
print(f"PyTorch 예측: {id_to_label[pt_pred_id]}")
print(f"ONNX 예측:    {id_to_label[onnx_pred_id]}")