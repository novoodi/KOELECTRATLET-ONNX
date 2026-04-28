import 'dart:io';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:b612_1/app_shell.dart';
import 'package:b612_1/models/mission.dart';

class HistoryTabScreen extends StatefulWidget {
  final Map<String, bool> attendanceData;
  final List<Mission> missionHistory;
  final VoidCallback onOpenProfile;
  final UserProfile userProfile;

  const HistoryTabScreen({
    super.key,
    required this.attendanceData,
    required this.missionHistory,
    required this.onOpenProfile,
    required this.userProfile,
  });

  @override
  State<HistoryTabScreen> createState() => _HistoryTabScreenState();
}

class _HistoryTabScreenState extends State<HistoryTabScreen> {
  String _selectedCategory = 'planet';
  Color _planetColor = const Color(0xFFFF8C42);
  DateTime _selectedDate = DateTime.now();

  // 갤러리 필터 상태
  bool _isSearchOpen = false;
  String _searchQuery = "";
  String? _selectedMonthFilter;
  List<String> _selectedTagFilters = [];

  final List<IconData> _availableIcons = [
    Icons.wb_sunny_rounded, Icons.coffee_rounded, Icons.directions_walk_rounded,
    Icons.wb_twilight_rounded, Icons.music_note_rounded, Icons.menu_book_rounded,
    Icons.cake_rounded, Icons.self_improvement_rounded, Icons.spa_rounded,
    Icons.landscape_rounded, Icons.pedal_bike_rounded, Icons.waves_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _loadPlanetColor();
  }

  // ✅ 저장된 행성 색상 불러오기
  Future<void> _loadPlanetColor() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt('planet_color');
    if (colorValue != null) {
      setState(() {
        _planetColor = Color(colorValue);
      });
    }
  }

  // ✅ 행성 색상 저장
  Future<void> _savePlanetColor(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('planet_color', color.value);
  }

  // ✅ 실제 미션 데이터에서 갤러리용 사진 목록 생성
  List<Map<String, dynamic>> get _galleryPhotos {
    return widget.missionHistory
        .where((m) => m.photo != null && m.photo!.isNotEmpty && m.completedAt != null)
        .map((m) {
      final date = m.completedAt!;
      return {
        'id': m.id,
        'title': m.title,
        'date': DateFormat('yyyy-MM-dd').format(date),
        'month': '${date.month}월',
        'icon': m.iconData,
        'tag': m.tag,
        'image': m.photo!,
        'color': m.colorObj.withOpacity(0.3),
      };
    }).toList();
  }

  // ✅ 실제 데이터 기반 통계 계산
  Map<String, dynamic> get _stats {
    final total = widget.missionHistory.length;
    final now = DateTime.now();

    // 이번 달 완료 미션
    final thisMonth = widget.missionHistory.where((m) {
      if (m.completedAt == null) return false;
      final d = m.completedAt!;
      return d.year == now.year && d.month == now.month;
    }).length;

    // 내가 만든 미션 개수
    final myMissionsCount = widget.missionHistory
        .where((m) => m.source == 'mine')
        .length;

    // 가장 많이 사용한 아이콘 계산
    final iconCounts = <String, int>{};
    for (var m in widget.missionHistory) {
      iconCounts[m.icon] = (iconCounts[m.icon] ?? 0) + 1;
    }
    String mostUsedIcon = '☀️';
    String mostUsedIconName = '없음';
    if (iconCounts.isNotEmpty) {
      final topIcon = iconCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      mostUsedIcon = _getEmojiForIcon(topIcon);
      mostUsedIconName = _getNameForIcon(topIcon);
    }

    // 가장 많이 사용한 태그
    final tagCounts = <String, int>{};
    for (var m in widget.missionHistory) {
      tagCounts[m.tag] = (tagCounts[m.tag] ?? 0) + 1;
    }
    String mostFrequentMood = '없음';
    if (tagCounts.isNotEmpty) {
      mostFrequentMood = tagCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    return {
      'mostUsedIcon': mostUsedIcon,
      'mostUsedIconName': mostUsedIconName,
      'mostFrequentMood': mostFrequentMood,
      'myMissionsCount': myMissionsCount,
      'totalMissionsCompleted': total,
      'thisMonthCompleted': thisMonth,
    };
  }

  String _getEmojiForIcon(String icon) {
    switch (icon) {
      case 'sun': return '☀️';
      case 'coffee': return '☕';
      case 'book': return '📚';
      case 'heart': return '❤️';
      case 'leaf': return '🌿';
      case 'star': return '⭐';
      default: return '✨';
    }
  }

  String _getNameForIcon(String icon) {
    switch (icon) {
      case 'sun': return '아침';
      case 'coffee': return '커피';
      case 'book': return '독서';
      case 'heart': return '힐링';
      case 'leaf': return '자연';
      case 'star': return '특별';
      default: return '기타';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. 상단 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userProfile.bio,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      GestureDetector(
                        onTap: widget.onOpenProfile,
                        child: const Text(
                          "성향 테스트 결과 보기 >",
                          style: TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                      )
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: widget.onOpenProfile,
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. 카테고리 탭
            _buildCategoryTabs(),
            const SizedBox(height: 16),

            // 3. 컨텐츠 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildContent(),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Column(
      children: [
        Row(
          children: [
            _buildTabItem('planet', '내 행성'),
            _buildTabItem('calendar', '달력'),
            _buildTabItem('gallery', '갤러리'),
          ],
        ),
        Stack(
          children: [
            Container(height: 2, color: Colors.grey.shade200),
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              alignment: _selectedCategory == 'planet'
                  ? Alignment.centerLeft
                  : (_selectedCategory == 'calendar' ? Alignment.center : Alignment.centerRight),
              child: Container(
                width: MediaQuery.of(context).size.width / 3,
                height: 2,
                color: Colors.orange,
              ),
            )
          ],
        )
      ],
    );
  }

  Widget _buildTabItem(String id, String label) {
    final isSelected = _selectedCategory == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedCategory = id),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.black : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedCategory) {
      case 'planet':
        return _buildPlanetView();
      case 'calendar':
        return _buildCalendarView();
      case 'gallery':
        return _buildGalleryView();
      default:
        return Container();
    }
  }

  // ==========================================
  // [1] 내 행성 뷰
  // ==========================================
  Widget _buildPlanetView() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '이번달 아이콘',
                _stats['mostUsedIcon'],
                sub: _stats['mostUsedIconName'],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard('나의 기분', _stats['mostFrequentMood']),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'MY 소확행',
                "${_stats['myMissionsCount']}개",
                highlight: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _showTotalHistoryList,
                child: _buildStatCard(
                  '전체 완료',
                  "${_stats['totalMissionsCompleted']}개",
                  highlight: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 행성 표시
        Container(
          width: double.infinity,
          height: 360,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.palette_outlined),
                  onPressed: _showColorPicker,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_planetColor, _planetColor.withOpacity(0.6)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _planetColor.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${_stats['thisMonthCompleted']}",
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "${DateTime.now().month}월 달성",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "총 완료한 미션",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildStatCard(String title, String value, {String? sub, bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
        ],
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),
          if (sub != null) ...[
            Text(value, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ] else ...[
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: highlight ? Colors.orange : Colors.black87,
              ),
            ),
          ]
        ],
      ),
    );
  }

  // ==========================================
  // [2] 달력 뷰
  // ==========================================
  Widget _buildCalendarView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar(
        locale: 'ko_KR',
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _selectedDate,
        selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDate = selectedDay;
          });
          _showDayDetailModal(selectedDay);
        },
        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          leftChevronIcon: Icon(Icons.chevron_left, color: Colors.grey),
          rightChevronIcon: Icon(Icons.chevron_right, color: Colors.grey),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Colors.orange.shade100,
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
          selectedDecoration: const BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          markerDecoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            if (events.isNotEmpty) {
              return Positioned(
                bottom: 1,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }
            return null;
          },
        ),
        eventLoader: (day) {
          final count = widget.missionHistory.where((m) {
            if (m.completedAt == null) return false;
            return isSameDay(m.completedAt!, day);
          }).length;

          String key = day.toIso8601String().split('T')[0];
          if (count > 0 || widget.attendanceData[key] == true) {
            return ['mission'];
          }
          return [];
        },
      ),
    );
  }

  // ==========================================
  // [3] 갤러리 뷰 (실제 미션 데이터 연결)
  // ==========================================
  Widget _buildGalleryView() {
    final photos = _galleryPhotos;

    // 1. 필터링 로직
    List<Map<String, dynamic>> filteredPhotos = photos.where((photo) {
      if (_searchQuery.isNotEmpty &&
          !photo['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_selectedTagFilters.isNotEmpty && !_selectedTagFilters.contains(photo['tag'])) {
        return false;
      }
      if (_selectedMonthFilter != null && photo['month'] != _selectedMonthFilter) {
        return false;
      }
      return true;
    }).toList();

    // 2. 월별 그룹화
    Map<String, List<Map<String, dynamic>>> groupedData = {};
    for (var photo in filteredPhotos) {
      String month = photo['month'];
      groupedData.putIfAbsent(month, () => []).add(photo);
    }

    // 월 정렬 (최신순)
    final sortedMonths = groupedData.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 갤러리 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _isSearchOpen
                    ? TextField(
                  autofocus: true,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: "미션 제목 검색...",
                    border: InputBorder.none,
                    hintStyle: const TextStyle(fontSize: 14),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => setState(() {
                        _isSearchOpen = false;
                        _searchQuery = "";
                      }),
                    ),
                  ),
                )
                    : Row(
                  children: [
                    const Text(
                      "사진 인증",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${photos.length}장",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isSearchOpen)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.search, size: 24, color: Colors.black54),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => _isSearchOpen = true),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(
                        Icons.calendar_today_outlined,
                        size: 22,
                        color: _selectedMonthFilter != null ? Colors.orange : Colors.black54,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _showMonthFilterDialog,
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(
                        Icons.filter_list,
                        size: 24,
                        color: _selectedTagFilters.isNotEmpty ? Colors.orange : Colors.black54,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _showTagFilterDialog,
                    ),
                  ],
                )
            ],
          ),
          const SizedBox(height: 24),

          // 갤러리 리스트
          if (photos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      "아직 인증 사진이 없어요",
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "미션 완료 시 사진을 추가해보세요!",
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else if (filteredPhotos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  "조건에 맞는 사진이 없습니다.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...sortedMonths.map((month) {
              final monthPhotos = groupedData[month]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        month,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${monthPhotos.length}장",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1,
                    ),
                    itemCount: monthPhotos.length,
                    itemBuilder: (context, index) {
                      final photo = monthPhotos[index];
                      String dayStr = photo['date'].toString().split('-').last + "일";

                      return GestureDetector(
                        onTap: () => _showPhotoDetailDialog(photo),
                        child: Container(
                          decoration: BoxDecoration(
                            color: photo['color'],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // ✅ URL vs 로컬 파일 자동 구분
                                _buildPhotoImage(photo['image']),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  height: 40,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.vertical(
                                        bottom: Radius.circular(16),
                                      ),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.5),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Text(
                                      dayStr,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              );
            }),
        ],
      ),
    );
  }

  // ✅ URL/로컬 파일 자동 구분 이미지 위젯
  Widget _buildPhotoImage(String imagePath) {
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey.shade100,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    } else {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          );
        },
      );
    }
  }

  // ==========================================
  // [모달] 팝업 다이얼로그 함수들
  // ==========================================

  void _showPhotoDetailDialog(Map<String, dynamic> photo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: photo['image'].toString().startsWith('http')
                        ? Image.network(
                      photo['image'],
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                    )
                        : Image.file(
                      File(photo['image']),
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(photo['icon'], color: Colors.orange, size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                photo['title'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          photo['date'],
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMonthFilterDialog() {
    final months = _galleryPhotos.map((e) => e['month'] as String).toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "월 선택",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 16),
              if (months.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("사진이 없습니다", style: TextStyle(color: Colors.grey)),
                )
              else
                ...months.map((month) => InkWell(
                  onTap: () {
                    setState(() => _selectedMonthFilter = month);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: _selectedMonthFilter == month
                          ? Colors.orange.shade50
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      month,
                      style: TextStyle(
                        color: _selectedMonthFilter == month ? Colors.orange : Colors.black87,
                        fontWeight: _selectedMonthFilter == month
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                )),
              if (_selectedMonthFilter != null)
                TextButton(
                  onPressed: () {
                    setState(() => _selectedMonthFilter = null);
                    Navigator.pop(context);
                  },
                  child: const Text("필터 해제", style: TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTagFilterDialog() {
    List<String> tempSelected = List.from(_selectedTagFilters);
    final availableTags = ['sun', 'coffee', 'book', 'heart', 'leaf', 'star'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "태그 필터",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: availableTags.map((tag) {
                      final isSelected = tempSelected.contains(tag);
                      return GestureDetector(
                        onTap: () => setStateDialog(() {
                          isSelected ? tempSelected.remove(tag) : tempSelected.add(tag);
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.orange.shade50 : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: isSelected ? Border.all(color: Colors.orange) : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_getEmojiForIcon(tag)),
                              const SizedBox(width: 6),
                              Text(
                                _getNameForIcon(tag),
                                style: TextStyle(
                                  color: isSelected ? Colors.orange : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => setStateDialog(() => tempSelected.clear()),
                        child: const Text("초기화", style: TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _selectedTagFilters = tempSelected);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("적용"),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ✅ 오버플로우 수정: DraggableScrollableSheet + ListView 사용
  void _showDayDetailModal(DateTime date) {
    final dayMissions = widget.missionHistory.where((m) {
      if (m.completedAt == null) return false;
      return isSameDay(m.completedAt!, date);
    }).toList();

    final dateStr = DateFormat('M월 d일 EEEE', 'ko_KR').format(date);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // ✅ 스크롤 가능하도록 설정
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5, // ✅ 초기 높이 50%
        maxChildSize: 0.85, // ✅ 최대 높이 85%
        minChildSize: 0.3, // ✅ 최소 높이 30%
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ 드래그 핸들
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                dateStr,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                dayMissions.isEmpty
                    ? "완료한 미션이 없어요"
                    : "${dayMissions.length}개의 미션 완료",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),

              // ✅ Expanded + ListView로 스크롤 가능하게
              Expanded(
                child: dayMissions.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        "이 날 완료한 미션이 없어요.",
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  controller: scrollController,
                  itemCount: dayMissions.length,
                  itemBuilder: (context, index) {
                    final mission = dayMissions[index];
                    final timeStr = mission.completedAt != null
                        ? DateFormat('a h:mm', 'ko_KR')
                        .format(mission.completedAt!)
                        : '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: mission.colorObj.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              mission.iconData,
                              color: Colors.grey.shade700,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mission.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (timeStr.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      timeStr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (mission.photo != null)
                            Container(
                              width: 40,
                              height: 40,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: mission.photo!.startsWith('http')
                                      ? NetworkImage(mission.photo!)
                                  as ImageProvider
                                      : FileImage(File(mission.photo!)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTotalHistoryList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "전체 완료한 미션",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "${widget.missionHistory.length}개",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (widget.missionHistory.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text("아직 기록이 없어요."),
                  ),
                ),

              ...widget.missionHistory.reversed.map((mission) {
                final dateStr = mission.completedAt != null
                    ? DateFormat('yyyy.MM.dd a h:mm', 'ko_KR').format(mission.completedAt!)
                    : '';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: mission.colorObj.withOpacity(0.3),
                    child: Icon(mission.iconData, color: Colors.orange),
                  ),
                  title: Text(
                    mission.title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(dateStr),
                  trailing: mission.photo != null
                      ? Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: mission.photo!.startsWith('http')
                            ? NetworkImage(mission.photo!) as ImageProvider
                            : FileImage(File(mission.photo!)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                      : const Icon(Icons.check_circle, color: Colors.green),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ 색상 선택 (저장 기능 추가)
  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("행성 색상 변경"),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            Colors.orange,
            Colors.blue,
            Colors.green,
            Colors.purple,
            Colors.pink,
            Colors.teal,
            Colors.amber,
            Colors.indigo,
          ].map((c) => GestureDetector(
            onTap: () {
              setState(() => _planetColor = c);
              _savePlanetColor(c);
              Navigator.pop(context);
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: _planetColor == c
                    ? Border.all(color: Colors.black, width: 3)
                    : null,
              ),
            ),
          )).toList(),
        ),
      ),
    );
  }
}