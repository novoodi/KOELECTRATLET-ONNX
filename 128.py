import os
import shutil
import tensorflow as tf
from transformers import TFElectraForSequenceClassification

# 원본 PyTorch 모델 경로 (v12)
PYTORCH_MODEL_PATH = "./fine-tuned-koelectra-emotion-model-small-best-v12"

# 여기만 변경하면 버전 별로 저장 가능
TF_SAVED_MODEL = "./tf-savedmodel-v12"
TFLITE_MODEL = "./tflite-model-v12/model_float32.tflite"

# 폴더가 없으면 만들지만, 기존 파일 삭제는 안 함
os.makedirs(TF_SAVED_MODEL, exist_ok=True)
os.makedirs(os.path.dirname(TFLITE_MODEL), exist_ok=True)

print("[1] PyTorch → TF 변환")
tf_model = TFElectraForSequenceClassification.from_pretrained(
    PYTORCH_MODEL_PATH, from_pt=True
)

tf_model.save(TF_SAVED_MODEL, save_format='tf')
print("SavedModel 저장 완료:", TF_SAVED_MODEL)

print("\n[2] TFLite 변환 (Flutter 호환 float32 버전 생성)")
converter = tf.lite.TFLiteConverter.from_saved_model(TF_SAVED_MODEL)

converter.target_spec.supported_ops = [
    tf.lite.OpsSet.TFLITE_BUILTINS,
    tf.lite.OpsSet.SELECT_TF_OPS,
]

converter.experimental_enable_resource_variables = True
converter._experimental_lower_tensor_list_ops = False
converter.optimizations = []  # 양자화 없음

tflite_model = converter.convert()

with open(TFLITE_MODEL, "wb") as f:
    f.write(tflite_model)

print("TFLite 저장 완료:", TFLITE_MODEL)
