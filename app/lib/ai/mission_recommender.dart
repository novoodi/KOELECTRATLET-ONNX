import '../models/mission.dart'; // 사용자의 실제 미션 모델 import
import 'emotion_model.dart';

class MissionRecommender {
  // 감정별 추천 미션 키워드 또는 카테고리 매핑
  static List<String> getRecommendations(EmotionLabel emotion) {
    switch (emotion) {
      case EmotionLabel.anger:
        return ["아침 스트레칭", "명상 10분", "찬물 마시기"]; // 차분함, 신체 이완
      case EmotionLabel.sadness:
        return ["감사일기 쓰기", "따뜻한 차 마시기", "산책하기"]; // 위로, 환기
      case EmotionLabel.anxiety:
        return ["명상 10분", "식물에 물 주기", "심호흡 하기"]; // 안정
      case EmotionLabel.hurt:
        return ["나를 위한 선물 사기", "감사일기 쓰기", "좋아하는 음악 듣기"]; // 자존감 회복
      case EmotionLabel.embarrassment:
        return ["거울 보고 웃기", "재미있는 영상 보기", "심호흡 하기"]; // 기분 전환
      case EmotionLabel.happiness:
        return ["이 순간 기록하기", "친구에게 연락하기", "목표 재설정"]; // 강화
    }
  }

// 실제 미션 객체로 변환하는 함수 (나중에 DB와 연동 필요)
// 지금은 텍스트만 리턴하지만, 나중에는 FireStore에서 쿼리해오는 방식으로 변경 가능
}