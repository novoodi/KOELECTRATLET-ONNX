import 'package:flutter/material.dart';
import 'package:b612_1/models/custom_tag.dart'; // CustomTag 모델 필요 (없으면 아래 코드 내 클래스 사용)

// 만약 models 폴더에 CustomTag가 없다면 아래 주석을 풀어 사용하세요.
/*
class CustomTag {
  final String id;
  final String label;
  final IconData icon;
  CustomTag({required this.id, required this.label, required this.icon});
}
*/

// 간단한 데이터 전송용 클래스
class NewMissionData {
  final String title;
  final String description;
  final String tagId;
  final bool isPublic;

  NewMissionData(this.title, this.description, this.tagId, this.isPublic);
}

class AddMissionModal extends StatefulWidget {
  final Function(NewMissionData) onAddMission;
  final List<CustomTag> customTags;
  final Function(CustomTag) onAddCustomTag;

  const AddMissionModal({
    super.key,
    required this.onAddMission,
    required this.customTags,
    required this.onAddCustomTag,
  });

  @override
  State<AddMissionModal> createState() => _AddMissionModalState();
}

class _AddMissionModalState extends State<AddMissionModal> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _customTagController = TextEditingController();

  String _selectedTagId = 'wellness';
  bool _isPublic = false;

  // 커스텀 태그 관련 상태
  bool _showCustomTagForm = false;
  String _selectedCustomIconId = 'heart';

  // 기본 태그 옵션
  final List<Map<String, dynamic>> _defaultTags = [
    {'id': 'wellness', 'label': '웰빙', 'icon': Icons.wb_sunny_rounded},
    {'id': 'daily', 'label': '일상', 'icon': Icons.coffee_rounded},
    {'id': 'growth', 'label': '성장', 'icon': Icons.menu_book_rounded},
    {'id': 'happiness', 'label': '행복', 'icon': Icons.sentiment_satisfied_alt_rounded},
    {'id': 'love', 'label': '사랑', 'icon': Icons.favorite_rounded},
    {'id': 'goal', 'label': '목표', 'icon': Icons.track_changes_rounded},
    {'id': 'energy', 'label': '에너지', 'icon': Icons.bolt_rounded},
    {'id': 'achievement', 'label': '성취', 'icon': Icons.star_rounded},
    {'id': 'nature', 'label': '자연', 'icon': Icons.forest_rounded},
  ];

  // 커스텀 아이콘 옵션
  final List<Map<String, dynamic>> _customIconOptions = [
    {'id': 'heart', 'icon': Icons.favorite_rounded},
    {'id': 'star', 'icon': Icons.star_rounded},
    {'id': 'target', 'icon': Icons.track_changes_rounded},
    {'id': 'zap', 'icon': Icons.bolt_rounded},
    {'id': 'tree', 'icon': Icons.forest_rounded},
  ];

  void _handleAddCustomTag() {
    if (_customTagController.text.trim().isEmpty) return;

    final selectedIconData = _customIconOptions.firstWhere(
          (opt) => opt['id'] == _selectedCustomIconId,
      orElse: () => _customIconOptions.first,
    )['icon'] as IconData;

    final newTag = CustomTag(
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      label: _customTagController.text.trim(),
      icon: selectedIconData,
    );

    widget.onAddCustomTag(newTag);
    setState(() {
      _selectedTagId = newTag.id;
      _showCustomTagForm = false;
      _customTagController.clear();
      _selectedCustomIconId = 'heart';
    });
  }

  void _handleSubmit() {
    if (_titleController.text.trim().isEmpty) return;

    widget.onAddMission(NewMissionData(
      _titleController.text.trim(),
      _descController.text.trim(),
      _selectedTagId,
      _isPublic,
    ));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // 키보드가 올라왔을 때 패딩 처리
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("새로운 미션 추가", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("오늘의 소확행을 추가해보세요", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              ],
            ),
          ),
          const Divider(height: 1),

          // 폼 영역
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // 제목
                const Text("미션 제목", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: "예: 아침에 따뜻한 차 한 잔 마시기",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.orange)),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  onChanged: (_) => setState(() {}), // 버튼 활성화를 위해 리빌드
                ),

                const SizedBox(height: 24),

                // 설명
                const Text("한 줄 설명", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                const SizedBox(height: 8),
                TextField(
                  controller: _descController,
                  decoration: InputDecoration(
                    hintText: "미션에 대한 간단한 설명을 입력해주세요",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.orange)),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),

                const SizedBox(height: 24),

                // 태그 선택 섹션
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("성향 태그", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                    TextButton.icon(
                      onPressed: () => setState(() => _showCustomTagForm = !_showCustomTagForm),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text("태그 추가", style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
                    )
                  ],
                ),

                // 커스텀 태그 폼
                if (_showCustomTagForm)
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _customTagController,
                                decoration: const InputDecoration(
                                  hintText: "새 태그 이름",
                                  isDense: true,
                                  contentPadding: EdgeInsets.all(12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide.none),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _handleAddCustomTag,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
                              ),
                              child: const Text("추가"),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: _customIconOptions.map((opt) {
                            final isSelected = _selectedCustomIconId == opt['id'];
                            return GestureDetector(
                              onTap: () => setState(() => _selectedCustomIconId = opt['id']),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isSelected ? Colors.orange : Colors.grey.shade200, width: isSelected ? 2 : 1),
                                ),
                                child: Icon(opt['icon'], size: 20, color: isSelected ? Colors.orange : Colors.grey),
                              ),
                            );
                          }).toList(),
                        )
                      ],
                    ),
                  ),

                // 태그 리스트 (Grid)
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: [
                    ..._defaultTags,
                    ...widget.customTags.map((t) => {'id': t.id, 'label': t.label, 'icon': t.icon})
                  ].map((tag) {
                    final isSelected = _selectedTagId == tag['id'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTagId = tag['id']),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.orange.shade50 : Colors.white,
                          border: Border.all(color: isSelected ? Colors.orange : Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(tag['icon'], size: 20, color: isSelected ? Colors.orange : Colors.grey),
                            const SizedBox(width: 8),
                            Text(tag['label'], style: TextStyle(
                              color: isSelected ? Colors.orange.shade900 : Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            )),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // 공개 설정 스위치
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("공개 설정", style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            _isPublic ? "다른 사용자들과 미션을 공유합니다" : "나만 볼 수 있는 개인 미션입니다",
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isPublic,
                        onChanged: (v) => setState(() => _isPublic = v),
                        activeColor: Colors.orange,
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 완료 버튼
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _titleController.text.trim().isNotEmpty ? _handleSubmit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      disabledBackgroundColor: Colors.orange.withOpacity(0.3),
                    ),
                    child: const Text("미션 추가하기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}