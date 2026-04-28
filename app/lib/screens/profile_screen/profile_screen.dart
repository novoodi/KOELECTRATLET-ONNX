import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:b612_1/app_shell.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile userProfile;
  final VoidCallback onBack;
  final VoidCallback onLogout;
  final Function(String)? onNicknameChanged; // ✅ 콜백 추가
  final VoidCallback? onRetakePersonalityTest; // ✅ 성향 테스트 다시하기

  const ProfileScreen({
    super.key,
    required this.userProfile,
    required this.onBack,
    required this.onLogout,
    this.onNicknameChanged,
    this.onRetakePersonalityTest,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  bool _isSaving = false;
  late TextEditingController _nickController;

  // 알림 설정 상태
  bool _notiEnabled = true;
  bool _reminderEnabled = true;
  bool _weeklyReportEnabled = false;

  @override
  void initState() {
    super.initState();
    _nickController = TextEditingController(text: widget.userProfile.nickname);
    _loadNotificationSettings();
  }

  // ✅ dispose 추가 (메모리 누수 방지)
  @override
  void dispose() {
    _nickController.dispose();
    super.dispose();
  }

  // ✅ 알림 설정 불러오기
  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notiEnabled = prefs.getBool('noti_enabled') ?? true;
      _reminderEnabled = prefs.getBool('reminder_enabled') ?? true;
      _weeklyReportEnabled = prefs.getBool('weekly_report_enabled') ?? false;
    });
  }

  // ✅ 알림 설정 저장
  Future<void> _saveNotificationSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // ✅ 닉네임 저장 (콜백 방식)
  Future<void> _toggleEdit() async {
    if (_isEditing) {
      final newNickname = _nickController.text.trim();

      if (newNickname.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('닉네임을 입력해주세요')),
        );
        return;
      }

      if (newNickname.length > 20) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('닉네임은 20자 이하여야 합니다')),
        );
        return;
      }

      setState(() => _isSaving = true);

      try {
        // 상위 위젯에 닉네임 변경 알림
        widget.onNicknameChanged?.call(newNickname);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('닉네임이 변경되었습니다'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('저장 실패: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }

    setState(() => _isEditing = !_isEditing);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: widget.onBack,
        ),
        title: const Text(
          "프로필 & 설정",
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. 프로필 정보 카드
            _buildCard(
              title: "프로필 정보",
              action: _isSaving
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : TextButton.icon(
                icon: Icon(_isEditing ? Icons.check : Icons.edit, size: 16),
                label: Text(_isEditing ? "저장" : "편집"),
                onPressed: _toggleEdit,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFF7F50),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              children: [
                // 닉네임
                if (_isEditing)
                  TextField(
                    controller: _nickController,
                    maxLength: 20,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                      counterText: '',
                    ),
                  )
                else
                  Text(
                    widget.userProfile.nickname,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                const SizedBox(height: 4),
                // 성향 타입
                Text(
                  widget.userProfile.personalityType,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Divider(height: 1, thickness: 0.5),
                ),

                // 계정 정보 섹션
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "계정",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    if (widget.userProfile.isGuest)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "게스트 로그인",
                            style: TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // TODO: 로그인 화면으로 이동
                              print("로그인 화면으로 이동");
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 0,
                              ),
                              minimumSize: const Size(0, 32),
                            ),
                            child: const Text(
                              "로그인",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        widget.userProfile.email,
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                  ],
                )
              ],
            ),

            const SizedBox(height: 16),

            // 2. 성향 테스트 다시하기 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: InkWell(
                onTap: widget.onRetakePersonalityTest,
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    const Text(
                      "성향 테스트 다시하기",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      widget.userProfile.personalityType,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 3. 알림 설정 카드
            _buildCard(
              title: "알림 설정",
              icon: Icons.notifications,
              iconColor: Colors.orange,
              children: [
                _buildSwitchRow(
                  "푸시 알림",
                  "앱 알림 받기",
                  _notiEnabled,
                      (v) {
                    setState(() => _notiEnabled = v);
                    _saveNotificationSetting('noti_enabled', v);
                  },
                ),
                _buildSwitchRow(
                  "미션 리마인더",
                  "완료하지 않은 미션 알림",
                  _reminderEnabled,
                      (v) {
                    setState(() => _reminderEnabled = v);
                    _saveNotificationSetting('reminder_enabled', v);
                  },
                ),
                _buildSwitchRow(
                  "주간 리포트",
                  "주간 달성 결과 받기",
                  _weeklyReportEnabled,
                      (v) {
                    setState(() => _weeklyReportEnabled = v);
                    _saveNotificationSetting('weekly_report_enabled', v);
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 4. 기타 메뉴 카드
            _buildCard(
              children: [
                _buildMenuRow(Icons.lock_outline, "개인정보 처리방침"),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: Divider(height: 1, thickness: 0.5),
                ),
                _buildMenuRow(Icons.help_outline, "고객센터"),
              ],
            ),

            const SizedBox(height: 16),

            // 5. 로그아웃 카드 (const 오류 수정)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onLogout,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    // ✅ const 오류 수정: Row를 const로 변경
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red, size: 20),
                        SizedBox(width: 12),
                        Text(
                          "로그아웃",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 탈퇴하기 링크
            GestureDetector(
              onTap: () {
                _showDeleteAccountDialog();
              },
              child: const Text(
                "탈퇴하기",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ✅ 탈퇴 확인 다이얼로그
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('정말 탈퇴하시겠습니까?'),
        content: const Text('탈퇴하면 모든 데이터가 삭제되며\n복구할 수 없습니다.'),
        actions: [
          TextButton(
            child: const Text('취소'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('탈퇴'),
            onPressed: () {
              Navigator.pop(context);
              // TODO: 실제 탈퇴 로직
              print("계정 탈퇴 처리");
            },
          ),
        ],
      ),
    );
  }

  // 카드 위젯 빌더
  Widget _buildCard({
    String? title,
    IconData? icon,
    Color? iconColor,
    Widget? action,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20, color: iconColor ?? Colors.black),
                      const SizedBox(width: 8)
                    ],
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                if (action != null) action,
              ],
            ),
            if (action == null)
              const SizedBox(height: 16)
            else
              const SizedBox(height: 8),
          ],
          ...children
        ],
      ),
    );
  }

  // 스위치 행 빌더 (deprecated API 수정)
  Widget _buildSwitchRow(
      String title,
      String sub,
      bool value,
      Function(bool) onChanged,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: Colors.orange,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade300,
              // ✅ deprecated MaterialStateProperty → WidgetStateProperty
              trackOutlineColor: WidgetStateProperty.resolveWith(
                    (states) => Colors.transparent,
              ),
            ),
          )
        ],
      ),
    );
  }

  // 메뉴 행 빌더
  Widget _buildMenuRow(IconData icon, String text) {
    return InkWell(
      onTap: () {
        // TODO: 각 메뉴 클릭 처리
        print("$text 클릭");
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}