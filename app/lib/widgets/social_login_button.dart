import 'package:flutter/material.dart';

// 클래스 이름에서 _(언더바)를 제거하여 public으로 만듭니다.
class SocialLoginButton extends StatelessWidget {
  final String text;
  final Widget icon;
  final VoidCallback onPressed;
  final Color borderColor;
  final Color? foregroundColor;
  final Color? backgroundColor;

  const SocialLoginButton({
    super.key, // super.key 추가
    required this.text,
    required this.icon,
    required this.onPressed,
    required this.borderColor,
    this.foregroundColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // `variant="outline"` -> Flutter의 `OutlinedButton`
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        // `w-full h-12`
        minimumSize: const Size(double.infinity, 48.0),
        // `border-2`
        side: BorderSide(color: borderColor, width: 2.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        foregroundColor: foregroundColor ?? Colors.grey.shade800,
        backgroundColor: backgroundColor ?? Colors.transparent,
      ),
      // `mr-3`
      icon: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: icon,
      ),
      label: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}