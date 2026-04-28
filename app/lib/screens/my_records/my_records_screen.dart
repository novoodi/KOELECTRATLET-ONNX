import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:b612_1/models/mission.dart';
import 'package:b612_1/services/database_service.dart';

class MyRecordsScreen extends StatefulWidget {
  final List<Mission> missions;
  final Function(String, String?) onAddPhoto;
  final VoidCallback onBack;

  const MyRecordsScreen({
    super.key,
    required this.missions,
    required this.onAddPhoto,
    required this.onBack,
  });

  @override
  State<MyRecordsScreen> createState() => _MyRecordsScreenState();
}

class _MyRecordsScreenState extends State<MyRecordsScreen> {
  DateTime? _selectedDate; // ✅ DateTime 타입으로 변경
  bool _isUploading = false; // ✅ 업로드 로딩 상태
  String? _uploadingMissionId; // 어떤 미션이 업로드 중인지

  // ✅ 날짜별로 완료된 미션 그룹화 (DateTime 키 사용)
  Map<DateTime, List<Mission>> get _groupedMissions {
    final completed = widget.missions
        .where((m) => m.completed && m.completedAt != null)
        .toList();
    final Map<DateTime, List<Mission>> group = {};

    for (var m in completed) {
      // 시간 제거하고 날짜만 키로 사용
      final dateKey = DateTime(
        m.completedAt!.year,
        m.completedAt!.month,
        m.completedAt!.day,
      );

      group.putIfAbsent(dateKey, () => []).add(m);
    }
    return group;
  }

  // ✅ 날짜 정렬 (DateTime 기반 - 정확한 최신순)
  List<DateTime> get _sortedDates {
    final dates = _groupedMissions.keys.toList();
    dates.sort((a, b) => b.compareTo(a)); // 최신순
    return dates;
  }

  // 날짜 포맷 헬퍼
  String _formatDate(DateTime date) {
    return DateFormat('yyyy년 M월 d일').format(date);
  }

  String _formatDateShort(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) return '오늘';
    if (date == yesterday) return '어제';
    return DateFormat('M월 d일').format(date);
  }

  // ✅ 사진 선택 및 업로드
  Future<void> _pickAndUploadPhoto(String missionId) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() {
      _isUploading = true;
      _uploadingMissionId = missionId;
    });

    try {
      // Firebase Storage에 업로드
      final url = await DatabaseService().uploadImage(image.path);

      if (url != null) {
        widget.onAddPhoto(missionId, url);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('사진이 저장되었습니다!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('사진 업로드에 실패했습니다')),
          );
        }
      }
    } catch (e) {
      print("사진 업로드 에러: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
        _uploadingMissionId = null;
      });
    }
  }

  // ✅ 사진 삭제 (Storage 파일도 함께 삭제)
  Future<void> _deletePhoto(String missionId, String? photoUrl) async {
    // 확인 다이얼로그
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사진 삭제'),
        content: const Text('이 사진을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isUploading = true;
      _uploadingMissionId = missionId;
    });

    try {
      // Storage에서 파일 삭제 (URL인 경우에만)
      if (photoUrl != null && photoUrl.startsWith('http')) {
        try {
          await FirebaseStorage.instance.refFromURL(photoUrl).delete();
          print("✅ Storage 파일 삭제 완료");
        } catch (e) {
          print("Storage 삭제 실패 (이미 삭제되었거나 권한 없음): $e");
        }
      }

      // DB에서 참조 제거
      widget.onAddPhoto(missionId, null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진이 삭제되었습니다')),
        );
      }
    } catch (e) {
      print("사진 삭제 에러: $e");
    } finally {
      setState(() {
        _isUploading = false;
        _uploadingMissionId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 오버레이
    return Stack(
      children: [
        if (_selectedDate == null)
          _buildDateListView()
        else
          _buildDetailView(),

        // ✅ 업로드 로딩 오버레이
        if (_isUploading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    '처리 중...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // 1. 날짜 목록 뷰
  Widget _buildDateListView() {
    final dates = _sortedDates;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF7ED), Color(0xFFFFEFE9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: widget.onBack,
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "나의 기록",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "완료한 미션들을 날짜별로 확인해보세요",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    if (dates.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        "총 ${widget.missions.where((m) => m.completed).length}개의 미션 완료!",
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 리스트
              Expanded(
                child: dates.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  itemCount: dates.length,
                  itemBuilder: (context, index) {
                    final date = dates[index];
                    final missions = _groupedMissions[date]!;
                    final photoCount =
                        missions.where((m) => m.photo != null).length;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedDate = date),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: const Border(
                            left: BorderSide(color: Colors.orange, width: 4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        _formatDate(date),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius:
                                          BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          _formatDateShort(date),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.orange.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        "완료한 미션 ${missions.length}개",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      if (photoCount > 0) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          "📷 $photoCount개",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ]
                                    ],
                                  )
                                ],
                              ),
                            ),
                            // 아이콘 미리보기 (Stack)
                            SizedBox(
                              width: 80,
                              height: 32,
                              child: Stack(
                                children: List.generate(
                                  missions.length > 3 ? 3 : missions.length,
                                      (i) => Positioned(
                                    right: i * 20.0,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        missions[i].iconData,
                                        size: 16,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // 2. 상세 보기
  Widget _buildDetailView() {
    final missions = _groupedMissions[_selectedDate] ?? [];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF7ED), Color(0xFFFFEFE9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => setState(() => _selectedDate = null),
                          icon: const Icon(Icons.arrow_back),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _formatDate(_selectedDate!),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 36, top: 4),
                      child: Text(
                        "이날 완료한 미션 ${missions.length}개",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: missions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final m = missions[index];
                    return _buildMissionCard(m);
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ✅ 미션 카드 (URL/로컬 경로 자동 구분)
  Widget _buildMissionCard(Mission m) {
    final hasPhoto = m.photo != null && m.photo!.isNotEmpty;
    final isUploading = _uploadingMissionId == m.id;

    // ✅ 이미지 프로바이더 결정 (URL vs 로컬 파일)
    ImageProvider? imageProvider;
    if (hasPhoto) {
      if (m.photo!.startsWith('http')) {
        imageProvider = NetworkImage(m.photo!);
      } else if (File(m.photo!).existsSync()) {
        imageProvider = FileImage(File(m.photo!));
      }
    }

    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: Colors.grey, width: 4),
        ),
        image: imageProvider != null
            ? DecorationImage(
          image: imageProvider,
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.4),
            BlendMode.darken,
          ),
        )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // 상태 아이콘
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange,
              ),
              child: const Icon(Icons.check, size: 12, color: Colors.white),
            ),
            const SizedBox(width: 12),

            // 텍스트 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: hasPhoto
                              ? Colors.white.withOpacity(0.8)
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          m.iconData,
                          size: 16,
                          color: Colors.orange.shade800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          m.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: hasPhoto ? Colors.white : Colors.black87,
                            decoration: TextDecoration.lineThrough,
                            decorationColor:
                            hasPhoto ? Colors.white : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    m.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: hasPhoto ? Colors.white70 : Colors.grey,
                    ),
                  ),
                  if (m.completedAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('HH:mm').format(m.completedAt!),
                      style: TextStyle(
                        fontSize: 10,
                        color: hasPhoto ? Colors.white54 : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 사진 추가/삭제 버튼
            if (isUploading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.orange,
                ),
              )
            else if (hasPhoto)
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: hasPhoto ? Colors.white : Colors.grey,
                ),
                onPressed: () => _deletePhoto(m.id, m.photo),
              )
            else
              OutlinedButton.icon(
                onPressed: () => _pickAndUploadPhoto(m.id),
                icon: const Icon(Icons.camera_alt, size: 14),
                label: const Text("사진", style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  side: const BorderSide(color: Colors.grey),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            "아직 완료한 미션이 없습니다",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            "오늘부터 소확행을 시작해보세요!",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: widget.onBack,
            icon: const Icon(Icons.home),
            label: const Text("홈으로 돌아가기"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}