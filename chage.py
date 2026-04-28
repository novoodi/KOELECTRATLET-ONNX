import torch
from transformers import ElectraForSequenceClassification, ElectraTokenizer
import os

MODEL_PATH = "./fine-tuned-koelectra-emotion-model-small-best-v12"
ONNX_SAVE_PATH = "./onnx-model"

# 모델과 토크나이저 로딩
model = ElectraForSequenceClassification.from_pretrained(MODEL_PATH)
tokenizer = ElectraTokenizer.from_pretrained(MODEL_PATH)
model.eval() # ⭐️ 추론 모드로 설정

# ONNX 저장 폴더 생성
os.makedirs(ONNX_SAVE_PATH, exist_ok=True)

# 예시 입력 데이터 준비
dummy_input = tokenizer("예시 텍스트", return_tensors="pt", padding="max_length", truncation=True, max_length=128)

# ⭐️⭐️⭐️ 중요: 2개의 입력을 모두 준비 ⭐️⭐️⭐️
input_ids = dummy_input['input_ids']
attention_mask = dummy_input['attention_mask']

# 모델을 ONNX 형식으로 변환
torch.onnx.export(
    model, 
    # ⭐️ (input_ids, attention_mask) 튜플로 2개의 입력을 전달
    (input_ids, attention_mask),
    os.path.join(ONNX_SAVE_PATH, "model.onnx"),
    opset_version=13, # 최신 버전 사용
    # ⭐️ 입력 이름을 2개로 지정
    input_names=['input_ids', 'attention_mask'],
    output_names=['output'],
    # ⭐️ 2개 입력 모두에 동적 배치 크기 적용
    dynamic_axes={
        'input_ids': {0: 'batch_size'},
        'attention_mask': {0: 'batch_size'},
        'output': {0: 'batch_size'}
    }
)

print(f"ONNX 모델이 '{ONNX_SAVE_PATH}' 폴더에 저장되었습니다.")