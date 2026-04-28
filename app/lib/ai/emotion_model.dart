enum EmotionLabel {
  anger(0, "분노", "😡"),
  sadness(1, "슬픔", "😢"),
  anxiety(2, "불안", "improving"),
  hurt(3, "상처", "❤️‍🩹"),
  embarrassment(4, "당황", "😳"),
  happiness(5, "기쁨", "🥰");

  final int emotionIndex; // <-- 이름 변경
  final String title;
  final String emoji;

  const EmotionLabel(this.emotionIndex, this.title, this.emoji);

  static EmotionLabel fromIndex(int index) {
    return EmotionLabel.values.firstWhere(
          (e) => e.emotionIndex == index,
      orElse: () => EmotionLabel.happiness,
    );
  }
}

class AnalysisResult {
  final EmotionLabel emotion;
  final double score;
  final String empathyComment;

  AnalysisResult({
    required this.emotion,
    required this.score,
    required this.empathyComment,
  });
}
