import onnxruntime as ort
from onnxruntime.quantization import quantize_dynamic, QuantType
import os
import onnx  # ⭐️ ONNX 라이브러리 import
import onnxsim # ⭐️ onnx-simplifier import

# --- 1. 설정 ---
ONNX_MODEL_PATH = "./onnx-model/model.onnx"
# ⭐️ 단순화된 모델 경로 추가
SIMPLIFIED_MODEL_PATH = "./onnx-model/model.sim.onnx"
QUANTIZED_MODEL_PATH = "./onnx-model/model.quant.onnx"

print(f"  원본 ONNX 모델: {ONNX_MODEL_PATH}")

# --- 1.5. ONNX 모델 단순화 (Simplification) ---
print("\nONNX 모델 단순화를 시작합니다...")
try:
    model = onnx.load(ONNX_MODEL_PATH)
    # ⭐️ onnxsim.simplify 함수 호출
    model_sim, check = onnxsim.simplify(model)
    
    if not check:
        print("  WARNING: 모델 단순화에 실패했습니다. (체크 실패)")
    else:
        print("  모델 단순화 성공.")
        
    # ⭐️ 단순화된 모델 저장
    onnx.save(model_sim, SIMPLIFIED_MODEL_PATH)
    print(f"  단순화된 모델 저장 완료: {SIMPLIFIED_MODEL_PATH}")

except Exception as e:
    print(f"  모델 단순화 중 오류 발생: {e}")
    print("  원본 모델로 양자화를 시도합니다.")
    SIMPLIFIED_MODEL_PATH = ONNX_MODEL_PATH # ⭐️ 실패 시 원본 경로 사용


# --- 2. 동적 양자화 수행 ---
print("\n동적 양자화(INT8)를 시작합니다...")
print(f"  양자화 대상 모델: {SIMPLIFIED_MODEL_PATH}")
print(f"  양자화된 모델 저장 경로: {QUANTIZED_MODEL_PATH}")

quant_options = {
    "DisableShapeInference": True # ⭐️ 이 옵션은 여전히 유지하는 것이 좋습니다.
}

quantize_dynamic(
    model_input=SIMPLIFIED_MODEL_PATH,  # ⭐️ 입력으로 단순화된 모델을 사용
    model_output=QUANTIZED_MODEL_PATH,
    weight_type=QuantType.QInt8,
    extra_options=quant_options
)

print("양자화 완료!")

# --- 3. 모델 크기 비교 ---
try:
    # ⭐️⭐️⭐️ 비교 대상을 'model.sim.onnx'로 변경 ⭐️⭐️⭐️
    original_size = os.path.getsize(SIMPLIFIED_MODEL_PATH) / (1024 * 1024)
    quantized_size = os.path.getsize(QUANTIZED_MODEL_PATH) / (1024 * 1024)

    print("\n--- 모델 크기 비교 ---")
    # ⭐️ 어떤 파일인지 명시해주는 것이 좋습니다.
    print(f"  원본 모델 크기 (FP32, '{SIMPLIFIED_MODEL_PATH}'): {original_size:.2f} MB")
    print(f"  양자화 모델 크기 (INT8, '{QUANTIZED_MODEL_PATH}'): {quantized_size:.2f} MB")
    print(f"  크기 감소율: {((original_size - quantized_size) / original_size * 100):.2f}%")
except FileNotFoundError:
    print("\n파일 크기를 비교하는 중 오류가 발생했습니다. 경로를 확인해주세요.")