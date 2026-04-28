import 'dart:io';
import 'package:flutter/material.dart';
import 'package:b612_1/models/mission.dart';
import 'package:b612_1/widgets/mission_card.dart';
import 'package:b612_1/widgets/modals/create_mission_modal.dart';

// ⭐️ [AI] 관련 임포트 추가 (경로가 맞는지 확인해주세요)
import '../../ai/emotion_classifier.dart';
import '../../ai/emotion_model.dart';
import '../../ai/mission_recommender.dart';

class HomeTabScreen extends StatefulWidget {
  final List<Mission> missions;
  final List<Mission> missionHistory;
  final Function(String) onToggleMission;
  final Function(String title, String icon, String color, bool isPublic, String? time) onAddMission;
  final Function(String) onDeleteMission;
  final Function(String, String?) onAddPhoto;
  final Function(Mission)? onEditMission;
  final VoidCallback onFinishDay;
  final VoidCallback onSortMissions;
  final VoidCallback onResetMissions;
  final String? currentMood;
  final int streakDays;

  const HomeTabScreen({
    super.key,
    required this.missions,
    this.missionHistory = const [],
    required this.onToggleMission,
    required this.onAddMission,
    required this.onDeleteMission,
    required this.onAddPhoto,
    this.onEditMission,
    required this.onFinishDay,
    required this.onSortMissions,
    required this.onResetMissions,
    this.currentMood,
    required this.streakDays,
  });

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  DateTime _selectedWeekDate = DateTime.now();
  String _filterTab = 'all';

  // ⭐️ [AI] 서비스 인스턴스 생성
  final EmotionClassifierService _aiService = EmotionClassifierService();

  // 날짜 포맷팅
  String get _dateString => "${_selectedWeekDate.month}월 ${_selectedWeekDate.day}일";
  String get _dayOfWeek => ['월', '화', '수', '목', '금', '토', '일'][_selectedWeekDate.weekday - 1];

  bool get _isToday {
    final now = DateTime.now();
    return _selectedWeekDate.year == now.year &&
        _selectedWeekDate.month == now.month &&
        _selectedWeekDate.day == now.day;
  }

  @override
  void initState() {
    super.initState();
    // ⭐️ [AI] 모델 로드 시작
    _aiService.init();
  }

  @override
  void dispose() {
    // ⭐️ [AI] 메모리 해제
    _aiService.close();
    super.dispose();
  }

  // ⭐️ [AI] 감정 입력 다이얼로그
  void _showAiDialog() {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Text("AI 마음 읽기 ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("✨", style: TextStyle(fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "오늘 하루 어떤 기분이 드시나요?\nAI가 딱 맞는 소확행을 찾아드릴게요!",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "예: 오늘 실수를 해서 좀 우울해...",
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("취소", style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () {
                if (textController.text.trim().isEmpty) return;

                // 1. 분석 실행
                final result = _aiService.analyze(textController.text);
                Navigator.pop(context); // 입력창 닫기

                if (result != null) {
                  // 2. 결과 시트 보여주기
                  _showResultSheet(result);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A5ACD), // Slate Blue (AI 느낌)
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text("분석하기", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ⭐️ [AI] 분석 결과 및 추천 바텀 시트
  void _showResultSheet(AnalysisResult result) {
    // 감정에 맞는 추천 미션 리스트 (문자열 리스트)
    final recommendedMissions = MissionRecommender.getRecommendations(result.emotion);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          height: MediaQuery.of(context).size.height * 0.6, // 화면의 60% 높이
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 이모지 & 감정 타이틀
              Text(result.emotion.emoji, style: const TextStyle(fontSize: 50)),
              const SizedBox(height: 12),
              Text(
                "\"${result.emotion.title}\"이 느껴지시네요",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),

              // 공감 멘트 박스
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF), // 연한 보라색 배경
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  result.empathyComment,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF6A5ACD), fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 30),

              // 추천 리스트 헤더
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "🎁 기분 전환을 위한 추천 미션",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 12),

              // 리스트뷰
              Expanded(
                child: ListView.separated(
                  itemCount: recommendedMissions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final missionTitle = recommendedMissions[index];
                    return GestureDetector(
                      onTap: () {
                        // ⭐️ 클릭 시 바로 미션 추가 (기본 아이콘/색상 지정)
                        widget.onAddMission(
                          missionTitle,          // 제목
                          'star',                // 아이콘 (기본값 설정 필요, 예: 'star' or 'face')
                          '0xFF9C27B0',          // 색상 (보라색 계열 Hex String)
                          false,                 // 공개 여부
                          null,                  // 시간
                        );
                        Navigator.pop(context); // 시트 닫기
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("['$missionTitle'] 미션이 추가되었어요!"),
                            backgroundColor: const Color(0xFF6A5ACD),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: Color(0xFF6A5ACD), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                missionTitle,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ),
                            const Icon(Icons.add_circle_outline, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 주간 날짜 계산
  List<DateTime> _getWeekDates() {
    final current = _selectedWeekDate;
    final currentWeekday = current.weekday == 7 ? 0 : current.weekday;
    final sunday = current.subtract(Duration(days: currentWeekday));
    return List.generate(7, (index) => sunday.add(Duration(days: index)));
  }

  // ... (기존 _getCompletionRate, _getCompletedCount, _filteredMissions, _showFinishDialog 등은 그대로 유지)
  double _getCompletionRate(DateTime date) {
    final now = DateTime.now();
    final isTargetToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    if (isTargetToday) {
      if (widget.missions.isEmpty) return 0.0;
      final completed = widget.missions.where((m) => m.completed).length;
      return completed / widget.missions.length;
    } else {
      final dayMissions = widget.missionHistory.where((m) {
        if (m.completedAt == null) return false;
        return m.completedAt!.year == date.year &&
            m.completedAt!.month == date.month &&
            m.completedAt!.day == date.day;
      }).toList();
      if (dayMissions.isEmpty) return 0.0;
      return 1.0;
    }
  }

  int _getCompletedCount(DateTime date) {
    final now = DateTime.now();
    final isTargetToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    if (isTargetToday) {
      return widget.missions.where((m) => m.completed).length;
    } else {
      return widget.missionHistory.where((m) {
        if (m.completedAt == null) return false;
        return m.completedAt!.year == date.year &&
            m.completedAt!.month == date.month &&
            m.completedAt!.day == date.day;
      }).length;
    }
  }

  List<Mission> get _filteredMissions {
    List<Mission> result;
    if (_isToday) {
      result = widget.missions;
    } else {
      result = widget.missionHistory.where((m) {
        if (m.completedAt == null) return false;
        return m.completedAt!.year == _selectedWeekDate.year &&
            m.completedAt!.month == _selectedWeekDate.month &&
            m.completedAt!.day == _selectedWeekDate.day;
      }).toList();
    }
    if (_filterTab == 'mine') {
      result = result.where((m) => m.source == 'mine').toList();
    } else if (_filterTab == 'imported') {
      result = result.where((m) => m.source == 'imported').toList();
    }
    return result;
  }

  void _showFinishDialog() {
    final now = DateTime.now();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, size: 20, color: Colors.grey.shade400),
                ),
              ),
              const Text("오늘 하루 마무리", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text("${now.month}월 ${now.day}일을 마치겠어요?", style: TextStyle(color: Colors.grey.shade600, fontSize: 15)),
              const SizedBox(height: 8),
              Text("완료: ${widget.missions.where((m) => m.completed).length}개 / 전체: ${widget.missions.length}개", style: const TextStyle(color: Colors.orange, fontSize: 13)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text("아니요", style: TextStyle(color: Colors.grey.shade700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onFinishDay();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B00),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text("네", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showEditMissionDialog(Mission mission) {
    if (widget.onEditMission == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('편집 기능이 준비 중입니다')));
      return;
    }
    widget.onEditMission!(mission);
  }

  @override
  Widget build(BuildContext context) {
    final weekDates = _getWeekDates();
    final todayRate = _getCompletionRate(_selectedWeekDate);
    final completedCount = _getCompletedCount(_selectedWeekDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. 상단 헤더
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _dateString,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              if (!_isToday) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text("지난 기록", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            "$_dayOfWeek요일",
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // ⭐️ [AI] 버튼 추가 (보라색 아이콘)
                          if (_isToday) ...[
                            _buildCircleBtn(
                              Icons.auto_awesome, // AI 느낌 아이콘
                              const Color(0xFF6A5ACD), // Slate Blue 색상
                              Colors.white,
                              _showAiDialog, // 클릭 시 다이얼로그 호출
                            ),
                            const SizedBox(width: 8),
                          ],

                          if (_isToday)
                            _buildCircleBtn(
                              Icons.add,
                              Colors.orange,
                              Colors.white,
                                  () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => CreateMissionModal(
                                    onCreateMission: widget.onAddMission,
                                  ),
                                );
                              },
                            ),

                          if (_isToday) const SizedBox(width: 8),
                          _buildCircleBtn(
                            Icons.share,
                            Colors.grey.shade100,
                            Colors.grey.shade700,
                                () {},
                          ),
                          const SizedBox(width: 8),
                          if (_isToday)
                            PopupMenuButton<String>(
                              offset: const Offset(0, 45),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              color: Colors.white,
                              surfaceTintColor: Colors.white,
                              elevation: 4,
                              onSelected: (value) {
                                if (value == 'sort') widget.onSortMissions();
                                if (value == 'reset') widget.onResetMissions();
                              },
                              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                _buildPopupItem('sort', '미션 정렬'),
                                _buildPopupItem('alarm', '알림 설정'),
                                _buildPopupItem('template', '미션 템플릿'),
                                const PopupMenuDivider(),
                                _buildPopupItem('reset', '완료 미션 초기화'),
                              ],
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.more_vert, size: 20, color: Colors.grey.shade700),
                              ),
                            ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 주간 날짜
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: weekDates.map((date) => _buildDayItem(date)).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. 메인 컨텐츠 (이하 기존 코드 동일)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 왼쪽: 게이지
                Column(
                  children: [
                    if (widget.currentMood != null && _isToday) ...[
                      const Text("기분", style: TextStyle(fontSize: 10, color: Colors.grey)),
                      Text(widget.currentMood!, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                    ],
                    Container(
                      width: 50,
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(25))),
                          FractionallySizedBox(
                            heightFactor: todayRate == 0 ? 0.05 : todayRate,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: _isToday
                                      ? [Colors.orange.shade300, Colors.orange.shade500]
                                      : [Colors.grey.shade300, Colors.grey.shade400],
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "${(todayRate * 100).toInt()}%",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: todayRate > 0.5 ? Colors.white : Colors.grey.shade700,
                                    ),
                                  ),
                                  if (!_isToday)
                                    Text("$completedCount개", style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_isToday)
                      GestureDetector(
                        onTap: _showFinishDialog,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3)),
                            ],
                          ),
                          child: const Icon(Icons.flag, color: Colors.white),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedWeekDate = DateTime.now();
                          });
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.today, color: Colors.orange.shade700),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 16),

                // 오른쪽: 리스트
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _buildFilterTab('all', '전체'),
                            _buildFilterTab('mine', 'MY'),
                            _buildFilterTab('imported', '탐색'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (_filteredMissions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Column(
                            children: [
                              Icon(
                                _isToday ? Icons.add_circle_outline : Icons.history,
                                size: 40,
                                color: Colors.orange.shade200,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isToday ? "아직 리스트가 없어요" : "이 날의 기록이 없어요",
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        )
                      else if (_isToday) ...[
                        if (_filteredMissions.any((m) => !m.completed)) ...[
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 8.0, left: 4),
                              child: Text("진행 중", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                            ),
                          ),
                          ..._filteredMissions.where((m) => !m.completed).map((m) => MissionCard(
                            mission: m,
                            onToggle: widget.onToggleMission,
                            onEdit: (id) => _showEditMissionDialog(m),
                            onDelete: widget.onDeleteMission,
                            onAddPhoto: widget.onAddPhoto,
                          )),
                        ],
                        if (_filteredMissions.any((m) => m.completed)) ...[
                          const SizedBox(height: 16),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 8.0, left: 4),
                              child: Text("완료", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                            ),
                          ),
                          ..._filteredMissions.where((m) => m.completed).map((m) => MissionCard(
                            mission: m,
                            onToggle: widget.onToggleMission,
                            onEdit: (id) => _showEditMissionDialog(m),
                            onDelete: widget.onDeleteMission,
                            onAddPhoto: widget.onAddPhoto,
                          )),
                        ]
                      ] else ...[
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 8.0, left: 4),
                            child: Text("완료한 미션", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                          ),
                        ),
                        ..._filteredMissions.map((m) => _buildHistoryMissionCard(m)),
                      ]
                    ],
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- 위젯 헬퍼들 (기존과 동일) ---
  Widget _buildHistoryMissionCard(Mission mission) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: mission.colorObj.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(mission.iconData, size: 20, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey,
                  ),
                ),
                if (mission.completedAt != null)
                  Text(
                    "${mission.completedAt!.hour}:${mission.completedAt!.minute.toString().padLeft(2, '0')}",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
              ],
            ),
          ),
          if (mission.photo != null)
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: mission.photo!.startsWith('http')
                      ? NetworkImage(mission.photo!) as ImageProvider
                      : FileImage(File(mission.photo!)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }

  Widget _buildCircleBtn(IconData icon, Color bg, Color contentColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: contentColor),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, String text) {
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }

  Widget _buildFilterTab(String id, String label) {
    final isSelected = _filterTab == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterTab = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orange : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayItem(DateTime date) {
    final now = DateTime.now();
    final isSelected = date.year == _selectedWeekDate.year &&
        date.month == _selectedWeekDate.month &&
        date.day == _selectedWeekDate.day;
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final dayName = ['월', '화', '수', '목', '금', '토', '일'][date.weekday - 1];

    final completion = (_getCompletionRate(date) * 100).toInt();
    final hasRecord = _getCompletedCount(date) > 0;

    return GestureDetector(
      onTap: () => setState(() => _selectedWeekDate = date),
      child: Column(
        children: [
          Text(dayName, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.orange
                  : (isToday ? Colors.orange.shade100 : Colors.transparent),
              shape: BoxShape.circle,
              border: hasRecord && !isSelected && !isToday
                  ? Border.all(color: Colors.green.shade300, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                "${date.day}",
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isToday ? Colors.orange.shade800 : Colors.grey.shade800),
                  fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hasRecord ? "$completion%" : "-",
            style: TextStyle(fontSize: 9, color: hasRecord ? Colors.grey.shade600 : Colors.grey.shade300),
          ),
        ],
      ),
    );
  }
}