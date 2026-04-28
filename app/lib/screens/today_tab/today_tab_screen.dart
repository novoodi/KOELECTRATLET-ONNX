import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:b612_1/models/mission.dart';
import 'package:b612_1/widgets/planet_progress_indicator.dart';
import 'package:b612_1/services/database_service.dart';

class TodayTabScreen extends StatefulWidget {
  final List<Mission> missions;
  final Map<String, bool> attendanceData;
  final Function(String) onToggleMission;
  final VoidCallback onAddMission;
  final Function(String, String?) onAddPhoto;
  final Function(String) onDeleteMission;

  const TodayTabScreen({
    super.key,
    required this.missions,
    required this.attendanceData,
    required this.onToggleMission,
    required this.onAddMission,
    required this.onAddPhoto,
    required this.onDeleteMission,
  });

  @override
  State<TodayTabScreen> createState() => _TodayTabScreenState();
}

class _TodayTabScreenState extends State<TodayTabScreen> {
  Mission? _missionToDelete;
  final Set<String> _expandedMissions = <String>{};
  final Set<String> _showDeleteButtons = <String>{};
  final ImagePicker _picker = ImagePicker();
  String _currentDateFormatted = '';

  // ✅ 업로드 로딩 상태 추가
  String? _uploadingMissionId;

  @override
  void initState() {
    super.initState();
    _currentDateFormatted =
        DateFormat.yMMMMd('ko_KR').add_EEEE().format(DateTime.now());
  }

  // ✅ 사진 추가 (업로드 로딩 + Storage 업로드)
  Future<void> _onAddPhoto(String missionId) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() => _uploadingMissionId = missionId);

    try {
      // Firebase Storage에 업로드 시도
      final url = await DatabaseService().uploadImage(image.path);

      if (url != null) {
        widget.onAddPhoto(missionId, url);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('사진이 저장되었습니다!'),
              backgroundColor: Colors.green.shade400,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // 업로드 실패 시 로컬 경로라도 저장
        widget.onAddPhoto(missionId, image.path);
      }
    } catch (e) {
      // 에러 발생 시 로컬 경로 저장
      widget.onAddPhoto(missionId, image.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('업로드 실패: 로컬에 저장됨'),
            backgroundColor: Colors.orange.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploadingMissionId = null);
      }
    }
  }

  void _onRemovePhoto(String missionId) {
    widget.onAddPhoto(missionId, null);
  }

  void _showDeleteDialog(Mission mission) {
    setState(() => _missionToDelete = mission);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('미션을 삭제하시겠습니까?'),
        content:
        Text('"${_missionToDelete!.title}"을(를) 삭제합니다. 이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            child: const Text('취소'),
            onPressed: () {
              setState(() => _missionToDelete = null);
              Navigator.pop(context);
            },
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
            onPressed: () {
              if (_missionToDelete != null) {
                widget.onDeleteMission(_missionToDelete!.id);
              }
              setState(() => _missionToDelete = null);
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  void _toggleExpandMission(String id) {
    setState(() {
      _expandedMissions.contains(id)
          ? _expandedMissions.remove(id)
          : _expandedMissions.add(id);
    });
  }

  void _toggleDeleteMode(String id) {
    setState(() {
      _showDeleteButtons.clear();
      _showDeleteButtons.add(id);
    });
  }

  void _hideAllDeleteModes() {
    if (_showDeleteButtons.isNotEmpty) {
      setState(() => _showDeleteButtons.clear());
    }
  }

  // ✅ URL vs 로컬 파일 자동 구분
  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('http')) {
      return NetworkImage(path);
    } else {
      return FileImage(File(path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = widget.missions.where((m) => m.completed).length;
    final bool isCompleted =
        widget.missions.isNotEmpty && completedCount == widget.missions.length;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: widget.onAddMission,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.only(bottom: 80.0),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF7ED), Color(0xFFFFEFE9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: GestureDetector(
          onTap: _hideAllDeleteModes,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, completedCount, widget.missions.length),
                  Text(_currentDateFormatted,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      )),
                  const SizedBox(height: 24),
                  _buildAttendanceRow(context),
                  const SizedBox(height: 16),
                  if (isCompleted)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "🌟 행성이 완전히 채워졌습니다! 🌟",
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  _buildMissionList(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int completedCount, int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '오늘의 소확행',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        PlanetProgressIndicator(
          completedCount: completedCount,
          totalCount: total,
        )
      ],
    );
  }

  Widget _buildAttendanceRow(BuildContext context) {
    final today = DateTime.now();
    final List<Widget> dayWidgets = [];

    for (int i = -3; i <= 3; i++) {
      final date = today.add(Duration(days: i));
      final dateKey = date.toIso8601String().split('T')[0];
      final bool completed = widget.attendanceData[dateKey] ?? false;
      final bool isToday = i == 0;
      final bool isFutureDay = i > 0;

      String label = i == -1
          ? '어제'
          : i == 0
          ? '오늘'
          : i == 1
          ? '내일'
          : DateFormat.E('ko_KR').format(date);

      dayWidgets.add(
        _buildAttendanceDay(
          dayLabel: label,
          dateNum: date.day.toString(),
          completed: completed,
          isToday: isToday,
          isFutureDay: isFutureDay,
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: dayWidgets,
    );
  }

  Widget _buildAttendanceDay({
    required String dayLabel,
    required String dateNum,
    required bool completed,
    required bool isToday,
    required bool isFutureDay,
  }) {
    Color boxColor = Colors.grey.shade100;
    Color borderColor = Colors.grey.shade300;
    Color dayLabelColor = Colors.grey.shade500;
    Color dateNumColor = Colors.grey.shade400;

    if (completed) {
      boxColor = Colors.green.shade500;
      borderColor = Colors.green.shade500;
      dayLabelColor = Colors.grey.shade600;
    }

    if (isToday) {
      borderColor = Colors.orange;
      dayLabelColor = Colors.orange;
      dateNumColor = Colors.orange;
      boxColor = completed ? Colors.orange : Colors.orange.shade50;
    }

    if (isFutureDay) {
      boxColor = Colors.grey.shade50;
      borderColor = Colors.grey.shade200;
    }

    return Column(
      children: [
        Text(
          dayLabel,
          style: TextStyle(
            fontSize: 12,
            color: dayLabelColor,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: 2,
            ),
          ),
          child: completed
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : (isToday
              ? Center(
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange.withOpacity(0.5),
              ),
            ),
          )
              : null),
        ),
        const SizedBox(height: 6),
        Text(
          dateNum,
          style: TextStyle(
            fontSize: 12,
            color: dateNumColor,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        )
      ],
    );
  }

  Widget _buildMissionList(BuildContext context) {
    if (widget.missions.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.grey.shade200,
            width: 2,
          ),
        ),
        elevation: 0,
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.sentiment_satisfied_alt,
                    size: 40, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  '오늘의 첫 번째 소확행을\n추가해보세요!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children:
      widget.missions.map((m) => _buildMissionCard(context, m)).toList(),
    );
  }

  Widget _buildMissionCard(BuildContext context, Mission mission) {
    final bool isCompleted = mission.completed;
    final bool hasPhoto = mission.photo != null && mission.photo!.isNotEmpty;
    final bool isExpanded = _expandedMissions.contains(mission.id);
    final bool isDeleteMode = _showDeleteButtons.contains(mission.id);
    final bool isUploading = _uploadingMissionId == mission.id;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Dismissible(
        key: ValueKey(mission.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('미션을 삭제하시겠습니까?'),
              content:
              Text('"${mission.title}"을(를) 삭제합니다. 이 작업은 되돌릴 수 없습니다.'),
              actions: [
                TextButton(
                  child: const Text('취소'),
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('삭제'),
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                )
              ],
            ),
          );
        },
        onDismissed: (_) {
          widget.onDeleteMission(mission.id);
        },
        background: Container(
          decoration: BoxDecoration(
            color: Colors.red.shade500,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete, color: Colors.white),
              SizedBox(height: 4),
              Text('삭제', style: TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
        child: GestureDetector(
          onLongPress: () => _toggleDeleteMode(mission.id),
          onDoubleTap: () => _toggleExpandMission(mission.id),
          onTap: _hideAllDeleteModes,
          child: Card(
            elevation: isCompleted ? 1 : 4,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDeleteMode
                    ? Colors.red.shade200
                    : isExpanded
                    ? Colors.blue.shade200
                    : Colors.transparent,
                width: 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                // ✅ URL vs 로컬 파일 자동 구분
                image: (isCompleted && hasPhoto)
                    ? DecorationImage(
                  image: _getImageProvider(mission.photo!),
                  fit: BoxFit.cover,
                )
                    : null,
                color: (isCompleted && !hasPhoto)
                    ? Colors.grey.shade50
                    : Colors.white,
              ),
              child: Stack(
                children: [
                  if (isCompleted && hasPhoto)
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Container(
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: isCompleted,
                              onChanged: (_) =>
                                  widget.onToggleMission(mission.id),
                              activeColor: Colors.orange,
                              // ✅ deprecated MaterialStateProperty → WidgetStateProperty
                              fillColor:
                              WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return Colors.orange;
                                }
                                return hasPhoto
                                    ? Colors.white
                                    : Colors.grey.shade300;
                              }),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: (isCompleted && hasPhoto)
                                    ? Colors.white.withOpacity(0.85)
                                    : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(mission.iconData,
                                  size: 16, color: Colors.orange.shade700),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  mission.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    decoration: isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: isCompleted
                                        ? Colors.grey.shade600
                                        : Colors.grey.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                isDeleteMode
                                    ? Icons.delete_outline
                                    : Icons.more_horiz,
                                color: isDeleteMode
                                    ? Colors.red.shade600
                                    : Colors.grey.shade400,
                                size: 24,
                              ),
                              onPressed: () {
                                if (isDeleteMode) {
                                  _showDeleteDialog(mission);
                                } else {
                                  _toggleDeleteMode(mission.id);
                                }
                              },
                            ),
                          ],
                        ),
                        AnimatedCrossFade(
                          firstChild: const SizedBox.shrink(),
                          secondChild: _buildExpandedDescription(mission),
                          crossFadeState: isExpanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 250),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 12, left: 44),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (isCompleted && hasPhoto)
                                      ? Colors.white.withOpacity(0.85)
                                      : Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '#${mission.tag}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ),
                              // ✅ 업로드 로딩 표시
                              if (isUploading)
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.orange,
                                  ),
                                )
                              else if (isCompleted && !isDeleteMode)
                                hasPhoto
                                    ? _buildPhotoActionButton(
                                  icon: Icons.close,
                                  onPressed: () =>
                                      _onRemovePhoto(mission.id),
                                )
                                    : _buildPhotoActionButton(
                                  icon: Icons.add_a_photo_outlined,
                                  text: "사진 추가",
                                  onPressed: () =>
                                      _onAddPhoto(mission.id),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedDescription(Mission mission) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 44, right: 44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mission.description,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            "💡 다시 더블클릭하면 숨겨집니다",
            style: TextStyle(color: Colors.blue.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoActionButton({
    required IconData icon,
    String? text,
    required VoidCallback onPressed,
  }) {
    if (text != null) {
      return OutlinedButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(text, style: const TextStyle(fontSize: 12)),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey.shade600,
          backgroundColor: Colors.white.withOpacity(0.5),
          side: BorderSide(
            color: Colors.grey.shade400,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
    }

    return IconButton(
      icon: Icon(icon, size: 20),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.9),
        foregroundColor: Colors.grey.shade600,
      ),
    );
  }
}