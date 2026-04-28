import 'package:flutter/material.dart';
import 'package:b612_1/models/browser_mission.dart';
import 'mission_browser_widgets.dart';

/// 슬라이더 모드 전용 뷰
class MissionSliderView extends StatefulWidget {
  // 부모로부터 컨트롤러를 받음
  final PageController pageController;

  final List<BrowserMission> allMissions;
  final List<BrowserMission> filteredMissions;
  final Set<String> addedMissionIds;
  final Set<String> likedMissions;
  final String sortBy;
  final String viewMode;
  final String? selectedFilterTag;
  final String searchQuery;
  final TextEditingController searchController;
  final Function(BrowserMission) onAddMission;
  final Function(String) onToggleLike;
  final Function(String) onSortChanged;
  final Function(String) onViewModeChanged;
  final Function(String) onSearchChanged;
  final VoidCallback onRefresh;
  final VoidCallback onFilterTap;

  const MissionSliderView({
    super.key,
    required this.pageController,
    required this.allMissions,
    required this.filteredMissions,
    required this.addedMissionIds,
    required this.likedMissions,
    required this.sortBy,
    required this.viewMode,
    required this.selectedFilterTag,
    required this.searchQuery,
    required this.searchController,
    required this.onAddMission,
    required this.onToggleLike,
    required this.onSortChanged,
    required this.onViewModeChanged,
    required this.onSearchChanged,
    required this.onRefresh,
    required this.onFilterTap,
  });

  @override
  State<MissionSliderView> createState() => _MissionSliderViewState();
}

class _MissionSliderViewState extends State<MissionSliderView> {
  int _currentSlideIndex = 0;

  @override
  void initState() {
    super.initState();
    // 화면이 다시 그려질 때 현재 페이지 위치를 컨트롤러에서 가져옴
    if (widget.pageController.hasClients) {
      _currentSlideIndex = widget.pageController.page?.round() ?? 0;
    }
  }

  // 자석 효과 함수
  void _snapToNearestPage() {
    if (!widget.pageController.hasClients) return;

    final double currentPosition = widget.pageController.page ?? 0.0;
    int targetPage = currentPosition.round();

    if (targetPage < 0) targetPage = 0;
    if (targetPage >= widget.filteredMissions.length) {
      targetPage = widget.filteredMissions.length - 1;
    }

    widget.pageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildFeaturedSection(),
                _buildListHeader(),
                _buildSlider(),
                PageIndicator(
                  itemCount: widget.filteredMissions.length,
                  currentIndex: _currentSlideIndex,
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider() {
    if (widget.filteredMissions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            '검색 결과가 없습니다',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ),
      );
    }

    return SizedBox(
      height: 320,
      child: Stack(
        children: [
          // Listener를 사용하여 드래그 끊김 현상 방지
          Listener(
            onPointerMove: (details) {
              if (widget.pageController.hasClients) {
                widget.pageController
                    .jumpTo(widget.pageController.offset - details.delta.dx);
              }
            },
            onPointerUp: (_) => _snapToNearestPage(),
            onPointerCancel: (_) => _snapToNearestPage(),
            child: PageView.builder(
              controller: widget.pageController,
              itemCount: widget.filteredMissions.length,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (idx) => setState(() => _currentSlideIndex = idx),
              itemBuilder: (context, index) {
                final mission = widget.filteredMissions[index];
                return Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: MissionSliderCard(
                    mission: mission,
                    isAdded: widget.addedMissionIds.contains(mission.id),
                    isLiked: widget.likedMissions.contains(mission.id),
                    onAddTap: () => widget.onAddMission(mission),
                    onLikeTap: () => widget.onToggleLike(mission.id),
                  ),
                );
              },
            ),
          ),
          // 왼쪽 버튼
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: SliderNavButton(
                icon: Icons.chevron_left,
                enabled: _currentSlideIndex > 0,
                onTap: () => widget.pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
              ),
            ),
          ),
          // 오른쪽 버튼
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: SliderNavButton(
                icon: Icons.chevron_right,
                enabled: _currentSlideIndex < widget.filteredMissions.length - 1,
                onTap: () => widget.pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: widget.searchController,
                  onChanged: widget.onSearchChanged,
                  decoration: InputDecoration(
                    hintText: '소확행을 검색하세요',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    // ✅ X 버튼 추가
                    suffixIcon: widget.searchQuery.isNotEmpty
                        ? GestureDetector(
                      onTap: widget.onRefresh,
                      child: const Icon(Icons.close,
                          color: Colors.grey, size: 20),
                    )
                        : null,
                    border: InputBorder.none,
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.grey.shade600),
              onPressed: widget.onRefresh,
            ),
            IconButton(
              icon: Icon(
                Icons.filter_list,
                color: widget.selectedFilterTag != null
                    ? Colors.orange
                    : Colors.grey.shade600,
              ),
              onPressed: widget.onFilterTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedSection() {
    if (widget.allMissions.isEmpty) return const SizedBox.shrink();

    final topMissions = List<BrowserMission>.from(widget.allMissions)
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
            isLiked: widget.likedMissions.contains(m.id),
            onLikeTap: () => widget.onToggleLike(m.id),
          )),
        ],
      ),
    );
  }

  Widget _buildListHeader() {
    return Container(
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
                currentMode: widget.viewMode,
                onModeChanged: widget.onViewModeChanged,
              ),
              const SizedBox(width: 8),
              ViewModeButton(
                icon: Icons.view_carousel_rounded,
                mode: 'slider',
                currentMode: widget.viewMode,
                onModeChanged: widget.onViewModeChanged,
              ),
            ],
          ),
          TextButton(
            onPressed: () => widget
                .onSortChanged(widget.sortBy == 'latest' ? 'likes' : 'latest'),
            child: Row(
              children: [
                Icon(
                  widget.sortBy == 'latest' ? Icons.access_time : Icons.favorite,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.sortBy == 'latest' ? '최신순' : '좋아요순',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}