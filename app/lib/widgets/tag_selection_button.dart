import 'package:flutter/material.dart';

class TagSelectionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onPressed;
  final bool enabled;

  const TagSelectionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;

    final Color borderColor = !enabled
        ? Colors.grey.shade300
        : isSelected
        ? primaryColor
        : Colors.grey.shade200;

    final Color backgroundColor = !enabled
        ? Colors.grey.shade100
        : isSelected
        ? Colors.orange.shade50
        : Colors.white;

    final Color textColor = !enabled
        ? Colors.grey.shade400
        : isSelected
        ? primaryColor
        : Colors.grey.shade600;

    final double scale = isSelected ? 1.02 : 1.0;

    return Semantics(
      button: true,
      selected: isSelected,
      enabled: enabled,
      label: '$label ${isSelected ? "선택됨" : ""}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(scale),
        transformAlignment: Alignment.center,
        child: OutlinedButton.icon(
          onPressed: enabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            backgroundColor: backgroundColor,
            side: BorderSide(color: borderColor, width: 2.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
            alignment: Alignment.centerLeft,
            foregroundColor: primaryColor,
          ).copyWith(
            overlayColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.pressed)) {
                return Colors.orange.withOpacity(0.1);
              }
              return null;
            }),
          ),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              icon,
              key: ValueKey(isSelected),
              size: 20.0,
              color: textColor,
            ),
          ),
          label: Text(
            label,
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}