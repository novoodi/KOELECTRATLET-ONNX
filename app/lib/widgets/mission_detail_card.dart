import 'package:flutter/material.dart';
// import 'package:lucide_flutter/lucide_flutter.dart'; // [수정] 삭제
import 'package:b612_1/models/browser_mission.dart';
import 'package:b612_1/utils/tag_colors.dart';

class MissionDetailCard extends StatelessWidget {
  final BrowserMission mission;
  final bool isLiked;
  final int likeCount;
  final VoidCallback onAdd;
  final VoidCallback onLike;

  const MissionDetailCard({
    super.key,
    required this.mission,
    required this.isLiked,
    required this.likeCount,
    required this.onAdd,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8.0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
      child: Container(
        height: 384.0,
        decoration: BoxDecoration(
          gradient: getGradientForTag(mission.tag),
        ),
        child: Stack(
          children: [
            // Mission Content
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        // BrowserMission에서 이미 IconData(Material)로 바꿨으므로 여기는 수정 불필요
                        child: Icon(mission.icon, size: 32.0, color: Colors.orange.shade600),
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        mission.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      if (mission.author != null) ...[
                        const SizedBox(height: 8.0),
                        Text(
                          'by ${mission.author}',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14.0, color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                  // Description
                  Text(
                    mission.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  // Tag and Like
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Text(
                          '#${mission.tag}',
                          style: TextStyle(fontSize: 14.0, color: Colors.grey.shade700),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: onLike,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLiked ? Colors.red.shade100 : Colors.white.withOpacity(0.6),
                          foregroundColor: isLiked ? Colors.red.shade600 : Colors.grey.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        ),
                        // [수정 1] LucideIcons.heart -> Icons.favorite / Icons.favorite_border
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 20.0, // Material 아이콘은 20~24 정도가 적당
                          color: isLiked ? Colors.red.shade600 : null,
                        ),
                        label: Text(likeCount.toString()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Add Mission Button (Top Right)
            Positioned(
              top: 16.0,
              right: 16.0,
              child: FloatingActionButton(
                onPressed: onAdd,
                mini: true,
                backgroundColor: Theme.of(context).primaryColor,
                // [수정 2] LucideIcons.plus -> Icons.add
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}