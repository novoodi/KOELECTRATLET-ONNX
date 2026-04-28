import 'package:flutter/material.dart';

/// PersonalityTest, OnboardingIntro 등
/// 여러 단계의 화면에서 공통으로 사용하는 상단바입니다.
class StepProgressBar extends StatelessWidget {
  final int currentStep; // 현재 단계 (1부터 시작)
  final int totalSteps; // 전체 단계 수
  final VoidCallback onBack;
  final bool showBackButton; // ✅ 뒤로가기 버튼 표시 여부

  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ 진행률 계산 수정: int를 double로 변환
    final double progress = currentStep / totalSteps.toDouble();

    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 32.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. 뒤로가기 버튼
              if (showBackButton)
                _CustomBackButton(onPressed: onBack)
              else
                const SizedBox(width: 40.0),

              // 2. 단계 카운터
              Text(
                '$currentStep / $totalSteps',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                ),
              ),

              // 3. 오른쪽 공간 (균형 맞추기)
              const SizedBox(width: 40.0),
            ],
          ),
          const SizedBox(height: 16.0),

          // 진행 바
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8.0,
                  backgroundColor: Colors.grey.shade200,
                  color: const Color(0xFFF9A825),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// ✅ CustomBackButton 위젯 (파일 내 정의)
class _CustomBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CustomBackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}

/// ✅ 별도 파일로 분리해서 사용하고 싶다면 이 클래스를 export
class CustomBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;

  const CustomBackButton({
    super.key,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: iconColor ?? Colors.grey,
          ),
        ),
      ),
    );
  }
}