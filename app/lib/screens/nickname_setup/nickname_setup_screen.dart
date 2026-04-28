import 'package:flutter/material.dart';

class NicknameSetupScreen extends StatefulWidget {
  final Future<void> Function(String) onComplete; // ✅ Future로 변경
  final VoidCallback onBack;

  const NicknameSetupScreen({
    super.key,
    required this.onComplete,
    required this.onBack,
  });

  @override
  State<NicknameSetupScreen> createState() => _NicknameSetupScreenState();
}

class _NicknameSetupScreenState extends State<NicknameSetupScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 텍스트 변경 시 에러 메시지 초기화
    _nicknameController.addListener(_clearError);
  }

  // ✅ dispose 추가 (메모리 누수 방지)
  @override
  void dispose() {
    _nicknameController.removeListener(_clearError);
    _nicknameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  // ✅ 닉네임 유효성 검사
  String? _validateNickname(String nickname) {
    if (nickname.isEmpty) {
      return '닉네임을 입력해주세요';
    }
    if (nickname.length < 2) {
      return '닉네임은 2자 이상이어야 해요';
    }
    if (nickname.length > 20) {
      return '닉네임은 20자 이하여야 해요';
    }
    // 특수문자 검사 (선택사항)
    final invalidChars = RegExp(r'[!@#$%^&*(),.?":{}|<>]');
    if (invalidChars.hasMatch(nickname)) {
      return '특수문자는 사용할 수 없어요';
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    // 키보드 닫기
    _focusNode.unfocus();

    final nickname = _nicknameController.text.trim();

    // 유효성 검사
    final error = _validateNickname(nickname);
    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    // 중복 클릭 방지
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.onComplete(nickname);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '저장에 실패했습니다. 다시 시도해주세요.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nickname = _nicknameController.text.trim();
    final isValid = _validateNickname(nickname) == null && nickname.isNotEmpty;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE5D6), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 뒤로가기
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, left: 8),
                  child: IconButton(
                    icon: const Icon(
                      Icons.chevron_left,
                      color: Colors.grey,
                      size: 32,
                    ),
                    onPressed: _isLoading ? null : widget.onBack,
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),

                      // 이모지 아이콘
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: const Center(
                          child: Text("🌟", style: TextStyle(fontSize: 32)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "환영합니다!",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "어떻게 불러드릴까요?",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),

                      const SizedBox(height: 32),

                      // 입력 카드
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "닉네임",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _nicknameController,
                              focusNode: _focusNode,
                              enabled: !_isLoading,
                              decoration: InputDecoration(
                                hintText: "닉네임을 입력해주세요",
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: _errorMessage != null ? Colors.red : Colors.orange,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.red),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                // ✅ 입력 완료 아이콘
                                suffixIcon: isValid
                                    ? const Icon(Icons.check_circle, color: Colors.green)
                                    : null,
                              ),
                              maxLength: 20,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _handleSubmit(),
                              onChanged: (_) => setState(() {}), // 버튼 상태 업데이트
                            ),

                            // ✅ 에러 메시지 또는 안내 텍스트
                            const SizedBox(height: 4),
                            if (_errorMessage != null)
                              Text(
                                _errorMessage!,
                                style: const TextStyle(fontSize: 12, color: Colors.red),
                              )
                            else
                              Text(
                                "2~20자, 특수문자 제외",
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // 완료 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: (isValid && !_isLoading) ? _handleSubmit : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            disabledBackgroundColor: Colors.orange.shade200,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: isValid ? 4 : 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text(
                            "소확행 시작하기! 🌟",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}