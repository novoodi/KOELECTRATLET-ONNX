import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:b612_1/models/mission.dart';
import 'package:b612_1/models/personality_type.dart';
import 'package:b612_1/services/database_service.dart';
import 'package:b612_1/services/auth_service.dart';

// Screens
import 'package:b612_1/screens/onboarding_intro/onboarding_intro_screen.dart';
import 'package:b612_1/screens/personality_test/personality_test_screen.dart';
import 'package:b612_1/screens/personality_result/personality_result_screen.dart';
import 'package:b612_1/screens/nickname_setup/nickname_setup_screen.dart';
import 'package:b612_1/screens/home_tab/home_tab_screen.dart';
import 'package:b612_1/screens/mission_browser/mission_browser_screen.dart';
import 'package:b612_1/screens/history_tab/history_tab_screen.dart';
import 'package:b612_1/screens/profile_screen/profile_screen.dart';
import 'package:b612_1/widgets/modals/mood_selector.dart';

enum OnboardingStep {
  intro,
  personalityTest,
  personalityResult,
  nicknameSetup,
  completed
}

// ✅ UserProfile에 copyWith 추가
class UserProfile {
  final String nickname;
  final String personalityType;
  final String email;
  final String bio;
  final bool isGuest;

  const UserProfile({
    required this.nickname,
    required this.personalityType,
    required this.email,
    required this.bio,
    this.isGuest = true,
  });

  UserProfile copyWith({
    String? nickname,
    String? personalityType,
    String? email,
    String? bio,
    bool? isGuest,
  }) {
    return UserProfile(
      nickname: nickname ?? this.nickname,
      personalityType: personalityType ?? this.personalityType,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      isGuest: isGuest ?? this.isGuest,
    );
  }

  factory UserProfile.guest() {
    return const UserProfile(
      nickname: '게스트',
      personalityType: '미설정',
      email: '',
      bio: '나만의 소확행을 찾아보세요',
      isGuest: true,
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // 상태 변수
  bool _isLoadingProfile = true;
  OnboardingStep _onboardingStep = OnboardingStep.completed;
  int _currentTabIndex = 1; // 0: 탐색, 1: 오늘(홈), 2: 기록

  // 데이터
  UserProfile _userProfile = UserProfile.guest();
  PersonalityType? _tempPersonalityType;
  Map<String, bool> _attendanceData = {};
  Set<String> _addedMissionIds = <String>{};

  // 기분 및 스트릭
  bool _showMoodSelector = false;
  String? _currentMood;
  int _streakDays = 0;

  // ✅ 아이콘 ID → IconData 매핑
  static const Map<String, IconData> _iconMap = {
    'sun': Icons.wb_sunny_rounded,
    'book': Icons.menu_book_rounded,
    'leaf': Icons.eco_rounded,
    'heart': Icons.favorite_rounded,
    'coffee': Icons.coffee_rounded,
    'star': Icons.star_rounded,
    'tree': Icons.park_rounded,
    'zap': Icons.bolt_rounded,
    'flame': Icons.local_fire_department_rounded,
  };

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadUserProfile();
    if (!mounted) return;
    await _loadAttendanceData();
    _calculateStreak();
    setState(() => _isLoadingProfile = false);
  }

  Future<void> _loadUserProfile() async {
    try {
      final userData = await DatabaseService().getCurrentUserData();
      if (!mounted) return;
      final user = FirebaseAuth.instance.currentUser;

      if (userData == null) {
        setState(() {
          _onboardingStep = OnboardingStep.intro;
          _userProfile = UserProfile(
            nickname: '게스트',
            personalityType: '미설정',
            email: user?.email ?? '',
            bio: '나만의 소확행을 찾아보세요',
            isGuest: user?.isAnonymous ?? true,
          );
        });
      } else {
        setState(() {
          _onboardingStep = OnboardingStep.completed;
          _userProfile = UserProfile(
            nickname: userData['nickname'] ?? '사용자',
            personalityType: userData['personality_type'] ?? '꾸준한 실천가',
            email: userData['email'] ?? '',
            bio: userData['bio'] ?? '오늘도 행복한 하루 보내세요!',
            isGuest: false,
          );
        });
      }
    } catch (e) {
      debugPrint('프로필 로드 에러: $e');
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
          _onboardingStep = OnboardingStep.intro;
        });
      }
    }
  }

  Future<void> _loadAttendanceData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('attendance')
          .get();

      final Map<String, bool> data = {};
      for (final doc in snapshot.docs) {
        data[doc.id] = doc.data()['completed'] ?? false;
      }

      if (mounted) {
        setState(() => _attendanceData = data);
      }
    } catch (e) {
      debugPrint('출석 데이터 로드 에러: $e');
    }
  }

  void _calculateStreak() {
    int streak = 0;
    DateTime date = DateTime.now();

    while (true) {
      final dateKey = date.toIso8601String().split('T')[0];
      if (_attendanceData[dateKey] == true) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    setState(() => _streakDays = streak);
  }

  // --- Handlers ---

  // 1. 미션 완료 토글
  Future<void> _handleToggleMission(String id) async {
    try {
      final docRef =
      FirebaseFirestore.instance.collection('user_missions').doc(id);
      final doc = await docRef.get();
      if (doc.exists) {
        final current = doc.data()?['completed'] ?? false;
        await docRef.update({
          'completed': !current,
          'completedAt': !current ? FieldValue.serverTimestamp() : null,
        });
      }
    } catch (e) {
      debugPrint('미션 토글 에러: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('미션 상태 변경에 실패했습니다')),
        );
      }
    }
  }

  // 2. 미션 추가 (탐색 탭 -> 내 미션)
  Future<void> _handleAddMissionFromBrowser(
      Mission mission, String? originalId) async {
    try {
      await DatabaseService().addUserMission(
        title: mission.title,
        description: mission.description,
        tag: mission.tag,
        iconCode: mission.iconData.codePoint,
        color: mission.color,
        author: mission.source,
        source: 'imported', // ✅ 탐색에서 가져온 미션은 'imported'로 분류
      );

      // ✅ 담기 횟수 증가
      if (originalId != null) {
        await DatabaseService().incrementAddedCount(originalId);
        if (mounted) {
          setState(() => _addedMissionIds.add(originalId));
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("내 행성에 미션이 추가되었어요! 🎉")),
        );
      }
    } catch (e) {
      debugPrint('미션 추가 에러: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('미션 추가에 실패했습니다')),
        );
      }
    }
  }

  // 3. ✅ 직접 미션 추가 (공개 미션 기능 추가)
  void _handleCreateMission(
      String title,
      String iconId,
      String color,
      bool isPublic,
      String? time,
      ) async {
    final iconData = _iconMap[iconId] ?? Icons.star_rounded;

    try {
      // 1. 내 미션에 항상 추가
      await DatabaseService().addUserMission(
        title: title,
        description: '',
        tag: 'custom',
        iconCode: iconData.codePoint,
        color: color,
        author: _userProfile.nickname,
        time: time,
      );

      // 2. ✅ 공개 설정이면 공개 미션에도 추가
      if (isPublic) {
        final publicMissionId = await DatabaseService().addPublicMission(
          title: title,
          description: '',
          tag: 'custom',
          iconCode: iconData.codePoint,
          color: color,
        );

        if (publicMissionId != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('미션이 공개되었어요! 다른 사용자들도 볼 수 있어요 🌟'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('새 미션이 추가되었어요! ✨')),
          );
        }
      }
    } catch (e) {
      debugPrint('미션 생성 에러: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('미션 추가에 실패했습니다')),
        );
      }
    }
  }

  // 4. 사진 추가
  Future<void> _handleAddPhoto(String missionId, String? path) async {
    if (path == null) {
      await DatabaseService().updateUserMission(missionId, {'photo': null});
      return;
    }

    if (path.startsWith('http')) {
      await DatabaseService().updateUserMission(missionId, {'photo': path});
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("사진을 업로드 중입니다...")),
        );
      }

      String? downloadUrl = await DatabaseService().uploadImage(path);

      if (downloadUrl != null) {
        await DatabaseService()
            .updateUserMission(missionId, {'photo': downloadUrl});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("사진 저장 완료! 🎉")),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("사진 업로드에 실패했습니다")),
          );
        }
      }
    }
  }

  // 5. 미션 삭제
  Future<void> _handleDeleteMission(String missionId) async {
    try {
      await DatabaseService().deleteUserMission(missionId);
    } catch (e) {
      debugPrint('미션 삭제 에러: $e');
    }
  }

  // 6. 하루 마무리
  Future<void> _handleFinishDay() async {
    try {
      final todayStr = DateTime.now().toIso8601String().split("T")[0];
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('attendance')
            .doc(todayStr)
            .set({
          'completed': true,
          'timestamp': FieldValue.serverTimestamp()
        });
      }

      setState(() => _attendanceData[todayStr] = true);
      _calculateStreak();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('오늘 하루 기록이 저장되었습니다! 🎉')),
        );
      }
    } catch (e) {
      debugPrint('하루 마무리 에러: $e');
    }
  }

  // 7. 정렬 및 초기화
  void _handleSortMissions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('미션이 정렬되었습니다.')),
    );
  }

  Future<void> _handleResetMissions() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('미션이 초기화되었습니다.')),
      );
    }
  }

  // 8. 닉네임 변경
  Future<void> _handleNicknameChanged(String newNickname) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'nickname': newNickname});
      }

      setState(() {
        _userProfile = _userProfile.copyWith(nickname: newNickname);
      });
    } catch (e) {
      debugPrint('닉네임 변경 에러: $e');
    }
  }

  // 9. 성향 테스트 다시하기
  void _handleRetakePersonalityTest() {
    setState(() {
      _onboardingStep = OnboardingStep.personalityTest;
    });
  }

  // 10. 기분 선택 닫기
  void _closeMoodSelector() {
    setState(() => _showMoodSelector = false);
  }

  // --- 온보딩 완료 핸들러 ---
  Future<void> _finishOnboarding(String nickname) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final personalityTypeString =
          _tempPersonalityType?.toString().split('.').last ?? 'ambivert';

      await DatabaseService().saveSocialUser(
        uid: user.uid,
        email: user.email ?? '',
        nickname: nickname,
        socialType: 'guest',
        personalityType: personalityTypeString,
      );
    }

    if (mounted) {
      setState(() {
        _userProfile = _userProfile.copyWith(
          nickname: nickname,
          personalityType: _getPersonalityTypeLabel(_tempPersonalityType),
          isGuest: false,
        );
        _onboardingStep = OnboardingStep.completed;
        _showMoodSelector = true;
      });
    }
  }

  String _getPersonalityTypeLabel(PersonalityType? type) {
    switch (type) {
      case PersonalityType.introvert:
        return '조용한 성찰가';
      case PersonalityType.extrovert:
        return '에너지 넘치는 소통가';
      case PersonalityType.ambivert:
      default:
        return '균형잡힌 실천가';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.orange),
              SizedBox(height: 16),
              Text('로딩 중...'),
            ],
          ),
        ),
      );
    }

    if (_onboardingStep != OnboardingStep.completed) {
      return _buildOnboarding();
    }

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentTabIndex,
            children: [
              // 0: 탐색
              MissionBrowserScreen(
                onAddMission: _handleAddMissionFromBrowser,
                addedMissionIds: _addedMissionIds,
              ),
              // 1: 오늘
              _buildTodayTab(),
              // 2: 기록
              _buildHistoryTab(),
              // 3: 프로필
              ProfileScreen(
                userProfile: _userProfile,
                onBack: () => setState(() => _currentTabIndex = 1),
                onLogout: () async {
                  await AuthService().signOut();
                },
                onNicknameChanged: _handleNicknameChanged,
                onRetakePersonalityTest: _handleRetakePersonalityTest,
              ),
            ],
          ),
          if (_showMoodSelector)
            MoodSelector(
              onSelectMood: (mood) {
                setState(() {
                  _currentMood = mood;
                  _showMoodSelector = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("오늘의 기분: $mood 🌟")),
                );
              },
              onClose: _closeMoodSelector,
            ),
        ],
      ),
      bottomNavigationBar: _currentTabIndex == 3
          ? null
          : _CustomBottomNavBar(
        currentIndex: _currentTabIndex,
        onTap: (index) => setState(() => _currentTabIndex = index),
      ),
    );
  }

  Widget _buildTodayTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: DatabaseService().getUserMissionsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('오류가 발생했습니다: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.orange),
          );
        }

        final missions = snapshot.data?.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Mission.fromMap(data, doc.id);
        }).toList() ??
            [];

        return HomeTabScreen(
          missions: missions,
          onToggleMission: _handleToggleMission,
          onAddMission: _handleCreateMission,
          onDeleteMission: _handleDeleteMission,
          onAddPhoto: _handleAddPhoto,
          onFinishDay: _handleFinishDay,
          onSortMissions: _handleSortMissions,
          onResetMissions: _handleResetMissions,
          currentMood: _currentMood,
          streakDays: _streakDays,
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: DatabaseService().getUserMissionsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('오류가 발생했습니다: ${snapshot.error}'),
          );
        }

        final missions = snapshot.data?.docs.map((doc) {
          return Mission.fromMap(
              doc.data() as Map<String, dynamic>, doc.id);
        }).toList() ??
            [];

        return HistoryTabScreen(
          attendanceData: _attendanceData,
          missionHistory: missions,
          onOpenProfile: () => setState(() => _currentTabIndex = 3),
          userProfile: _userProfile,
        );
      },
    );
  }

  Widget _buildOnboarding() {
    switch (_onboardingStep) {
      case OnboardingStep.intro:
        return OnboardingIntroScreen(
          onComplete: () =>
              setState(() => _onboardingStep = OnboardingStep.personalityTest),
          onBack: () {},
        );
      case OnboardingStep.personalityTest:
        return PersonalityTestScreen(
          onComplete: (type) {
            setState(() {
              _tempPersonalityType = type;
              _onboardingStep = OnboardingStep.personalityResult;
            });
          },
          onBack: () => setState(() => _onboardingStep = OnboardingStep.intro),
        );
      case OnboardingStep.personalityResult:
        return PersonalityResultScreen(
          personalityType: _tempPersonalityType ?? PersonalityType.ambivert,
          onComplete: (_, __) =>
              setState(() => _onboardingStep = OnboardingStep.nicknameSetup),
          onBack: () =>
              setState(() => _onboardingStep = OnboardingStep.personalityTest),
        );
      case OnboardingStep.nicknameSetup:
        return NicknameSetupScreen(
          onComplete: _finishOnboarding,
          onBack: () => setState(
                  () => _onboardingStep = OnboardingStep.personalityResult),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _CustomBottomNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.0,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildNavItem(
                icon: Icons.search_rounded,
                label: '탐색',
                index: 0,
                onTap: () => onTap(0),
              ),
              const Spacer(),
              _buildNavItem(
                icon: Icons.calendar_today_rounded,
                label: '기록',
                index: 2,
                onTap: () => onTap(2),
              ),
            ],
          ),
          Positioned(
            bottom: 20.0,
            child: GestureDetector(
              onTap: () => onTap(1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                transform: Matrix4.identity()
                  ..scale(currentIndex == 1 ? 1.1 : 1.0)
                  ..translate(0.0, currentIndex == 1 ? -5.0 : 0.0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 12.0,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8C42), Color(0xFFFF6B00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30.0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B00).withOpacity(0.4),
                      blurRadius: 15.0,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.home_rounded,
                      size: 24.0,
                      color: Colors.white,
                    ),
                    if (currentIndex == 1) ...[
                      const SizedBox(width: 8),
                      const Text(
                        '오늘',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required VoidCallback onTap,
  }) {
    final bool isSelected = currentIndex == index;
    final Color color =
    isSelected ? const Color(0xFFFF8C42) : Colors.grey.shade400;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.only(top: 15, bottom: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 26.0, color: color),
              const SizedBox(height: 4.0),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.0,
                  color: color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}