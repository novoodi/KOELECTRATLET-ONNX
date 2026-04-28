import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:b612_1/models/browser_mission.dart';
import 'package:b612_1/utils/tag_colors.dart';

class MissionGridCard extends StatelessWidget {
  final BrowserMission mission;
  final bool isLiked;
  final int likeCount;
  final VoidCallback onTap;
  final VoidCallback onLike;

  const MissionGridCard({
    super.key,
    required this.mission,
    required this.isLiked,
    required this.likeCount,
    required this.onTap,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 176.0, // h-44
          decoration: BoxDecoration(
            gradient: getGradientForTag(mission.tag),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
          ),
          child: Stack(
            children: [
              // Background Icon
              Positioned(
                top: 16.0,
                right: 16.0,
                child: Icon(
                  mission.icon,
                  size: 40.0,
                  color: Colors.black.withOpacity(0.1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0), // 16->12로 줄임
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(mission.icon, size: 28.0, color: Colors.orange.shade600),
                        const SizedBox(height: 12.0),
                        Text(
                          mission.title,
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    // Bottom Section - 수정된 부분
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Like Button
                        Flexible( // Flexible 추가
                          child: InkWell(
                            onTap: onLike,
                            borderRadius: BorderRadius.circular(16.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              decoration: BoxDecoration(
                                color: isLiked ? Colors.red.shade50 : Colors.black.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min, // 추가
                                children: [
                                  Icon(
                                    isLiked ? Icons.favorite : LucideIcons.heart,
                                    size: 14.0, // 16->14로 줄임
                                    color: isLiked ? Colors.red.shade500 : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 4.0),
                                  Text(
                                    likeCount.toString(),
                                    style: TextStyle(
                                      fontSize: 12.0, // 14->12로 줄임
                                      color: isLiked ? Colors.red.shade500 : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0), // 간격 추가
                        // Tag
                        Flexible( // Flexible 추가
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            child: Text(
                              '#${mission.tag}',
                              style: TextStyle(fontSize: 12.0, color: Colors.grey.shade600),
                              overflow: TextOverflow.ellipsis, // 추가
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}