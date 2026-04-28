import 'package:flutter/material.dart';
import 'package:b612_1/models/personality_type.dart';

class PersonalityTestScreen extends StatefulWidget {
  final Function(PersonalityType) onComplete;
  final VoidCallback onBack;

  const PersonalityTestScreen({
    super.key,
    required this.onComplete,
    required this.onBack,
  });

  @override
  State<PersonalityTestScreen> createState() => _PersonalityTestScreenState();
}

class _PersonalityTestScreenState extends State<PersonalityTestScreen> {
  int _currentQuestionIndex = 0;
  List<String> _answers = [];
  String? _selectedAnswer;

  final List<Map<String, dynamic>> _questions = [
    {
      'question': "새로운 사람들과 만나는 상황에서\n어떤 기분이 드나요?",
      'options': [
        {'text': "설레고 즐거운 기분이 든다", 'value': 'extrovert'},
        {'text': "약간 부담스럽지만 괜찮다", 'value': 'ambivert'},
        {'text': "피하고 싶고 부담스럽다", 'value': 'introvert'},
      ]
    },
    {
      'question': "스트레스가 쌓였을 때\n어떻게 해소하시나요?",
      'options': [
        {'text': "친구들과 만나서 이야기하며 해소한다", 'value': 'extrovert'},
        {'text': "상황에 따라 혼자 있거나 사람들과 만난다", 'value': 'ambivert'},
        {'text': "혼자만의 시간을 가지며 조용히 해소한다", 'value': 'introvert'},
      ]
    },
    {
      'question': "주말에 어떤 계획을\n세우는 것을 선호하시나요?",
      'options': [
        {'text': "친구들과 함께하는 활동적인 계획", 'value': 'extrovert'},
        {'text': "그때 기분에 따라 결정한다", 'value': 'ambivert'},
        {'text': "집에서 혼자 보내는 조용한 시간", 'value': 'introvert'},
      ]
    },
    {
      'question': "새로운 환경에\n적응하는 방식은?",
      'options': [
        {'text': "적극적으로 다가가며 빠르게 적응한다", 'value': 'extrovert'},
        {'text': "천천히 관찰하며 점진적으로 적응한다", 'value': 'ambivert'},
        {'text': "조심스럽게 관찰 후 천천히 적응한다", 'value': 'introvert'},
      ]
    },
    {
      'question': "에너지를 충전하는 방법은?",
      'options': [
        {'text': "사람들과 함께 시간을 보낼 때", 'value': 'extrovert'},
        {'text': "혼자 있을 때와 사람들과 있을 때 모두", 'value': 'ambivert'},
        {'text': "혼자만의 조용한 시간을 가질 때", 'value': 'introvert'},
      ]
    },
  ];

  void _handleNext() {
    if (_selectedAnswer == null) return;

    setState(() {
      _answers.add(_selectedAnswer!);
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
        _selectedAnswer = null; // 선택 초기화
      } else {
        // 결과 계산 및 완료 처리
        _calculateResult();
      }
    });
  }

  void _handlePrev() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _answers.removeLast();
        _selectedAnswer = null;
      });
    } else {
      widget.onBack();
    }
  }

  void _calculateResult() {
    int introCount = _answers.where((a) => a == 'introvert').length;
    int extroCount = _answers.where((a) => a == 'extrovert').length;
    int ambiCount = _answers.where((a) => a == 'ambivert').length;

    PersonalityType result;
    if (ambiCount >= 2) {
      result = PersonalityType.ambivert;
    } else if (extroCount > introCount) {
      result = PersonalityType.extrovert;
    } else if (introCount > extroCount) {
      result = PersonalityType.introvert;
    } else {
      result = PersonalityType.ambivert; // 동점일 경우
    }

    widget.onComplete(result);
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

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
                // 상단 네비게이션 및 프로그레스 바
                Row(
                  children: [
                    IconButton(
                      onPressed: _handlePrev,
                      icon: const Icon(Icons.chevron_left, color: Colors.grey),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "${_currentQuestionIndex + 1} / ${_questions.length}",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // 질문 텍스트
                Text(
                  "성향 테스트",
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  question['question'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.4),
                ),

                const SizedBox(height: 48),

                // 선택지 리스트
                Expanded(
                  child: ListView.separated(
                    itemCount: question['options'].length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final option = question['options'][index];
                      final isSelected = _selectedAnswer == option['value'];

                      return InkWell(
                        onTap: () => setState(() => _selectedAnswer = option['value']),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.orange.shade50 : Colors.white,
                            border: Border.all(
                              color: isSelected ? Colors.orange : Colors.grey.shade200,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            option['text'],
                            style: TextStyle(
                              fontSize: 15,
                              color: isSelected ? Colors.orange.shade900 : Colors.grey.shade800,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 다음 버튼
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _selectedAnswer != null ? _handleNext : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      disabledBackgroundColor: Colors.orange.withOpacity(0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: _selectedAnswer != null ? 4 : 0,
                    ),
                    child: Text(
                      _currentQuestionIndex < _questions.length - 1 ? "다음" : "결과 보기",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    // 건너뛰기: 기본값으로 완료 처리 (여기선 Ambivert)
                    widget.onComplete(PersonalityType.ambivert);
                  },
                  child: const Text("건너뛰기", style: TextStyle(color: Colors.grey)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}