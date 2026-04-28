import 'package:flutter/material.dart';

/// React의 성향 `Badge` 컴포넌트에 해당합니다.
class PersonalityBadge extends StatelessWidget {
  final Widget icon;
  final String title;
  final List<Color> gradientColors;
  final double paddingVertical;
  final double paddingHorizontal;

  const PersonalityBadge({
    super.key,
    required this.icon,
    required this.title,
    required this.gradientColors,
    this.paddingVertical = 8.0,
    this.paddingHorizontal = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: paddingVertical,
        horizontal: paddingHorizontal,
      ),
      decoration: BoxDecoration(
        // `bg-gradient-to-r ${personality.color}`
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // 컨텐츠 크기에 맞게 Row 크기 조절
        children: [
          // `icon`
          icon,
          const SizedBox(width: 8.0), // `ml-2`
          // `title`
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}