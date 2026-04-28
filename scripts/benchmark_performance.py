import torch
from transformers import ElectraTokenizer, ElectraForSequenceClassification
import tensorflow as tf
import numpy as np
import time

# --- 설정 ---
PYTORCH_MODEL_PATH = "./fine-tuned-koelectra-emotion-model-small-best-v12"
TFLITE_MODEL_PATH = "./tflite-model/model.quant.tflite"
MAX_LENGTH = 128
WARMUP_RUNS = 5
BENCHMARK_RUNS = 50

TEST_SENTENCES = [
    "이 영화 정말 재미있고 감동적이었어요!",
    "오늘은 기분이 별로 좋지 않네요.",
    "깜짝 놀랐어요! 정말 예상 못했어요.",
    "평범한 하루를 보냈습니다.",
    "서비스가 정말 형편없어서 화가 났어요."
]

print("=" * 60)
print("모델 성능 벤치마크 테스트")
print("=" * 60)

# --- 모델 로드 ---
print("\n[1단계] 모델 로드 중...")
tokenizer = ElectraTokenizer.from_pretrained(PYTORCH_MODEL_PATH)
pt_model = ElectraForSequenceClassification.from_pretrained(PYTORCH_MODEL_PATH)
pt_model.eval()

interpreter = tf.lite.Interpreter(model_path=TFLITE_MODEL_PATH)
interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print("✓ 모델 로드 완료")

# --- 입력 데이터 준비 ---
def prepare_inputs(sentence):
    inputs = tokenizer(
        sentence,
        return_tensors="np",
        padding="max_length",
        truncation=True,
        max_length=MAX_LENGTH
    )
    
    # PyTorch 입력
    input_ids_pt = torch.tensor(inputs['input_ids'], dtype=torch.long)
    attention_mask_pt = torch.tensor(inputs['attention_mask'], dtype=torch.long)
    token_type_ids_pt = torch.zeros_like(input_ids_pt, dtype=torch.long)
    
    # TFLite 입력
    input_ids_tflite = inputs['input_ids'].astype(np.int32)
    attention_mask_tflite = inputs['attention_mask'].astype(np.int32)
    token_type_ids_tflite = np.zeros_like(input_ids_tflite, dtype=np.int32)
    
    return {
        'pt': (input_ids_pt, attention_mask_pt, token_type_ids_pt),
        'tflite': (attention_mask_tflite, input_ids_tflite, token_type_ids_tflite)
    }

# --- PyTorch 추론 함수 ---
def run_pytorch(inputs_pt):
    with torch.no_grad():
        outputs = pt_model(
            input_ids=inputs_pt[0],
            attention_mask=inputs_pt[1],
            token_type_ids=inputs_pt[2]
        )
    return outputs.logits[0].numpy()

# --- TFLite 추론 함수 ---
def run_tflite(inputs_tflite):
    interpreter.set_tensor(input_details[0]['index'], inputs_tflite[0])  # attention_mask
    interpreter.set_tensor(input_details[1]['index'], inputs_tflite[1])  # input_ids
    interpreter.set_tensor(input_details[2]['index'], inputs_tflite[2])  # token_type_ids
    interpreter.invoke()
    return interpreter.get_tensor(output_details[0]['index'])[0]

# --- 워밍업 ---
print(f"\n[2단계] 워밍업 중... ({WARMUP_RUNS}회)")
test_inputs = prepare_inputs(TEST_SENTENCES[0])

for i in range(WARMUP_RUNS):
    run_pytorch(test_inputs['pt'])
    run_tflite(test_inputs['tflite'])

print("✓ 워밍업 완료")

# --- 벤치마크 ---
print(f"\n[3단계] 벤치마크 실행 중... ({BENCHMARK_RUNS}회 x {len(TEST_SENTENCES)}개 문장)")

pytorch_times = []
tflite_times = []

for sentence in TEST_SENTENCES:
    inputs = prepare_inputs(sentence)
    
    # PyTorch 벤치마크
    for _ in range(BENCHMARK_RUNS):
        start = time.perf_counter()
        run_pytorch(inputs['pt'])
        end = time.perf_counter()
        pytorch_times.append((end - start) * 1000)
    
    # TFLite 벤치마크
    for _ in range(BENCHMARK_RUNS):
        start = time.perf_counter()
        run_tflite(inputs['tflite'])
        end = time.perf_counter()
        tflite_times.append((end - start) * 1000)

# --- 결과 출력 ---
print("\n" + "=" * 60)
print("벤치마크 결과")
print("=" * 60)

def print_stats(times, model_name):
    times = np.array(times)
    print(f"\n{model_name}:")
    print(f"  평균:     {np.mean(times):.2f} ms")
    print(f"  중앙값:   {np.median(times):.2f} ms")
    print(f"  최소:     {np.min(times):.2f} ms")
    print(f"  최대:     {np.max(times):.2f} ms")
    print(f"  표준편차: {np.std(times):.2f} ms")

print_stats(pytorch_times, "PyTorch (원본 모델)")
print_stats(tflite_times, "TFLite (INT8 양자화)")

# --- 비교 ---
pt_avg = np.mean(pytorch_times)
tflite_avg = np.mean(tflite_times)
speedup = pt_avg / tflite_avg

print("\n" + "-" * 60)
if speedup > 1:
    print(f"✓ TFLite가 {speedup:.2f}배 빠릅니다!")
elif speedup < 1:
    print(f"✗ TFLite가 {1/speedup:.2f}배 느립니다.")
    print("\n💡 참고:")
    print("  - CPU에서는 float32가 INT8보다 빠를 수 있습니다")
    print("  - TFLite의 장점은 모바일/임베디드 기기에서 나타납니다")
    print("  - 모델 크기: TFLite가 훨씬 작습니다 (약 4배 감소)")
else:
    print("성능이 비슷합니다.")

print("-" * 60)

# --- 정확도 검증 ---
print("\n[4단계] 정확도 검증")
print("-" * 60)

correct = 0
total = len(TEST_SENTENCES)

for sentence in TEST_SENTENCES:
    inputs = prepare_inputs(sentence)
    
    pt_logits = run_pytorch(inputs['pt'])
    tflite_logits = run_tflite(inputs['tflite'])
    
    pt_pred = np.argmax(pt_logits)
    tflite_pred = np.argmax(tflite_logits)
    
    if pt_pred == tflite_pred:
        correct += 1
    
    print(f"문장: {sentence[:30]}...")
    print(f"  PyTorch: 클래스 {pt_pred} | TFLite: 클래스 {tflite_pred} {'✓' if pt_pred == tflite_pred else '✗'}")

print(f"\n정확도 일치율: {correct}/{total} ({100*correct/total:.1f}%)")
print("=" * 60)