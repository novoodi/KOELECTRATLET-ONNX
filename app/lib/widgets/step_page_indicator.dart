import 'package:flutter/material.dart';

class StepPageIndicator extends StatelessWidget {
  final int currentStep; // 현재 단계 (0부터 시작)
  final int totalSteps;
  final Function(int)? onDotTapped; // ✅ nullable로 변경 (탭 비활성화 가능)
  final bool enableTap; // ✅ 탭 활성화 여부

  const StepPageIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.onDotTapped,
    this.enableTap = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${currentStep + 1} / $totalSteps 단계',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalSteps, (index) {
            final bool isActive = index == currentStep;
            final bool isPast = index < currentStep;

            // 색상 설정
            Color color;
            if (isActive) {
              color = const Color(0xFFF9A825); // 현재: 오렌지
            } else if (isPast) {
              color = const Color(0xFFF9A825).withOpacity(0.5); // 지난 단계: 연한 오렌지
            } else {
              color = Colors.grey.shade300; // 미래 단계: 회색
            }

            return Semantics(
              button: enableTap && onDotTapped != null,
              label: '${index + 1}단계 ${isActive ? "현재" : isPast ? "완료" : ""}',
              child: GestureDetector(
                onTap: (enableTap && onDotTapped != null)
                    ? () => onDotTapped!(index)
                    : null,
                behavior: HitTestBehavior.opaque,
                // ✅ 터치 영역 확대
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.0,
                    vertical: 8.0,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    width: isActive ? 24.0 : 8.0,
                    height: 8.0,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4.0),
                      // ✅ 활성 상태에 그림자 추가
                      boxShadow: isActive
                          ? [
                        BoxShadow(
                          color: const Color(0xFFF9A825).withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ]
                          : null,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// ✅ 대안: 탭 없이 표시만 하는 버전
class StepPageIndicatorReadOnly extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepPageIndicatorReadOnly({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return StepPageIndicator(
      currentStep: currentStep,
      totalSteps: totalSteps,
      enableTap: false,
    );
  }
}