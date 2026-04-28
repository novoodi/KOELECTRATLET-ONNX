import json
from collections import Counter

# 확인할 JSON 파일 경로
# 학습 데이터셋에 있는 모든 감정의 종류를 파악하는 것이 목표입니다.
TRAIN_JSON_PATH = 'aihub_data.json'

def find_unique_emotion_codes(file_path):
    """JSON 파일에서 모든 고유 감정 코드를 찾고, 각 코드의 개수를 셉니다."""
    emotion_codes = []
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        for item in data:
            # .get()을 사용하여 키가 없는 경우에도 오류 없이 안전하게 접근
            emotion_code = item.get('profile', {}).get('emotion', {}).get('type')
            if emotion_code:
                emotion_codes.append(emotion_code)
        
        print(f"✅ '{file_path}' 파일 스캔 완료!")
        
        # 고유한 코드 목록 (정렬해서 보기 편하게)
        unique_codes = sorted(list(set(emotion_codes)))
        print(f"\n--- 발견된 고유 감정 코드 (총 {len(unique_codes)}개) ---")
        print(unique_codes)
        
        # 각 코드별 데이터 개수
        code_counts = Counter(emotion_codes)
        print("\n--- 각 코드별 데이터 개수 (상위 20개) ---")
        for code, count in code_counts.most_common(20):
            print(f"- {code}: {count}개")
            
    except FileNotFoundError:
        print(f"❌ 오류: '{file_path}' 파일을 찾을 수 없습니다. 경로를 확인해주세요.")
    except Exception as e:
        print(f"❌ 오류 발생: {e}")

# 스크립트 실행
find_unique_emotion_codes(TRAIN_JSON_PATH)