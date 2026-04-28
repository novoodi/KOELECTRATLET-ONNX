import 'package:flutter/material.dart';
import 'package:b612_1/models/personality_type.dart';

class PersonalityResultScreen extends StatelessWidget {
  final PersonalityType personalityType;
  final Function(String, String) onComplete;
  final VoidCallback onBack;

  const PersonalityResultScreen({
    super.key,
    required this.personalityType,
    required this.onComplete,
    required this.onBack,
  });

  // 성향별 데이터
  Map<String, dynamic> _getData() {
    switch (personalityType) {
      case PersonalityType.introvert:
        return {
          'title': "조용한 성찰가",
          'emoji': "🌙",
          'desc': "혼자만의 시간을 소중히 여기며,\n깊이 있는 경험을 추구하는 당신",
          'traits': ["깊이 있는 사고", "집중력 강함", "신중한 결정", "질 높은 인간관계"],
          'missions': ["혼자만의 산책하기", "좋아하는 책 한 챕터 읽기", "일기 쓰기"],
          'color': Colors.purple.shade50,
          'iconColor': Colors.purple,
        };
      case PersonalityType.extrovert:
        return {
          'title': "에너지 넘치는 소통가",
          'emoji': "☀️",
          'desc': "사람들과의 만남에서 에너지를 얻고,\n활동적인 경험을 좋아하는 당신",
          'traits': ["활발한 소통", "에너지 넘침", "적극적 참여", "새로운 도전"],
          'missions': ["친구와 카페 가기", "모르는 사람에게 친절 베풀기", "야외 활동"],
          'color': Colors.orange.shade50,
          'iconColor': Colors.orange,
        };
      case PersonalityType.ambivert:
        return {
          'title': "균형잡힌 실천가",
          'emoji': "⚖️",
          'desc': "상황에 따라 유연하게 적응하며,\n다양한 경험을 즐기는 당신",
          'traits': ["균형잡힌 성향", "상황 적응력", "다양한 관심사", "유연한 사고"],
          'missions': ["새로운 취미 도전", "자연 속 힐링", "창의적 활동"],
          'color': Colors.green.shade50,
          'iconColor': Colors.green,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _getData();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE5D6), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),

                const SizedBox(height: 20),
                const Text(
                  "테스트 완료!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "당신의 성향을 분석했어요",
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 32),

                // 결과 카드
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // 성향 타입 배지
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: data['color'] as Color,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  data['emoji'] as String,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  data['title'] as String,
                                  style: TextStyle(
                                    color: data['iconColor'] as Color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 설명
                          Text(
                            data['desc'] as String,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              height: 1.5,
                              color: Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // 특징
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "주요 특징",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (data['traits'] as List<String>)
                                .map((t) => Chip(
                              label: Text(
                                t,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Colors.grey.shade100,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ))
                                .toList(),
                          ),

                          const SizedBox(height: 24),

                          // 추천 미션
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "추천 소확행",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...(data['missions'] as List<String>)
                              .map((m) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  size: 16,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  m,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ))
                              .toList(),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 버튼
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      // 닉네임 설정은 다음 화면(NicknameSetupScreen)에서 진행
                      onComplete("", data['title'] as String);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "닉네임 설정하기",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}