import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:naver_login_sdk/naver_login_sdk.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:b612_1/services/database_service.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // ✅ 싱글톤 패턴 적용
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ===============================================================
  // 1. 구글 로그인
  // ===============================================================
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await DatabaseService().saveUser(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      print("구글 로그인 에러: $e");
      return null;
    }
  }

  // ===============================================================
  // 2. 네이버 로그인 (v3.x 콜백 방식)
  // ===============================================================
  Future<bool> signInWithNaver() async {
    final completer = Completer<bool>();

    NaverLoginSDK.authenticate(
      callback: OAuthLoginCallback(
        onSuccess: () {
          print("✅ 네이버 로그인 성공!");
          _fetchNaverProfile(completer);
        },
        onFailure: (errorCode, message) {
          print("❌ 네이버 로그인 실패: $errorCode - $message");
          completer.complete(false);
        },
        onError: (errorCode, message) {
          print("❌ 네이버 로그인 에러: $errorCode - $message");
          completer.complete(false);
        },
      ),
    );

    return completer.future;
  }

  // 네이버 프로필 가져오기 (JSON 파싱 + 재로그인 연결 개선)
  void _fetchNaverProfile(Completer<bool> completer) {
    NaverLoginSDK.profile(
      callback: ProfileCallback(
        onSuccess: (resultCode, message, response) async {
          print("✅ 프로필 응답: $response");

          try {
            final Map<String, dynamic> profileData = jsonDecode(response.toString());

            final String id = profileData['id'] ?? '';
            final String email = profileData['email'] ?? 'naver_user@temp.com';
            final String nickname = profileData['nickname'] ?? profileData['name'] ?? '네이버 사용자';
            final String? profileImage = profileData['profileImage'];
            final String socialUid = "naver_$id";

            print("✅ 파싱된 프로필: $nickname, $email");

            // ✅ 기존 사용자 확인 후 로그인 처리
            await _handleSocialLogin(
              socialUid: socialUid,
              email: email,
              nickname: nickname,
              photoUrl: profileImage,
              socialType: 'naver',
            );

            completer.complete(true);
          } catch (e) {
            print("프로필 처리 에러: $e");

            // 프로필 파싱 실패해도 로그인은 시도
            try {
              await _auth.signInAnonymously();
              await DatabaseService().saveSocialUser(
                uid: "naver_${DateTime.now().millisecondsSinceEpoch}",
                email: "naver_user@temp.com",
                nickname: "네이버 사용자",
                photoUrl: null,
                socialType: 'naver',
              );
              completer.complete(true);
            } catch (e2) {
              print("Firebase 로그인 에러: $e2");
              completer.complete(false);
            }
          }
        },
        onFailure: (errorCode, message) {
          print("❌ 프로필 가져오기 실패: $errorCode - $message");
          completer.complete(false);
        },
      ),
    );
  }

  // ===============================================================
  // 3. 카카오 로그인 (순서 수정 + 재로그인 연결 개선)
  // ===============================================================
  Future<bool> signInWithKakao() async {
    try {
      bool isInstalled = await kakao.isKakaoTalkInstalled();
      kakao.OAuthToken token;

      if (isInstalled) {
        try {
          token = await kakao.UserApi.instance.loginWithKakaoTalk();
        } catch (error) {
          if (error is PlatformException && error.code == 'CANCELED') {
            return false;
          }
          token = await kakao.UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        token = await kakao.UserApi.instance.loginWithKakaoAccount();
      }

      kakao.User user = await kakao.UserApi.instance.me();
      final String socialUid = "kakao_${user.id.toString()}";

      // ✅ 기존 사용자 확인 후 로그인 처리
      await _handleSocialLogin(
        socialUid: socialUid,
        email: user.kakaoAccount?.email ?? "이메일 없음",
        nickname: user.kakaoAccount?.profile?.nickname ?? "이름 없음",
        photoUrl: user.kakaoAccount?.profile?.thumbnailImageUrl,
        socialType: 'kakao',
      );

      return true;
    } catch (e) {
      print("카카오 로그인 에러: $e");
      return false;
    }
  }

  // ===============================================================
  // 4. 게스트(익명) 로그인 - 새로 추가
  // ===============================================================
  Future<bool> signInAsGuest() async {
    try {
      await _auth.signInAnonymously();
      print("✅ 게스트 로그인 성공");
      return true;
    } catch (e) {
      print("❌ 게스트 로그인 에러: $e");
      return false;
    }
  }

  // ===============================================================
  // 5. 소셜 로그인 공통 처리 (재로그인 시 데이터 연결)
  // ===============================================================
  Future<void> _handleSocialLogin({
    required String socialUid,
    required String email,
    required String nickname,
    String? photoUrl,
    required String socialType,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. 로컬에 저장된 이전 Firebase UID 확인
    final savedFirebaseUid = prefs.getString('firebase_uid_$socialUid');

    // 2. Firestore에서 기존 사용자 검색
    final existingUser = await DatabaseService().findUserBySocialUid(socialUid);

    if (existingUser != null && savedFirebaseUid != null) {
      // ✅ 기존 사용자 - 같은 익명 계정 재사용은 불가하므로
      // 새 익명 계정 생성 후 데이터 마이그레이션 처리
      print("✅ 기존 사용자 발견: $socialUid");
    }

    // 3. Firebase 익명 로그인 (먼저!)
    await _auth.signInAnonymously();

    // 4. 사용자 정보 저장
    await DatabaseService().saveSocialUser(
      uid: socialUid,
      email: email,
      nickname: nickname,
      photoUrl: photoUrl,
      socialType: socialType,
    );

    // 5. Firebase UID와 소셜 UID 매핑 로컬 저장
    final currentUid = _auth.currentUser?.uid;
    if (currentUid != null) {
      await prefs.setString('firebase_uid_$socialUid', currentUid);
      await prefs.setString('current_social_uid', socialUid);
    }
  }

  // ===============================================================
  // 6. 로그아웃 (카카오 추가)
  // ===============================================================
  Future<void> signOut() async {
    try {
      // 구글 로그아웃
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      // 네이버 로그아웃
      try {
        await NaverLoginSDK.logout();
      } catch (_) {}

      // ✅ 카카오 로그아웃 추가
      try {
        await kakao.UserApi.instance.logout();
      } catch (_) {}

      // Firebase 로그아웃
      await _auth.signOut();

      // 로컬 소셜 UID 정보 삭제
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_social_uid');

      print("✅ 통합 로그아웃 완료");
    } catch (e) {
      print("로그아웃 에러: $e");
    }
  }

  // ===============================================================
  // 7. 현재 사용자 정보
  // ===============================================================
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // 현재 소셜 로그인 타입 확인
  Future<String?> getCurrentSocialType() async {
    final prefs = await SharedPreferences.getInstance();
    final socialUid = prefs.getString('current_social_uid');
    if (socialUid == null) return null;

    if (socialUid.startsWith('kakao_')) return 'kakao';
    if (socialUid.startsWith('naver_')) return 'naver';
    return 'google';
  }
}