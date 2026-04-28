import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DatabaseService {
  // ✅ 싱글톤 패턴 적용
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ✅ 현재 로그인한 사용자 UID 가져오기
  String? get currentUserId => _auth.currentUser?.uid;

  // ===============================================================
  // 1. 유저 정보 저장 (AuthService 연동)
  // ===============================================================
  Future<void> saveUser(User user) async {
    try {
      await _db.collection('users').doc(user.uid).set({
        'email': user.email,
        'nickname': user.displayName ?? '이름 없음',
        'photo_url': user.photoURL,
        'last_login': DateTime.now(),
        'social_type': 'google',
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("❌ 구글 유저 정보 저장 실패: $e");
    }
  }

  // ✅ personalityType 파라미터 추가
  Future<void> saveSocialUser({
    required String uid,
    required String email,
    required String nickname,
    String? photoUrl,
    required String socialType,
    String? personalityType,
  }) async {
    try {
      final firebaseUid = _auth.currentUser?.uid;
      if (firebaseUid == null) {
        debugPrint("❌ Firebase UID가 없습니다. 로그인 먼저 필요!");
        return;
      }

      await _db.collection('users').doc(firebaseUid).set({
        'social_uid': uid,
        'email': email,
        'nickname': nickname,
        'photo_url': photoUrl,
        'last_login': DateTime.now(),
        'social_type': socialType,
        'personality_type': personalityType,
      }, SetOptions(merge: true));

      debugPrint("✅ $socialType 유저 정보 저장 완료 (Firebase UID: $firebaseUid)");
    } catch (e) {
      debugPrint("❌ $socialType 유저 정보 저장 실패: $e");
    }
  }

  // ✅ 소셜 UID로 기존 사용자 찾기 (재로그인 연결용)
  Future<Map<String, dynamic>?> findUserBySocialUid(String socialUid) async {
    try {
      final querySnapshot = await _db
          .collection('users')
          .where('social_uid', isEqualTo: socialUid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return {
          'firebase_uid': doc.id,
          ...doc.data(),
        };
      }
      return null;
    } catch (e) {
      debugPrint("❌ 사용자 검색 실패: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUserData() async {
    if (currentUserId == null) return null;
    try {
      final doc = await _db.collection('users').doc(currentUserId).get();
      return doc.data();
    } catch (e) {
      debugPrint("❌ 사용자 정보 조회 실패: $e");
      return null;
    }
  }

  // ===============================================================
  // 2. 미션 데이터 관리
  // ===============================================================

  // ✅ [탐색 탭용] 공개된 모든 미션 가져오기 (샘플 미션 포함)
  Stream<QuerySnapshot> getPublicMissionsStream() {
    return _db
        .collection('missions')
        .orderBy('likes', descending: true)
        .snapshots();
  }

  // ✅ [홈/기록 탭용] "내"가 추가한 미션만 가져오기
  Stream<QuerySnapshot> getUserMissionsStream() {
    if (currentUserId == null) {
      debugPrint("⚠️ 로그인 필요: getUserMissionsStream");
      return const Stream.empty();
    }

    return _db
        .collection('user_missions')
        .where('user_id', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError((error) {
      debugPrint("❌ 미션 스트림 에러: $error");
      debugPrint("💡 Firebase Console에서 복합 인덱스 생성 필요할 수 있습니다.");
    });
  }

  // ✅ [미션 추가] 사용자가 "내 미션"에 추가할 때
  Future<bool> addUserMission({
    required String title,
    required String description,
    required String tag,
    required int iconCode,
    String? color,
    String? author,
    String? time,
    String? source, // ✅ source 파라미터 추가
  }) async {
    if (currentUserId == null) {
      debugPrint("❌ 로그인이 필요합니다.");
      return false;
    }

    try {
      await _db.collection('user_missions').add({
        'user_id': currentUserId,
        'title': title,
        'description': description,
        'tag': tag,
        'icon_code': iconCode,
        'color': color ?? '#FFFFFF',
        'completed': false,
        'author': author ?? '나',
        'time': time,
        'timestamp': DateTime.now(),
        'source': source ?? 'mine', // ✅ source 파라미터 사용
      });
      debugPrint("✅ 내 미션 추가 완료!");
      return true;
    } catch (e) {
      debugPrint("❌ 미션 추가 에러: $e");
      return false;
    }
  }

  // ===============================================================
  // ✅ [NEW] 공개 미션 추가 (모든 사용자가 탐색 탭에서 볼 수 있음)
  // ===============================================================
  Future<String?> addPublicMission({
    required String title,
    required String description,
    required String tag,
    required int iconCode,
    String? color,
  }) async {
    if (currentUserId == null) {
      debugPrint("❌ 로그인이 필요합니다.");
      return null;
    }

    try {
      // 작성자 닉네임 가져오기
      final userData = await getCurrentUserData();
      final authorName = userData?['nickname'] ?? '익명';

      final docRef = await _db.collection('missions').add({
        'title': title,
        'description': description,
        'tag': tag,
        'icon_code': iconCode,
        'color': color ?? '#FFFFFF',
        'author': authorName,
        'author_id': currentUserId, // 작성자 ID (수정/삭제 권한 확인용)
        'likes': 0,
        'addedCount': 0,
        'timestamp': DateTime.now(),
      });

      debugPrint("✅ 공개 미션 추가 완료! (ID: ${docRef.id})");
      return docRef.id; // 생성된 문서 ID 반환
    } catch (e) {
      debugPrint("❌ 공개 미션 추가 에러: $e");
      return null;
    }
  }

  // ✅ [NEW] 공개 미션 수정 (작성자만 가능)
  Future<bool> updatePublicMission(
      String missionId,
      Map<String, dynamic> data,
      ) async {
    if (currentUserId == null) return false;

    try {
      // 작성자 확인
      final doc = await _db.collection('missions').doc(missionId).get();
      if (!doc.exists) return false;

      final authorId = doc.data()?['author_id'];
      if (authorId != currentUserId) {
        debugPrint("❌ 수정 권한이 없습니다.");
        return false;
      }

      await _db.collection('missions').doc(missionId).update(data);
      debugPrint("✅ 공개 미션 수정 완료!");
      return true;
    } catch (e) {
      debugPrint("❌ 공개 미션 수정 에러: $e");
      return false;
    }
  }

  // ✅ [NEW] 공개 미션 삭제 (작성자만 가능)
  Future<bool> deletePublicMission(String missionId) async {
    if (currentUserId == null) return false;

    try {
      // 작성자 확인
      final doc = await _db.collection('missions').doc(missionId).get();
      if (!doc.exists) return false;

      final authorId = doc.data()?['author_id'];
      if (authorId != currentUserId) {
        debugPrint("❌ 삭제 권한이 없습니다.");
        return false;
      }

      await _db.collection('missions').doc(missionId).delete();
      debugPrint("✅ 공개 미션 삭제 완료!");
      return true;
    } catch (e) {
      debugPrint("❌ 공개 미션 삭제 에러: $e");
      return false;
    }
  }

  // ✅ [NEW] 내가 작성한 공개 미션 목록 가져오기
  Stream<QuerySnapshot> getMyPublicMissionsStream() {
    if (currentUserId == null) {
      return const Stream.empty();
    }

    return _db
        .collection('missions')
        .where('author_id', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ✅ [NEW] 미션 담기 횟수 증가 (다른 사용자가 담을 때)
  Future<void> incrementAddedCount(String missionId) async {
    try {
      await _db.collection('missions').doc(missionId).update({
        'addedCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint("❌ 담기 횟수 증가 에러: $e");
    }
  }

  // [미션 상태 수정] 완료 체크, 사진 URL 저장 등
  Future<bool> updateUserMission(
      String missionId,
      Map<String, dynamic> data,
      ) async {
    try {
      await _db.collection('user_missions').doc(missionId).update(data);
      return true;
    } catch (e) {
      debugPrint("❌ 미션 수정 에러: $e");
      return false;
    }
  }

  // [미션 삭제]
  Future<bool> deleteUserMission(String missionId) async {
    try {
      await _db.collection('user_missions').doc(missionId).delete();
      return true;
    } catch (e) {
      debugPrint("❌ 미션 삭제 에러: $e");
      return false;
    }
  }

  // ===============================================================
  // 3. 사진 업로드 기능 (Firebase Storage)
  // ===============================================================
  Future<String?> uploadImage(String filePath) async {
    if (filePath.isEmpty) return null;
    if (currentUserId == null) {
      debugPrint("❌ 로그인이 필요합니다.");
      return null;
    }

    File file = File(filePath);
    if (!file.existsSync()) {
      debugPrint("❌ 파일이 존재하지 않습니다.");
      return null;
    }

    try {
      String fileName = "${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference ref =
      _storage.ref().child('mission_photos/$currentUserId/$fileName');

      await ref.putFile(file);
      String downloadUrl = await ref.getDownloadURL();
      debugPrint("✅ 이미지 업로드 성공: $downloadUrl");

      return downloadUrl;
    } catch (e) {
      debugPrint("❌ 이미지 업로드 실패: $e");
      return null;
    }
  }

  // ===============================================================
  // 4. 미션 인증 (Completed Missions - 별도 기록용)
  // ===============================================================
  Future<bool> completeMission(
      String uid,
      String missionTitle,
      String review,
      String photoUrl,
      ) async {
    try {
      await _db.collection('completed_missions').add({
        'user_uid': uid,
        'mission_title': missionTitle,
        'review': review,
        'photo_url': photoUrl,
        'timestamp': DateTime.now(),
      });
      return true;
    } catch (e) {
      debugPrint("❌ 인증 저장 실패: $e");
      return false;
    }
  }

  Stream<QuerySnapshot> getCompletedMissionsStream(String uid) {
    return _db
        .collection('completed_missions')
        .where('user_uid', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError((error) {
      debugPrint("❌ 완료 미션 스트림 에러: $error");
    });
  }

  // ===============================================================
  // 5. 닉네임 관리
  // ===============================================================
  Future<bool> updateNickname(String newNickname) async {
    if (currentUserId == null) return false;

    try {
      await _db.collection('users').doc(currentUserId).update({
        'nickname': newNickname,
      });
      return true;
    } catch (e) {
      debugPrint("❌ 닉네임 수정 실패: $e");
      return false;
    }
  }

  // ===============================================================
  // [관리자용] 탐색 탭용 샘플 데이터 업로드
  // ===============================================================
  Future<void> uploadSampleMissions() async {
    final List<Map<String, dynamic>> sampleMissions = [
      {
        'title': '하루 2L 물 마시기',
        'description': '건강을 위해 수분을 충분히 섭취하세요.',
        'tag': 'coffee',
        'icon_code': Icons.water_drop.codePoint,
        'likes': 120,
        'author': 'B612 관리자',
      },
      {
        'title': '아침 스트레칭',
        'description': '상쾌한 아침을 여는 5분 스트레칭.',
        'tag': 'leaf',
        'icon_code': Icons.accessibility_new.codePoint,
        'likes': 85,
        'author': '요가마스터',
      },
      {
        'title': '감사일기 쓰기',
        'description': '오늘 하루 감사했던 일 3가지 적기.',
        'tag': 'heart',
        'icon_code': Icons.edit_note.codePoint,
        'likes': 300,
        'author': '마음챙김',
      },
    ];

    debugPrint("⏳ 샘플 미션 업로드 시작...");
    for (var mission in sampleMissions) {
      final QuerySnapshot existing = await _db
          .collection('missions')
          .where('title', isEqualTo: mission['title'])
          .get();

      if (existing.docs.isEmpty) {
        await _db.collection('missions').add({
          'title': mission['title'],
          'description': mission['description'],
          'tag': mission['tag'],
          'likes': mission['likes'],
          'author': mission['author'],
          'icon_code': mission['icon_code'],
          'addedCount': 0,
          'timestamp': DateTime.now(),
        });
      }
    }
    debugPrint("✅ 샘플 데이터 업로드 완료!");
  }
}