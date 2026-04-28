# KoELECTRA 한국어 감정 분류 모델

AI Hub 한국어 감정 대화 데이터셋으로 [KoELECTRA-small-v3](https://github.com/monologg/KoELECTRA)를 파인튜닝한 6감정 분류 모델입니다.  
최종 모델은 모바일 배포를 위해 ONNX 및 TFLite 포맷으로 변환됩니다.

## 분류 감정

| 레이블 | 감정 코드 범위 |
|--------|--------------|
| 분노   | E10 ~ E19    |
| 슬픔   | E20 ~ E29    |
| 불안   | E30 ~ E39    |
| 상처   | E40 ~ E49    |
| 당황   | E50 ~ E59    |
| 기쁨   | E60 ~ E69    |

## 최종 모델 성능 (v12)

| 지표 | 값 |
|------|----|
| Macro F1-Score | 0.7584 |
| Accuracy | 0.7646 |

> v8부터 v14까지 총 7회 반복 실험을 통해 v12가 최고 성능을 달성했습니다.  
> 핵심 개선 포인트: 분류기 Dropout 0.3 + Linear 스케줄러 + CrossEntropy(클래스 가중치 + 라벨 스무딩 0.1)

## 파일 구조

```
.
├── AFC.py                  # 모델 파인튜닝 학습 (메인)
├── chage.py                # PyTorch → ONNX 변환
├── Quantization.py         # ONNX 단순화 + INT8 동적 양자화
├── convert_to_tflite.py    # TFLite INT8 전체 양자화 변환 (모바일 배포용)
├── 128.py                  # TFLite float32 변환 (Flutter 호환)
└── scripts/                # 분석·검증·실험용 유틸리티
    ├── data.py                  # 데이터셋 감정 코드 분포 탐색
    ├── extract_misclassified.py # 오분류 샘플 추출 및 저장
    ├── translator.py            # 역번역(Back-translation) 데이터 증강 실험
    ├── verify_onnx.py           # PyTorch vs ONNX 출력 일치 검증
    ├── convert_to_tflite_v2.py  # TFLite 변환 대안 방법
    ├── benchmark_performance.py # PyTorch vs TFLite 추론 속도 비교
    ├── check_tflite_model.py    # TFLite 모델 구조 확인
    ├── check_tokens.py          # 토크나이저 토큰화 결과 확인
    └── verify_tflite.py         # TFLite 출력 검증
```

## 학습 파이프라인

```
1. AFC.py              → PyTorch 파인튜닝 모델 (fine-tuned-koelectra-*/))
2. chage.py            → ONNX 변환 (onnx-model/model.onnx)
3. Quantization.py     → ONNX INT8 양자화 (onnx-model/model.quant.onnx)
4. convert_to_tflite.py or 128.py → TFLite 변환 (tflite-model/)
```

## 주요 하이퍼파라미터 (v12 기준)

```python
MODEL_NAME      = "monologg/koelectra-small-v3-discriminator"
LEARNING_RATE   = 2e-5
WEIGHT_DECAY    = 0.1
DROPOUT_RATE    = 0.3
LABEL_SMOOTHING = 0.1
BATCH_SIZE      = 16
EPOCHS          = 30  # Early stopping (patience=5) 적용
SCHEDULER       = "linear" (10% warmup)
LOSS            = CrossEntropyLoss (클래스 가중치 적용)
MAX_LENGTH      = 128
```

## 데이터

AI Hub [한국어 감정 정보가 포함된 단발성 대화 데이터셋](https://aihub.or.kr)을 사용합니다.  
라이선스 문제로 데이터 파일은 포함되지 않습니다. AI Hub에서 직접 다운로드 후 아래 경로에 배치해 주세요.

```
aihub_data.json              # 학습 데이터
aihub.data.Validation.json   # 검증 데이터
```

## 버전별 실험 결과

| 버전 | LR | Dropout | Scheduler | Loss | Best F1 |
|------|----|---------|-----------|------|---------|
| v8  | 1e-5 | 기본값 | 기본      | CE             | 0.6953 |
| v9  | 2e-5 | 기본값 | 기본      | CE             | 0.7142 |
| v10 | 2e-5 | 기본값 | cosine_restarts | CE      | 0.7109 |
| v11 | 2e-5 | 기본값 | cosine_restarts | FocalLoss | 0.7035 |
| **v12** | **2e-5** | **0.3** | **linear** | **CE+Weight** | **0.7584** |
| v13 | 2e-5 | 0.3 | linear    | FocalLoss      | 0.7529 |
| v14 | 1e-5 | 0.3 | linear    | CE+Weight      | 0.7449 |

## 환경

```
Python 3.x
torch
transformers
scikit-learn
tensorflow
onnxruntime
onnx
onnx-simplifier
```
