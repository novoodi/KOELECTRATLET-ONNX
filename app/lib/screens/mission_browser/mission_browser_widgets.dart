import 'package:flutter/material.dart';
import 'package:b612_1/models/browser_mission.dart';

/// 미션 그리드 카드
class MissionGridCard extends StatelessWidget {
  final BrowserMission mission;
  final bool isAdded;
  final bool isLiked;
  final VoidCallback onAddTap;
  final VoidCallback onLikeTap;

  const MissionGridCard({
    super.key,
    required this.mission,
    required this.isAdded,
    required this.isLiked,
    required this.onAddTap,
    required this.onLikeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: mission.color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(mission.icon, size: 40, color: Colors.grey.shade700),
          const SizedBox(height: 12),
          Text(
            mission.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 좋아요 버튼
              GestureDetector(
                onTap: onLikeTap,
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                      size: 12,
                      color: isLiked ? Colors.orange : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${mission.likes}",
                      style: TextStyle(
                        fontSize: 12,
                        color: isLiked ? Colors.orange : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              // 추가 버튼
              GestureDetector(
                onTap: onAddTap,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: isAdded ? Colors.grey : Colors.green,
                  child: Icon(
                    isAdded ? Icons.check : Icons.add,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}

/// 미션 슬라이더 카드
class MissionSliderCard extends StatelessWidget {
  final BrowserMission mission;
  final bool isAdded;
  final bool isLiked;
  final VoidCallback onAddTap;
  final VoidCallback onLikeTap;

  const MissionSliderCard({
    super.key,
    required this.mission,
    required this.isAdded,
    required this.isLiked,
    required this.onAddTap,
    required this.onLikeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: mission.color.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(mission.icon, size: 48, color: Colors.grey.shade700),
          const SizedBox(height: 12),
          Text(
            mission.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            "by ${mission.author ?? '익명'}",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          // 좋아요 버튼
          GestureDetector(
            onTap: onLikeTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isLiked ? Colors.orange.shade100 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    size: 14,
                    color: isLiked ? Colors.orange : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${mission.likes}",
                    style: TextStyle(
                      color: isLiked ? Colors.orange : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 추가 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isAdded ? null : onAddTap,
              icon: Icon(isAdded ? Icons.check : Icons.add, size: 18),
              label: Text(
                isAdded ? '추가됨' : '내 미션에 추가',
                style: const TextStyle(fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isAdded ? Colors.grey : Colors.green,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade400,
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          )
        ],
      ),
    );
  }
}

/// 인기 미션 카드 (Featured)
class FeaturedMissionCard extends StatelessWidget {
  final BrowserMission mission;
  final bool isLiked;
  final VoidCallback onLikeTap;

  const FeaturedMissionCard({
    super.key,
    required this.mission,
    required this.isLiked,
    required this.onLikeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: mission.color.withOpacity(0.3),
            child: Icon(mission.icon, color: Colors.grey.shade700, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mission.title,
              style: const TextStyle(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onLikeTap,
            child: Row(
              children: [
                Icon(
                  isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  size: 14,
                  color: isLiked ? Colors.orange : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  "${mission.likes}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isLiked ? Colors.orange : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 뷰 모드 토글 버튼
class ViewModeButton extends StatelessWidget {
  final IconData icon;
  final String mode;
  final String currentMode;
  final ValueChanged<String> onModeChanged;

  const ViewModeButton({
    super.key,
    required this.icon,
    required this.mode,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentMode == mode;
    return GestureDetector(
      onTap: () => onModeChanged(mode),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.shade300 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? Colors.white : Colors.grey,
        ),
      ),
    );
  }
}

/// 슬라이더 네비게이션 버튼
class SliderNavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const SliderNavButton({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: enabled ? onTap : null,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.white.withOpacity(0.5),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: enabled ? Colors.orange : Colors.grey.shade400,
            size: 28,
          ),
        ),
      ),
    );
  }
}

/// 페이지 인디케이터
class PageIndicator extends StatelessWidget {
  final int itemCount;
  final int currentIndex;
  final int maxDisplay;

  const PageIndicator({
    super.key,
    required this.itemCount,
    required this.currentIndex,
    this.maxDisplay = 10,
  });

  @override
  Widget build(BuildContext context) {
    final displayCount = itemCount > maxDisplay ? maxDisplay : itemCount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          displayCount,
              (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == currentIndex ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: i == currentIndex ? Colors.orange : Colors.grey.shade300,
            ),
          ),
        ),
      ),
    );
  }
}

/// 인기 미션 섹션 헤더
class FeaturedSectionHeader extends StatelessWidget {
  const FeaturedSectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          backgroundColor: Colors.orange,
          radius: 14,
          child: Icon(Icons.favorite, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 8),
        const Text(
          "좋아요를 많이 받은 SHH",
          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}