# 필요한 라이브러리를 설치합니다.
# pip install torch transformers sentencepiece sacremoses

from transformers import pipeline

# 1. 번역 파이프라인 준비
print("번역 모델을 로딩합니다... (초기에 시간이 조금 걸릴 수 있습니다)")

# 한국어 -> 영어 번역 모델
translator_ko_to_en = pipeline("translation", model="Helsinki-NLP/opus-mt-ko-en")

# 영어 -> 한국어 번역 모델
translator_en_to_ko = pipeline("translation", model="NHNDQ/nllb-finetuned-en2ko")
print("모델 로딩 완료!")

# 2. 증강시킬 원본 문장들
original_sentences = [
    "아무것도 하기 싫고 우울해.",
    "짜증나 진짜! 왜 이렇게 안 풀리는 거야.",
    "내일 발표 때문에 잠이 안 와.",
    "힘들었던 하루 속에서도 내가 해낸 작은 일을 스스로 칭찬해 주고 싶어.",
    "그냥 평범하게 하루가 지나갔어."
]

print("\n--- 역번역 테스트 시작 ---")

# 3. 각 문장에 대해 역번역 수행
for sentence in original_sentences:
    print(f"원본 문장: {sentence}")

    # 한국어 -> 영어 번역
    english_translation = translator_ko_to_en(sentence)[0]['translation_text']
    print(f"➡️ 영어 번역: {english_translation}")

    # 영어 -> 한국어 번역 (역번역)
    # *** 여기에 src_lang과 tgt_lang을 추가합니다 ***
    back_translated_sentence = translator_en_to_ko(
        english_translation,
        src_lang="eng_Latn",
        tgt_lang="kor_Hang"
    )[0]['translation_text']
    
    print(f"⬅️ 역번역된 문장: {back_translated_sentence}")
    print("-" * 30)