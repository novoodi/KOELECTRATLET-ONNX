import 'package:flutter/material.dart';

/// 태그(String)를 IconData로 매핑합니다.
final Map<String, IconData> iconMap = {
  'wellness': Icons.wb_sunny_outlined,
  'daily': Icons.coffee_outlined,
  'growth': Icons.book_outlined,
  'happiness': Icons.sentiment_satisfied_alt_outlined,
  'love': Icons.favorite_border,
  'goal': Icons.ads_click,
  'energy': Icons.bolt,
  'achievement': Icons.star_border,
  'nature': Icons.cloud_outlined,
  'mindful': Icons.spa_outlined,
  'creative': Icons.music_note_outlined,
  'hobby': Icons.camera_alt_outlined,
  'beauty': Icons.local_florist_outlined,
  'routine': Icons.access_time,
};

/// 태그 ID에 맞는 아이콘을 반환합니다.
IconData getIconForTag(String tagId) {
  return iconMap[tagId] ?? Icons.sentiment_satisfied_alt_outlined; // 기본값
}