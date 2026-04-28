import 'dart:async';
import 'package:flutter/material.dart';

class OnboardingIntroScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onBack;

  const OnboardingIntroScreen({
    super.key,
    required this.onComplete,
    required this.onBack,
  });

  @override
  State<OnboardingIntroScreen> createState() => _OnboardingIntroScreenState();
}

class _OnboardingIntroScreenState extends State<OnboardingIntroScreen> {
  int _currentStep = 0;
  bool _showFinalScreen = false;
  double _asteroidProgress = 0.0;
  Timer? _animationTimer;

  final List<Map<String, dynamic>> _introSteps = [
    {
      'title': "오늘 탭",
      'description': "오늘의\n소소한 행복\n미션을\n살펴보세요",
      'highlight': "오늘",
      'icon': Icons.today_rounded,
    },
    {
      'title': "탐색 탭",
      'description': "다른 사람의\n미션을\n탐색해보세요",
      'highlight': "탐색",
      'icon': Icons.explore_rounded,
    },
    {
      'title': "기록 탭",
      'description': "나의 기록을\n모아봐요\n갤러리를 공유해\n보세요",
      'highlight': "기록",
      'icon': Icons.photo_library_rounded,
    },
  ];

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  void _startAsteroidAnimation() {
    _animationTimer?.cancel(); // 기존 타이머 취소
    _animationTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_asteroidProgress >= 1.0) {
          _asteroidProgress = 1.0;
          timer.cancel();
        } else {
          _asteroidProgress += 0.02;
        }
      });
    });
  }

  void _handleNext() {
    if (_currentStep < _introSteps.length - 1) {
      setState(() => _currentStep++);
    } else {
      setState(() => _showFinalScreen = true);
      _startAsteroidAnimation();
    }
  }

  void _handlePrev() {
    if (_showFinalScreen) {
      setState(() {
        _showFinalScreen = false;
        _asteroidProgress = 0.0;
      });
      _animationTimer?.cancel();
    } else if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      widget.onBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showFinalScreen) {
      return _buildFinalScreen();
    }

    final currentIntro = _introSteps[_currentStep];

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
          child: Column(
            children: [
              // 상단 뒤로가기
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _handlePrev,
                  icon: const Icon(Icons.arrow_back, color: Colors.grey),
                  label: const Text("뒤로", style: TextStyle(color: Colors.grey)),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 인디케이터
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_introSteps.length, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: index == _currentStep ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: index == _currentStep
                                  ? Colors.orange
                                  : Colors.grey.shade300,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 32),

                      // 타이틀
                      Text(
                        currentIntro['title'],
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      // 설명 텍스트 (하이라이트 처리)
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 28,
                            height: 1.5,
                            color: Colors.black87,
                            fontFamily: 'Pretendard',
                          ),
                          children: _parseDescription(
                            currentIntro['description'],
                            currentIntro['highlight'],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // 목업 이미지 영역
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFFF8C42), Color(0xFFFFD27F)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            currentIntro['icon'] as IconData,
                            size: 80,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // 버튼들
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _handleNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentStep == _introSteps.length - 1
                                    ? "완료"
                                    : "다음",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: widget.onComplete,
                        child: const Text(
                          "건너뛰기",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<TextSpan> _parseDescription(String text, String highlight) {
    final parts = text.split(highlight);
    if (parts.length == 1) return [TextSpan(text: text)];

    return [
      TextSpan(text: parts[0]),
      TextSpan(
        text: highlight,
        style: const TextStyle(
          color: Colors.orange,
          fontWeight: FontWeight.bold,
        ),
      ),
      if (parts.length > 1) TextSpan(text: parts[1]),
    ];
  }

  Widget _buildFinalScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFD4F1D4), Color(0xFFA8E6CF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _handlePrev,
                  icon: const Icon(Icons.arrow_back, color: Colors.grey),
                  label: const Text("뒤로", style: TextStyle(color: Colors.grey)),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "행복을 모아",
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.black87,
                          fontFamily: 'Pretendard',
                        ),
                        children: [
                          TextSpan(text: "여러분의 "),
                          TextSpan(
                            text: "소행성",
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(text: "을 꾸며보세요"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

                    // 소행성 애니메이션
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.2),
                                blurRadius: 40,
                              )
                            ],
                          ),
                        ),
                        // 채워지는 부분 (클리핑)
                        ClipOval(
                          child: Stack(
                            children: [
                              Container(
                                width: 240,
                                height: 240,
                                color: Colors.orange.shade100,
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                height: 240 * _asteroidProgress,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.orange.shade200,
                                        Colors.orange.shade400,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 외곽선
                        Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.orange.shade200,
                              width: 4,
                            ),
                          ),
                        ),
                        // 중앙 아이콘
                        Icon(
                          Icons.auto_awesome,
                          size: 60,
                          color: _asteroidProgress > 0.5
                              ? Colors.white
                              : Colors.orange.shade300,
                        ),
                        // 반짝이 (완료 시)
                        if (_asteroidProgress > 0.8) ...[
                          const Positioned(
                            top: 20,
                            right: 40,
                            child: Icon(
                              Icons.star,
                              color: Colors.yellow,
                              size: 30,
                            ),
                          ),
                          const Positioned(
                            top: 60,
                            left: 30,
                            child: Icon(
                              Icons.star,
                              color: Colors.yellow,
                              size: 20,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 60),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: widget.onComplete,
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
                                "성향 테스트",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.chevron_right, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "나에게 맞는 소확행을 찾기 위한 간단한 질문이에요",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}