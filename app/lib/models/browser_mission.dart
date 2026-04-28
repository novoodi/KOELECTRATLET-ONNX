import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class BrowserMission {
  final String id;
  final String title;
  final String description;
  final String tag;
  final IconData icon;
  final String? author;
  final int likes;
  final Color color;
  final int addedCount;
  final List<String> photos;
  final DateTime? timestamp; // ✅ 추가: 생성 시간

  BrowserMission({
    required this.id,
    required this.title,
    required this.description,
    required this.tag,
    required this.icon,
    this.author,
    required this.likes,
    required this.color,
    required this.addedCount,
    required this.photos,
    this.timestamp, // ✅ 추가
  });

  // Firestore 데이터를 모델로 변환하는 팩토리 메서드
  factory BrowserMission.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BrowserMission(
      id: doc.id,
      title: data['title'] ?? '제목 없음',
      description: data['description'] ?? '설명 없음',
      tag: data['tag'] ?? 'star',
      icon: IconData(data['icon_code'] ?? Icons.star.codePoint, fontFamily: 'MaterialIcons'),
      author: data['author'],
      likes: data['likes'] ?? 0,
      color: _getColorFromTag(data['tag']),
      addedCount: data['addedCount'] ?? Random().nextInt(500),
      photos: List<String>.from(data['photos'] ?? []),
      // ✅ 추가: Firestore Timestamp → DateTime 변환
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  // 태그별 색상 매핑
  static Color _getColorFromTag(String? tag) {
    switch (tag) {
      case 'coffee': return const Color(0xFFFFC6A5);
      case 'leaf': return const Color(0xFFCAFFBF);
      case 'heart': return const Color(0xFFFFD6E8);
      case 'book': return const Color(0xFFA0C4FF);
      case 'sun': return const Color(0xFFFFD6A5);
      case 'star': return const Color(0xFFFDFD96);
      default: return const Color(0xFFFFE4B5);
    }
  }
}