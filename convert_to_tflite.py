import tensorflow as tf
from transformers import ElectraTokenizer, TFElectraForSequenceClassification
import os
import numpy as np
import shutil

# --- 1. 경로 설정 ---
PYTORCH_MODEL_PATH = "./fine-tuned-koelectra-emotion-model-small-best-v12"
TF_SAVEDMODEL_DIR = "./tf-savedmodel"
TFLITE_MODEL_DIR = "./tflite-model"
TFLITE_QUANT_MODEL_PATH = os.path.join(TFLITE_MODEL_DIR, "model.quant.tflite")
MAX_LENGTH = 128 # 대표 데이터셋과 일치해야 함

if os.path.exists(TF_SAVEDMODEL_DIR):
    shutil.rmtree(TF_SAVEDMODEL_DIR)
    print(f"기존 TF SavedModel 폴더 삭제: {TF_SAVEDMODEL_DIR}")

os.makedirs(TFLITE_MODEL_DIR, exist_ok=True)
os.makedirs(TF_SAVEDMODEL_DIR, exist_ok=True)

print(f"PyTorch 모델 로드: {PYTORCH_MODEL_PATH}")

# --- 2. [1단계] PyTorch Checkpoint -> TensorFlow SavedModel 변환 (고정 shape) ---
print("\n[1단계] PyTorch 가중치를 TF SavedModel로 변환합니다...")
try:
    tf_model = TFElectraForSequenceClassification.from_pretrained(
        PYTORCH_MODEL_PATH, 
        from_pt=True
    )
    
    # ⭐ 고정된 shape으로 SavedModel 저장 (추가)
    print(f"     -> 고정 입력 shape (1, {MAX_LENGTH})으로 SavedModel 생성 중...")
    
    # 고정 shape의 입력 스펙 정의
    input_spec = (
        tf.TensorSpec(shape=[1, MAX_LENGTH], dtype=tf.int32, name="input_ids"),
        tf.TensorSpec(shape=[1, MAX_LENGTH], dtype=tf.int32, name="attention_mask"),
        tf.TensorSpec(shape=[1, MAX_LENGTH], dtype=tf.int32, name="token_type_ids")
    )
    
    # call 함수를 위한 래퍼 생성
    @tf.function(input_signature=input_spec)
    def serving_fn(input_ids, attention_mask, token_type_ids):
        return tf_model(input_ids=input_ids, attention_mask=attention_mask, token_type_ids=token_type_ids)
    
    # 고정 shape으로 SavedModel 저장
    ACTUAL_SAVEDMODEL_PATH = os.path.join(TF_SAVEDMODEL_DIR, "saved_model", "1")
    tf.saved_model.save(
        tf_model,
        ACTUAL_SAVEDMODEL_PATH,
        signatures={'serving_default': serving_fn}
    )
    
    print(f"\n[1단계] TF SavedModel 저장 완료: {TF_SAVEDMODEL_DIR}")
    print(f"     입력 shape이 (1, {MAX_LENGTH})로 고정되었습니다.")
except Exception as e:
    print(f"[1단계 오류] PyTorch -> TF SavedModel 변환 실패: {e}")
    import traceback
    traceback.print_exc()
    exit()

# --- 3. [2단계] TF SavedModel -> TFLite (Full INT8 양자화) ---
print("\n[2단계] TFLite 변환 및 INT8 양자화를 시작합니다...")

try:
    tokenizer = ElectraTokenizer.from_pretrained(PYTORCH_MODEL_PATH)
    
    real_sentences = [
        "이 영화 정말 재밌어요, 강력 추천합니다.",
        "오늘 기분은 그저 그렇네요, 날씨가 흐려서 그런가.",
        "서비스가 너무 불친절해서 화가 났어요.",
        "깜짝 놀랐잖아요! 갑자기 나타나서.",
        "이런 슬픈 이야기는 정말 오랜만이에요.",
        "평범한 하루였어요."
    ] * 20

    def representative_dataset_gen():
        print("     -> 보정용 데이터셋 생성 중...")
        count = 0
        for text in real_sentences:
            if count >= 100:
                break
            
            inputs = tokenizer(
                text, 
                return_tensors="np",
                padding="max_length", 
                truncation=True, 
                max_length=MAX_LENGTH
            )
            
            # TFLite가 기대하는 순서대로 배열 생성
            input_ids = inputs['input_ids'].astype(np.int32)
            attention_mask = inputs['attention_mask'].astype(np.int32)
            
            if 'token_type_ids' in inputs:
                token_type_ids = inputs['token_type_ids'].astype(np.int32)
            else:
                token_type_ids = np.zeros_like(inputs['input_ids'], dtype=np.int32)
            
            # SavedModel의 signature 순서에 맞춰 반환 (보통 알파벳 순서)
            yield [attention_mask, input_ids, token_type_ids]
            count += 1
        print(f"     -> 보정용 데이터 {count}개 생성 완료.")

except Exception as e:
    print(f"토크나이저 로드 또는 데이터 생성 오류: {e}")
    exit()

# --- TFLite 변환 ---
try:
    # ⭐️ --- 수정된 부분: SavedModel에서 직접 변환 --- ⭐️
    
    # 1. 1단계에서 저장된 SavedModel 로드
    ACTUAL_SAVEDMODEL_PATH = os.path.join(TF_SAVEDMODEL_DIR, "saved_model", "1")
    print(f"     -> TFLite 변환 대상 경로: {ACTUAL_SAVEDMODEL_PATH}")
    
    # 2. from_saved_model로 직접 변환 (signature_keys 지정)
    converter = tf.lite.TFLiteConverter.from_saved_model(
        ACTUAL_SAVEDMODEL_PATH,
        signature_keys=['serving_default']
    )
    # ⭐️ --- 수정 완료 --- ⭐️
    
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.representative_dataset = representative_dataset_gen
    
    # Full INT8 양자화 설정
    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
    converter.inference_input_type = tf.int8
    converter.inference_output_type = tf.float32

    print("     -> TFLite 모델 변환 중... (시간이 걸릴 수 있습니다)")
    tflite_quant_model = converter.convert()
    
    with open(TFLITE_QUANT_MODEL_PATH, 'wb') as f:
        f.write(tflite_quant_model)
        
    print(f"\n✅ TFLite INT8 양자화 모델 저장 완료!")
    print(f"     -> {TFLITE_QUANT_MODEL_PATH}")

    # --- 4. TFLite 모델 크기 확인 ---
    quantized_size = os.path.getsize(TFLITE_QUANT_MODEL_PATH) / (1024 * 1024)
    
    print("\n--- 최종 모델 크기 ---")
    print(f"     최종 TFLite (INT8 양자화): {quantized_size:.2f} MB")

except Exception as e:
    print(f"\n[2단계 오류] TFLite 변환 실패: {e}")
    import traceback
    traceback.print_exc()