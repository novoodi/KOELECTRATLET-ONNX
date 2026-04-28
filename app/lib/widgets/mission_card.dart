import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:b612_1/models/mission.dart';

class MissionCard extends StatelessWidget {
  final Mission mission;
  final Function(String) onToggle;
  final Function(String) onEdit;
  final Function(String) onDelete;
  final Function(String, String?) onAddPhoto;

  const MissionCard({
    super.key,
    required this.mission,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onAddPhoto,
  });

  // 색상 문자열(#RRGGBB)을 Color 객체로 변환
  Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) return Colors.white;
    try {
      final buffer = StringBuffer();
      if (colorStr.length == 6 || colorStr.length == 7) buffer.write('ff');
      buffer.write(colorStr.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.white;
    }
  }

  Future<void> _handlePhotoClick(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      onAddPhoto(mission.id, image.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasPhoto = mission.photo != null && mission.photo!.isNotEmpty;
    // Mission 모델에 time 필드가 있으면 사용, 없으면 null
    final String? timeStr = mission.time;

    return Dismissible(
      key: Key(mission.id),
      confirmDismiss: (direction) async {
        onToggle(mission.id);
        return false; // 삭제되지 않고 토글만 수행
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: Colors.green.withOpacity(0.2),
        child: const Icon(Icons.check, color: Colors.green),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.green.withOpacity(0.2),
        child: const Icon(Icons.check, color: Colors.green),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _parseColor(mission.color), // 배경색 적용
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onToggle(mission.id),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // 1. 아이콘 or 사진 영역
                  GestureDetector(
                    onTap: hasPhoto
                        ? () => _showPhotoDialog(context, mission.photo!)
                        : null,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasPhoto ? Colors.transparent : Colors.white.withOpacity(0.5),
                        // [수정] 이미지 소스 분기 처리 (URL vs 로컬 파일)
                        image: hasPhoto
                            ? DecorationImage(
                          image: mission.photo!.startsWith('http')
                              ? NetworkImage(mission.photo!) as ImageProvider
                              : FileImage(File(mission.photo!)),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: !hasPhoto
                          ? Center(
                        // mission.iconData 사용 (String -> IconData 변환)
                          child: Icon(mission.iconData,
                              color: Colors.black54, size: 24))
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // 2. 텍스트 영역
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mission.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: mission.completed
                                ? Colors.grey.shade400
                                : Colors.grey.shade800,
                            decoration: mission.completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (timeStr != null && timeStr.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time,
                                    size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  timeStr,
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // 3. 우측 액션 (체크박스 + 카메라 버튼)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // 완료 체크 아이콘
                      if (mission.completed)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.check,
                              size: 16, color: Colors.green.shade600),
                        ),

                      const SizedBox(height: 8),

                      // 사진 인증 버튼 (사진 없을 때만)
                      if (!hasPhoto && !mission.completed)
                        GestureDetector(
                          onTap: () => _handlePhotoClick(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.camera_alt, size: 12, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text("인증", style: TextStyle(fontSize: 10, color: Colors.grey.shade600))
                              ],
                            ),
                          ),
                        ),

                      // 메뉴 버튼 (사진이 있거나 미완료 상태일 때 옵션)
                      if (!mission.completed || hasPhoto)
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: _buildPopupMenu(context),
                        ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade400),
      onSelected: (value) {
        if (value == 'edit') onEdit(mission.id);
        if (value == 'delete') onDelete(mission.id);
        if (value == 'removePhoto') onAddPhoto(mission.id, null);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(value: 'edit', child: Text('수정')),
        if (mission.photo != null)
          const PopupMenuItem<String>(value: 'removePhoto', child: Text('사진 삭제')),
        const PopupMenuItem<String>(
            value: 'delete',
            child: Text('삭제', style: TextStyle(color: Colors.red))),
      ],
    );
  }

  void _showPhotoDialog(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              // [수정] 팝업 다이얼로그에서도 이미지 소스 분기 처리
              child: path.startsWith('http')
                  ? Image.network(path, fit: BoxFit.cover)
                  : Image.file(File(path), fit: BoxFit.cover),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}