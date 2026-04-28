import tensorflow as tf
import numpy as np
import os
import json
from transformers import ElectraTokenizer, TFElectraForSequenceClassification
import shutil

# --- 1. 설정 ---
PYTORCH_MODEL_PATH = "./fine-tuned-koelectra-emotion-model-small-best-v12"
TF_SAVEDMODEL_DIR = "./tf-savedmodel"
TFLITE_MODEL_DIR = "./tflite-model"
TFLITE_QUANT_MODEL_PATH = os.path.join(TFLITE_MODEL_DIR, "model.quant.tflite")
VALIDATION_JSON_PATH = 'aihub.data.Validation.json' 

if os.path.exists(TF_SAVEDMODEL_DIR):
    shutil.rmtree(TF_SAVEDMODEL_DIR)
os.makedirs(TFLITE_MODEL_DIR, exist_ok=True)
os.makedirs(TF_SAVEDMODEL_DIR, exist_ok=True)

print(f"모델 경로: {PYTORCH_MODEL_PATH}")

# --- 2. [1단계] PyTorch -> TF SavedModel ---
print("\n[1단계] PyTorch -> TF SavedModel 변환...")
try:
    tf_model = TFElectraForSequenceClassification.from_pretrained(
        PYTORCH_MODEL_PATH, from_pt=True
    )
    tf_model.save(TF_SAVEDMODEL_DIR, save_format='tf')
    print("  -> SavedModel 저장 완료.")
except Exception as e:
    print(f"  -> 오류: {e}")
    exit()

# --- 3. 데이터 로드 함수 ---
def load_real_data_from_json(file_path, limit=300):
    print(f"\n[데이터 로드] '{file_path}'에서 보정용 데이터 {limit}개를 읽어옵니다...")
    texts = []
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            count = 0
            for item in data:
                content = item.get('talk', {}).get('content', {})
                user_utterances = [content.get(f'HS0{i}') for i in range(1, 4)]
                full_text = " ".join(t for t in user_utterances if t and t.strip())
                
                if full_text:
                    texts.append(full_text)
                    count += 1
                    if count >= limit: break
        print(f"  -> {len(texts)}개 문장 로드 완료.")
        return texts
    except FileNotFoundError:
        print(f"  -> 🚨 오류: '{file_path}' 파일을 찾을 수 없습니다.")
        return ["테스트 문장입니다"] * 50

# --- 4. [2단계] TFLite 변환 ---
print("\n[2단계] TFLite 변환 및 양자화 시작...")

try:
    tokenizer = ElectraTokenizer.from_pretrained(PYTORCH_MODEL_PATH)
    calibration_texts = load_real_data_from_json(VALIDATION_JSON_PATH)

    def representative_dataset_gen():
        for i, text in enumerate(calibration_texts):
            inputs = tokenizer(
                text, 
                return_tensors="np", 
                padding="max_length", 
                truncation=True, 
                max_length=128
            )
            # int32 데이터 제공
            yield {
                "input_ids": inputs['input_ids'].astype(np.int32),
                "attention_mask": inputs['attention_mask'].astype(np.int32),
                "token_type_ids": np.zeros_like(inputs['input_ids'], dtype=np.int32)
            }

    converter = tf.lite.TFLiteConverter.from_saved_model(TF_SAVEDMODEL_DIR)
    
    # 양자화 옵션
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.representative_dataset = representative_dataset_gen
    
    # Ops 설정
    converter.target_spec.supported_ops = [
        tf.lite.OpsSet.TFLITE_BUILTINS_INT8,
        tf.lite.OpsSet.TFLITE_BUILTINS
    ]
    

    print("  -> 모델 변환 중... (시간이 좀 걸립니다)")
    tflite_model = converter.convert()

    with open(TFLITE_QUANT_MODEL_PATH, 'wb') as f:
        f.write(tflite_model)

    print(f"\n✅ 변환 완료! 저장 경로: {TFLITE_QUANT_MODEL_PATH}")
    print(f"   크기: {os.path.getsize(TFLITE_QUANT_MODEL_PATH) / 1024 / 1024 :.2f} MB")

except Exception as e:
    print(f"\n🚨 변환 실패: {e}")
    import traceback
    traceback.print_exc()