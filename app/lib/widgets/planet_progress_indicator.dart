import 'package:flutter/material.dart';

/// .tsx의 SVG 행성을 Flutter 위젯으로 단순화한 버전입니다.
/// 물이 차오르는 애니메이션 효과를 구현합니다.
class PlanetProgressIndicator extends StatelessWidget {
  final int completedCount;
  final int totalCount;

  const PlanetProgressIndicator({
    super.key,
    required this.completedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    // 진행률 (0.0 ~ 1.0)
    final double progress = (totalCount == 0) ? 0 : completedCount / totalCount;
    final bool isCompleted = progress >= 1.0;

    const double planetSize = 56.0;
    const Color planetBorderColor = Color(0xFF5A9397);
    const Color waterColor = Color(0xFFE88435);
    const Color planetBaseColor = Color(0xFFF2F2F2);
    const Color glowColor = Color(0xFFEAC141);

    return Container(
      width: planetSize,
      height: planetSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. 행성 기본 (테두리 + 배경)
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: planetBaseColor,
              border: Border.all(color: planetBorderColor, width: 2.5),
            ),
          ),

          // 2. 물 채우기 (ClipOval + AnimatedContainer)
          ClipOval(
            child: Align(
              alignment: Alignment.bottomCenter,
              // 애니메이션 효과
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOut,
                height: planetSize * progress,
                width: planetSize,
                color: waterColor.withOpacity(0.8),
              ),
            ),
          ),

          // 3. 행성 표면 디테일 (크레이터)
          ..._buildCraters(planetBorderColor),

          // 4. 완료 시 반짝임 효과
          if (isCompleted)
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: glowColor.withOpacity(0.4),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withOpacity(0.7),
                    blurRadius: 10.0,
                    spreadRadius: 2.0,
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }

  // .tsx의 크레이터 SVG <circle> 요소를 Dart로 구현
  List<Widget> _buildCraters(Color color) {
    return [
      Positioned(
        top: 10,
        left: 8,
        child: Container(
          width: 5.0,
          height: 5.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2),
          ),
        ),
      ),
      Positioned(
        top: 12,
        right: 10,
        child: Container(
          width: 3.6,
          height: 3.6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
          ),
        ),
      ),
      Positioned(
        bottom: 12,
        left: 10,
        child: Container(
          width: 4.4,
          height: 4.4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.18),
          ),
        ),
      ),
      Positioned(
        bottom: 14,
        right: 12,
        child: Container(
          width: 3.0,
          height: 3.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.12),
          ),
        ),
      ),
    ];
  }
}