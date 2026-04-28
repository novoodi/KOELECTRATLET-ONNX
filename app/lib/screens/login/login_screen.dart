import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  final Future<void> Function() onGuestLogin; // ✅ Future로 변경
  final Future<bool> Function(String) onSocialLogin; // ✅ 결과 반환

  const LoginScreen({
    super.key,
    required this.onGuestLogin,
    required this.onSocialLogin,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _loadingProvider; // 어떤 버튼이 로딩 중인지

  // ✅ 소셜 로그인 처리 (로딩 + 에러 처리)
  Future<void> _handleSocialLogin(String provider) async {
    if (_isLoading) return; // 중복 클릭 방지

    setState(() {
      _isLoading = true;
      _loadingProvider = provider;
    });

    try {
      final success = await widget.onSocialLogin(provider);

      if (!success && mounted) {
        _showErrorSnackBar('$provider 로그인에 실패했습니다. 다시 시도해주세요.');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('오류가 발생했습니다: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingProvider = null;
        });
      }
    }
  }

  // ✅ 게스트 로그인 처리
  Future<void> _handleGuestLogin() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _loadingProvider = 'guest';
    });

    try {
      await widget.onGuestLogin();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('게스트 로그인에 실패했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingProvider = null;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. 전체 배경 그라데이션
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFE5D6), Colors.white],
              ),
            ),
          ),

          // 2. 하단 소행성 배경 (둥근 언덕 모양)
          Positioned(
            bottom: -100,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFF8C42), Color(0xFFFFA07A)],
                ),
                borderRadius: BorderRadius.vertical(
                  top: Radius.elliptical(300, 100),
                ),
              ),
            ),
          ),

          // 3. 메인 콘텐츠
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    "로그인",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // 카드 영역
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "시작하기",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 네이버 로그인 버튼
                        _buildSocialButton(
                          provider: 'naver',
                          text: "네이버로 시작하기",
                          textColor: Colors.white,
                          backgroundColor: const Color(0xFF03C75A),
                          borderColor: const Color(0xFF03C75A),
                          icon: const Text(
                            "N",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 카카오 로그인 버튼
                        _buildSocialButton(
                          provider: 'kakao',
                          text: "카카오로 시작하기",
                          textColor: Colors.brown,
                          backgroundColor: const Color(0xFFFEE500),
                          borderColor: const Color(0xFFFEE500),
                          icon: const Icon(
                            Icons.chat_bubble,
                            size: 18,
                            color: Colors.brown,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 구글 로그인 버튼
                        _buildSocialButton(
                          provider: 'google',
                          text: "Google로 시작하기",
                          textColor: Colors.black87,
                          backgroundColor: Colors.white,
                          borderColor: Colors.grey.shade300,
                          icon: const Text(
                            "G",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 구분선
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey.shade300)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                "또는",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey.shade300)),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // 게스트 로그인
                        _buildGuestButton(),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // 하단 약관 텍스트
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      "계속 진행하시면 서비스 이용약관 및 개인정보처리방침에\n동의하는 것으로 간주됩니다.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ✅ 전체 로딩 오버레이 (선택사항)
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.1),
            ),
        ],
      ),
    );
  }

  // ✅ 소셜 로그인 버튼 (로딩 상태 포함)
  Widget _buildSocialButton({
    required String provider,
    required String text,
    required Color textColor,
    required Color backgroundColor,
    required Color borderColor,
    required Widget icon,
  }) {
    final isThisLoading = _isLoading && _loadingProvider == provider;
    final isDisabled = _isLoading && _loadingProvider != provider;

    return InkWell(
      onTap: isDisabled ? null : () => _handleSocialLogin(provider),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        decoration: BoxDecoration(
          color: isDisabled ? backgroundColor.withOpacity(0.5) : backgroundColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isThisLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textColor,
                ),
              )
            else
              icon,
            const SizedBox(width: 10),
            Text(
              isThisLoading ? "로그인 중..." : text,
              style: TextStyle(
                color: isDisabled ? textColor.withOpacity(0.5) : textColor,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ 게스트 버튼 (로딩 상태 포함)
  Widget _buildGuestButton() {
    final isThisLoading = _isLoading && _loadingProvider == 'guest';
    final isDisabled = _isLoading && _loadingProvider != 'guest';

    return TextButton.icon(
      onPressed: isDisabled ? null : _handleGuestLogin,
      icon: isThisLoading
          ? const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
      )
          : const Icon(Icons.person_outline, color: Colors.grey),
      label: Text(
        isThisLoading ? "접속 중..." : "게스트로 둘러보기",
        style: TextStyle(
          color: isDisabled ? Colors.grey.shade300 : Colors.grey,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }
}