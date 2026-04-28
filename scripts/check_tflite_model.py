import tensorflow as tf
import numpy as np

# 1. 모델 로드 (안드로이드에 넣은 그 파일!)
TFLITE_MODEL_PATH = "./tflite-model/model.quant.tflite"
interpreter = tf.lite.Interpreter(model_path=TFLITE_MODEL_PATH)
interpreter.allocate_tensors()

# 2. 입력/출력 정보 가져오기
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print("\n=== 1. 모델 입력 순서 확인 ===")
for i, detail in enumerate(input_details):
    print(f"Index {i}: {detail['name']} (Shape: {detail['shape']})")

# 3. "나 너무 힘들어" 데이터 준비 (안드로이드 로그에 찍힌 그 숫자!)
# [2, 2236, 6395, 7048, 4025, 3] + 나머지 0
input_ids = [2, 2236, 6395, 7048, 4025, 3] + [0] * (128 - 6)
attention_mask = [1, 1, 1, 1, 1, 1] + [0] * (128 - 6)
token_type_ids = [0] * 128

# 데이터를 TFLite 형식(int32)으로 변환
inputs_map = {
    "input_ids": np.array([input_ids], dtype=np.int32),
    "attention_mask": np.array([attention_mask], dtype=np.int32),
    "token_type_ids": np.array([token_type_ids], dtype=np.int32)
}

# 4. 모델에 데이터 넣기 (이름 맞춰서 넣기)
for detail in input_details:
    # 이름에서 'serving_default_' 제거하고 매핑
    key = detail['name'].split(":")[0].replace("serving_default_", "")
    if key in inputs_map:
        interpreter.set_tensor(detail['index'], inputs_map[key])

# 5. 추론 실행
interpreter.invoke()

# 6. 결과 확인
output_data = interpreter.get_tensor(output_details[0]['index'])[0]
emotion_labels = ["분노", "슬픔", "불안", "상처", "당황", "기쁨"]
max_idx = np.argmax(output_data)

print(f"\n=== 2. 분석 결과 ===")
print(f"입력 문장: '나 너무 힘들어'")
print(f"Raw Logits: {output_data}")
print(f"예측된 감정: {emotion_labels[max_idx]} (Index {max_idx})")

if max_idx == 5: # 기쁨
    print("\n❌ 결론: TFLite 모델 파일 자체가 망가졌습니다. (변환 과정 문제)")
else:
    print("\n✅ 결론: 모델은 정상입니다. 안드로이드 코드의 입력 순서가 문제일 수 있습니다.")