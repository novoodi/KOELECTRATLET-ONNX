import 'package:flutter/material.dart';

/// .tsx의 옵션 <button>에 해당하는 재사용 가능한 위젯입니다.
class SelectionOptionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isSelected;

  const SelectionOptionButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    // .tsx의 conditional className을 Flutter 스타일로 변환합니다.
    final Color borderColor = isSelected ? const Color(0xFFF9A825) : Colors.grey.shade200;
    final Color backgroundColor = isSelected ? const Color(0xFFFFF7E6) : Colors.white;
    final Color textColor = isSelected ? const Color(0xFFC2410C) : Colors.grey.shade700;

    // `hover:` 스타일은 Flutter의 `styleFrom`에서
    // `onSurface`나 `overlayColor` 등으로 처리할 수 있으나,
    // 모바일에서는 `hover`가 없으므로 기본 스타일만 적용합니다.
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        // `w-full p-4`
        minimumSize: const Size(double.infinity, 56.0),
        padding: const EdgeInsets.all(16.0),
        // `text-left`
        alignment: Alignment.centerLeft,
        backgroundColor: backgroundColor,
        // `border-2`
        side: BorderSide(color: borderColor, width: 2.0),
        // `rounded-xl`
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        // `text-gray-700` (기본값)
        foregroundColor: textColor,
      ),
      child: Text(
        text,
        // `text-sm leading-relaxed`
        style: TextStyle(
          fontSize: 14.0,
          color: textColor,
          height: 1.5,
        ),
      ),
    );
  }
}