from transformers import AutoTokenizer

# 학습된 모델 경로 (또는 원본 모델명)
MODEL_PATH = "./fine-tuned-koelectra-emotion-model-small-best-v14" 
# 만약 로컬 경로가 없으면 "monologg/koelectra-small-v3-discriminator" 사용

tokenizer = AutoTokenizer.from_pretrained(MODEL_PATH)

text = "나 너무 힘들어"

# 1. 토큰화 결과 (눈으로 보는 글자)
tokens = tokenizer.tokenize(text)
print(f"✅ 정답 토큰 (글자): {tokens}")

# 2. ID 변환 결과 (모델에 들어가는 숫자)
input_ids = tokenizer.encode(text)
print(f"✅ 정답 ID (숫자): {input_ids}")