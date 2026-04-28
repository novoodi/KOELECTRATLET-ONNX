import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Mission {
  final String id;
  final String title;
  final String description;
  final bool completed;
  final String tag;
  final String icon;
  final String color;
  final String? photo;
  final DateTime? completedAt;
  final String? time;
  final bool isPublic;
  final String source;

  Mission({
    required this.id,
    required this.title,
    this.description = '',
    this.completed = false,
    this.tag = 'daily',
    this.icon = 'sun',
    this.color = '#FFFFFF',
    this.photo,
    this.completedAt,
    this.time,
    this.isPublic = false,
    this.source = 'mine',
  });

  // ✅ 1. 카피 메서드 (nullable 필드 처리 개선)
  // clearPhoto: true로 설정하면 photo를 null로 만들 수 있음
  Mission copyWith({
    String? id,
    String? title,
    String? description,
    bool? completed,
    String? tag,
    String? icon,
    String? color,
    String? photo,
    bool clearPhoto = false, // ✅ 추가: photo를 null로 설정하고 싶을 때
    DateTime? completedAt,
    bool clearCompletedAt = false, // ✅ 추가: completedAt을 null로 설정하고 싶을 때
    String? time,
    bool clearTime = false, // ✅ 추가
    bool? isPublic,
    String? source,
  }) {
    return Mission(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      tag: tag ?? this.tag,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      photo: clearPhoto ? null : (photo ?? this.photo),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      time: clearTime ? null : (time ?? this.time),
      isPublic: isPublic ?? this.isPublic,
      source: source ?? this.source,
    );
  }

  // 2. Firestore -> App (데이터 받아올 때)
  factory Mission.fromMap(Map<String, dynamic> map, String docId) {
    // completedAt 안전하게 파싱
    DateTime? parsedDate;
    final rawDate = map['completedAt'];

    if (rawDate != null) {
      if (rawDate is Timestamp) {
        parsedDate = rawDate.toDate();
      } else if (rawDate is String) {
        parsedDate = DateTime.tryParse(rawDate);
      }
    }

    return Mission(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      completed: map['completed'] == true || map['completed'] == 'true',
      tag: map['tag'] ?? 'daily',
      icon: map['icon'] ?? 'sun',
      color: map['color'] ?? '#FFFFFF',
      photo: map['photo'],
      completedAt: parsedDate,
      time: map['time'],
      isPublic: map['isPublic'] ?? false,
      source: map['source'] ?? 'mine',
    );
  }

  // 3. App -> Firestore (데이터 저장할 때)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'completed': completed,
      'tag': tag,
      'icon': icon,
      'color': color,
      'photo': photo,
      // ✅ 명시적 Timestamp 변환 (null이면 null 유지)
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'time': time,
      'isPublic': isPublic,
      'source': source,
    };
  }

  // 4. UI 헬퍼: Hex String을 Flutter Color로 변환
  Color get colorObj {
    try {
      final hexCode = color.replaceAll('#', '');
      return Color(int.parse('FF$hexCode', radix: 16));
    } catch (e) {
      return Colors.white;
    }
  }

  // 5. UI 헬퍼: String 아이콘 ID를 Flutter IconData로 변환
  IconData get iconData {
    switch (icon) {
      case 'sun': return Icons.wb_sunny_rounded;
      case 'book': return Icons.menu_book_rounded;
      case 'leaf': return Icons.eco_rounded;
      case 'heart': return Icons.favorite_rounded;
      case 'coffee': return Icons.coffee_rounded;
      case 'star': return Icons.star_rounded;
      case 'tree': return Icons.park_rounded;
      case 'zap': return Icons.bolt_rounded;
      case 'flame': return Icons.local_fire_department_rounded;
      case 'water_drop': return Icons.water_drop_rounded;
      default: return Icons.wb_sunny_rounded;
    }
  }

  // ✅ 6. 디버깅용 toString
  @override
  String toString() {
    return 'Mission(id: $id, title: $title, completed: $completed, photo: ${photo != null ? "있음" : "없음"})';
  }

  // ✅ 7. 동등성 비교 (리스트에서 contains 등 사용할 때 필요)
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Mission && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}