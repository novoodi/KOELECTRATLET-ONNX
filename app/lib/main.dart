import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:naver_login_sdk/naver_login_sdk.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'package:b612_1/services/auth_service.dart';
import 'package:b612_1/screens/login/login_screen.dart';
import 'package:b612_1/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 카카오 초기화
  kakao.KakaoSdk.init(nativeAppKey: 'b5edb9f1862a0c6c7a43e426918be57c');

  // 2. 네이버 초기화
  await NaverLoginSDK.initialize(
    urlScheme: 'naverlogin',
    clientId: '_x8Vz7Ub52jDlTwNh_va',
    clientSecret: 'A2sTff_Asw',
    clientName: '소확행',
  );

  // 3. 파이어베이스 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 4. 날짜 포맷 초기화
  await initializeDateFormatting('ko_KR', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '소확행',
      theme: ThemeData(
        primaryColor: const Color(0xFFFF8C42),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF8C42)),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Pretendard',
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. 로딩 중
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Colors.orange),
              ),
            );
          }

          // 2. 에러 발생 시
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('오류가 발생했습니다: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // 앱 재시작 또는 재시도 로직
                      },
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            );
          }

          // 3. 로그인 됨 -> AppShell (메인 화면)
          if (snapshot.hasData) {
            return const AppShell();
          }

          // 4. 로그인 안됨 -> LoginScreen
          return LoginScreen(
            // ✅ 게스트 로그인 구현
            onGuestLogin: () async {
              final success = await AuthService().signInAsGuest();
              if (!success) {
                // 에러 처리 (필요시 Snackbar 등으로 알림)
                print("❌ 게스트 로그인 실패");
              }
            },
            // ✅ 수정: bool 값을 반환하도록 수정
            onSocialLogin: (provider) async {
              bool success = false;

              try {
                if (provider == 'google') {
                  final result = await AuthService().signInWithGoogle();
                  success = result != null;
                } else if (provider == 'naver') {
                  success = await AuthService().signInWithNaver();
                } else if (provider == 'kakao') {
                  success = await AuthService().signInWithKakao();
                }

                if (!success) {
                  print("❌ $provider 로그인 실패");
                }
              } catch (e) {
                print("❌ $provider 로그인 오류: $e");
                success = false;
              }

              return success; // ✅ bool 반환 추가
            },
          );
        },
      ),
    );
  }
}