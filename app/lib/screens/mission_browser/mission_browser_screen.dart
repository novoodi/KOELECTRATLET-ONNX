import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:b612_1/models/mission.dart';
import 'package:b612_1/models/browser_mission.dart';
import 'package:b612_1/services/database_service.dart';
import 'mission_browser_widgets.dart';
import 'mission_slider_view.dart';

class MissionBrowserScreen extends StatefulWidget {
  final Function(Mission, String?) onAddMission;
  final Set<String> addedMissionIds;

  const MissionBrowserScreen({
    super.key,
    required this.onAddMission,
    required this.addedMissionIds,
  });

  @override
  State<MissionBrowserScreen> createState() => _MissionBrowserScreenState();
}

class _MissionBrowserScreenState extends State<MissionBrowserScreen> {
  final TextEditingController _searchController = TextEditingController();

  // 상태 변수들
  String _sortBy = 'latest';
  String _viewMode = 'grid';
  Set<String> _likedMissions = {};
  String? _selectedFilterTag; // 선택된 태그 (예: 'coffee')
  String _searchQuery = '';

  final Map<String, String> _tagMap = {
    'coffee': '☕ 휴식',
    'leaf': '🌿 건강',
    'heart': '❤️ 마음',
    'book': '📚 자기계발',
    'sun': '☀️ 일상',
    'star': '⭐ 특별',
    'gym': '💪 운동',
  };

  late PageController _pageController;
  late Stream<QuerySnapshot> _missionsStream;

  @override
  void initState() {
    super.initState();
    _loadLikedMissions();
    _pageController = PageController(viewportFraction: 0.85);
    _missionsStream = DatabaseService().getPublicMissionsStream();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadLikedMissions() async {
    final prefs = await SharedPreferences.getInstance();
    final liked = prefs.getStringList('liked_missions') ?? [];
    setState(() {
      _likedMissions = liked.toSet();
    });
  }

  Future<void> _toggleLike(String missionId) async {
    try {
      final db = FirebaseFirestore.instance;
      final ref = db.collection('missions').doc(missionId);
      final isLiked = _likedMissions.contains(missionId);

      setState(() {
        if (isLiked) _likedMissions.remove(missionId);
        else _likedMissions.add(missionId);
      });

      if (isLiked) await ref.update({'likes': FieldValue.increment(-1)});
      else await ref.update({'likes': FieldValue.increment(1)});

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('liked_missions', _likedMissions.toList());
    } catch (e) {
      debugPrint("좋아요 에러: $e");
    }
  }

  void _handleAddClick(BrowserMission bm) {
    if (widget.addedMissionIds.contains(bm.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 추가된 미션입니다.')),
      );
      return;
    }

    final colorHex = '#${bm.color.value.toRadixString(16).substring(2).toUpperCase()}';

    final newMission = Mission(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: bm.title,
      description: bm.description,
      tag: bm.tag,
      icon: bm.tag,
      source: 'imported',
      color: colorHex,
    );

    widget.onAddMission(newMission, bm.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${bm.title}을(를) 추가했습니다!')),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('카테고리 필터'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tagMap.entries.map((entry) {
            final key = entry.key;
            final label = entry.value;

            return ChoiceChip(
              label: Text(label),
              selected: _selectedFilterTag == key,
              selectedColor: Colors.orange.shade200,
              onSelected: (selected) {
                setState(() {
                  _selectedFilterTag = selected ? key : null;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _selectedFilterTag = null);
              Navigator.pop(context);
            },
            child: const Text('초기화'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      body: StreamBuilder<QuerySnapshot>(
        stream: _missionsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }
          if (snapshot.hasError) return Center(child: Text('에러: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('아직 미션이 없습니다'));
          }

          // 1. 모델로 변환 (여기서 위에서 수정한 BrowserMission.fromFirestore가 호출됨)
          final allMissions = snapshot.data!.docs
              .map((doc) => BrowserMission.fromFirestore(doc))
              .toList();

          // 2. 필터링 로직
          var filteredMissions = allMissions.where((m) {
            final authorName = m.author ?? '';
            final matchQuery = m.title.contains(_searchQuery) ||
                authorName.contains(_searchQuery);

            final matchTag = _selectedFilterTag == null ||
                m.tag == _selectedFilterTag;

            return matchQuery && matchTag;
          }).toList();

          // 3. 정렬 로직
          if (_sortBy == 'likes') {
            filteredMissions.sort((a, b) => b.likes.compareTo(a.likes));
          } else {
            filteredMissions.sort((a, b) {
              final aTime = a.timestamp ?? DateTime(2000);
              final bTime = b.timestamp ?? DateTime(2000);
              return bTime.compareTo(aTime);
            });
          }

          // 뷰 모드에 따른 화면 반환
          if (_viewMode == 'slider') {
            return MissionSliderView(
              pageController: _pageController,
              allMissions: allMissions,
              filteredMissions: filteredMissions,
              addedMissionIds: widget.addedMissionIds,
              likedMissions: _likedMissions,
              sortBy: _sortBy,
              viewMode: _viewMode,
              selectedFilterTag: _selectedFilterTag,
              searchQuery: _searchQuery,
              searchController: _searchController,
              onAddMission: _handleAddClick,
              onToggleLike: _toggleLike,
              onSortChanged: (sort) => setState(() => _sortBy = sort),
              onViewModeChanged: (mode) => setState(() => _viewMode = mode),
              onSearchChanged: (query) => setState(() => _searchQuery = query),
              onRefresh: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedFilterTag = null;
                });
              },
              onFilterTap: _showFilterDialog,
            );
          }

          return CustomScrollView(
            slivers: [
              _buildSearchBar(),
              SliverToBoxAdapter(child: _buildFeaturedSection(allMissions)),
              _buildListHeader(),
              _buildGridList(filteredMissions),
              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: '소확행을 검색하세요',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: const Icon(Icons.close, color: Colors.grey, size: 20),
            )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: Colors.grey.shade600),
          onPressed: () {
            _searchController.clear();
            setState(() {
              _searchQuery = '';
              _selectedFilterTag = null;
            });
          },
        ),
        IconButton(
          icon: Icon(
            Icons.filter_list,
            color: _selectedFilterTag != null ? Colors.orange : Colors.grey.shade600,
          ),
          onPressed: _showFilterDialog,
        ),
      ],
    );
  }

  Widget _buildFeaturedSection(List<BrowserMission> allMissions) {
    if (allMissions.isEmpty) return const SizedBox.shrink();
    final topMissions = List<BrowserMission>.from(allMissions)
      ..sort((a, b) => b.likes.compareTo(a.likes));
    final featured = topMissions.take(2).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.orange.shade50, Colors.white],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FeaturedSectionHeader(),
          const SizedBox(height: 12),
          ...featured.map((m) => FeaturedMissionCard(
            mission: m,
            isLiked: _likedMissions.contains(m.id),
            onLikeTap: () => _toggleLike(m.id),
          )),
        ],
      ),
    );
  }

  Widget _buildListHeader() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                ViewModeButton(
                  icon: Icons.grid_view_rounded,
                  mode: 'grid',
                  currentMode: _viewMode,
                  onModeChanged: (mode) => setState(() => _viewMode = mode),
                ),
                const SizedBox(width: 8),
                ViewModeButton(
                  icon: Icons.view_carousel_rounded,
                  mode: 'slider',
                  currentMode: _viewMode,
                  onModeChanged: (mode) => setState(() => _viewMode = mode),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                setState(() => _sortBy = _sortBy == 'latest' ? 'likes' : 'latest');
              },
              child: Row(
                children: [
                  Icon(
                    _sortBy == 'latest' ? Icons.access_time : Icons.favorite,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _sortBy == 'latest' ? '최신순' : '좋아요순',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGridList(List<BrowserMission> missions) {
    if (missions.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Text('검색 결과가 없습니다', style: TextStyle(color: Colors.grey.shade500)),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final mission = missions[index];
            return MissionGridCard(
              mission: mission,
              isAdded: widget.addedMissionIds.contains(mission.id),
              isLiked: _likedMissions.contains(mission.id),
              onAddTap: () => _handleAddClick(mission),
              onLikeTap: () => _toggleLike(mission.id),
            );
          },
          childCount: missions.length,
        ),
      ),
    );
  }
}