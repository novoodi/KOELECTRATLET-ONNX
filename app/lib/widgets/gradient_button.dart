import 'package:flutter/material.dart';

/// React의 그라데이션 버튼 컴포넌트에 해당합니다.
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool disabled;
  final double height;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.disabled = false,
    this.height = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    // `disabled:opacity-50`
    final bool isDisabled = disabled || onPressed == null;

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          // `bg-gradient-to-r from-orange-400 to-pink-400`
          gradient: const LinearGradient(
            colors: [Color(0xFFFB923C), Color(0xFFF472B6)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(8.0),
          // `shadow-lg`
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withOpacity(0.2),
              blurRadius: 10.0,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            minimumSize: Size(double.infinity, height),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16.0,
            ),
          ),
        ),
      ),
    );
  }
}