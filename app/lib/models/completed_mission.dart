import 'package:cloud_firestore/cloud_firestore.dart';

class CompletedMission {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime completedAt;
  final bool hasPhoto;
  final List<String> photos;
  final String? representativePhoto;
  final bool isPublic;
  final bool isImported;

  CompletedMission({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.completedAt,
    this.hasPhoto = false,
    this.photos = const [],
    this.representativePhoto,
    required this.isPublic,
    required this.isImported,
  });

  // ✅ Firestore -> App (null 안전성 개선)
  factory CompletedMission.fromMap(Map<String, dynamic> map, String docId) {
    // completedAt 안전하게 파싱
    DateTime parsedDate;
    final rawDate = map['completedAt'];

    if (rawDate == null) {
      parsedDate = DateTime.now(); // 기본값
    } else if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return CompletedMission(
      id: docId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '기타',
      completedAt: parsedDate,
      hasPhoto: map['hasPhoto'] ?? false,
      photos: List<String>.from(map['photos'] ?? []),
      representativePhoto: map['representativePhoto'],
      isPublic: map['isPublic'] ?? false,
      isImported: map['isImported'] ?? false,
    );
  }

  // App -> Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'completedAt': Timestamp.fromDate(completedAt), // ✅ 명시적 Timestamp 변환
      'hasPhoto': hasPhoto,
      'photos': photos,
      'representativePhoto': representativePhoto,
      'isPublic': isPublic,
      'isImported': isImported,
    };
  }

  // ✅ copyWith 추가 (상태 업데이트용)
  CompletedMission copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    DateTime? completedAt,
    bool? hasPhoto,
    List<String>? photos,
    String? representativePhoto,
    bool clearRepresentativePhoto = false, // null로 설정하고 싶을 때
    bool? isPublic,
    bool? isImported,
  }) {
    return CompletedMission(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      completedAt: completedAt ?? this.completedAt,
      hasPhoto: hasPhoto ?? this.hasPhoto,
      photos: photos ?? this.photos,
      representativePhoto: clearRepresentativePhoto ? null : (representativePhoto ?? this.representativePhoto),
      isPublic: isPublic ?? this.isPublic,
      isImported: isImported ?? this.isImported,
    );
  }
}