import 'package:flutter/material.dart';

// .tsx의 tagColors를 Flutter의 LinearGradient로 변환
final Map<String, LinearGradient> _tagGradients = {
  'wellness': const LinearGradient(colors: [Color(0xFFDCFCE7), Color(0xFFF0FDF4)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  'daily': const LinearGradient(colors: [Color(0xFFDBEAFE), Color(0xFFEFF6FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  'growth': const LinearGradient(colors: [Color(0xFFEDE9FE), Color(0xFFF5F3FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  'happiness': const LinearGradient(colors: [Color(0xFFFEF9C3), Color(0xFFFEFDE8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  'love': const LinearGradient(colors: [Color(0xFFFCE7F3), Color(0xFFFDF2F8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  'goal': const LinearGradient(colors: [Color(0xFFFEE2E2), Color(0xFFFEF2F2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  'energy': const LinearGradient(colors: [Color(0xFFFFEDD5), Color(0xFFFFF7ED)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  'achievement': const LinearGradient(colors: [Color(0xFFE0E7FF), Color(0xFFEEF2FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  'nature': const LinearGradient(colors: [Color(0xFFD1FAE5), Color(0xFFECFDF5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  'mindful': const LinearGradient(colors: [Color(0xFFCCFBF1), Color(0xFFF0FDFA)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  'creative': const LinearGradient(colors: [Color(0xFFEBE5FF), Color(0xFFF5F3FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  'hobby': const LinearGradient(colors: [Color(0xFFCFFAFE), Color(0xFFECFEFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  'beauty': const LinearGradient(colors: [Color(0xFFFDE4E7), Color(0xFFFEF1F2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  'routine': const LinearGradient(colors: [Color(0xFFF3F4F6), Color(0xFFF9FAFB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
};

LinearGradient getGradientForTag(String tag) {
  return _tagGradients[tag] ?? _tagGradients['wellness']!;
}
Color getCategoryColor(String tag) {
  switch (tag.toLowerCase()) {
    case 'history':
      return Colors.blue;
    case 'culture':
      return Colors.red;
    case 'food':
      return Colors.orange;
    case 'travel':
      return Colors.green;
    default:
      return Colors.grey;
  }
}
