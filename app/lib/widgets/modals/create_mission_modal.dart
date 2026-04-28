import 'package:flutter/material.dart';

class CreateMissionModal extends StatefulWidget {
  final Function(String title, String icon, String color, bool isPublic, String? time) onCreateMission;

  const CreateMissionModal({
    super.key,
    required this.onCreateMission,
  });

  @override
  State<CreateMissionModal> createState() => _CreateMissionModalState();
}

class _CreateMissionModalState extends State<CreateMissionModal> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  String _selectedIconId = 'sun';
  String _selectedColorId = 'orange';
  bool _isPublic = false;

  // ✅ 로딩 상태 추가
  bool _isSubmitting = false;

  // 아이콘 옵션
  final List<Map<String, dynamic>> _iconOptions = [
    {'id': 'sun', 'icon': Icons.wb_sunny_rounded},
    {'id': 'book', 'icon': Icons.menu_book_rounded},
    {'id': 'leaf', 'icon': Icons.eco_rounded},
    {'id': 'heart', 'icon': Icons.favorite_rounded},
    {'id': 'coffee', 'icon': Icons.coffee_rounded},
    {'id': 'star', 'icon': Icons.star_rounded},
    {'id': 'tree', 'icon': Icons.park_rounded},
    {'id': 'zap', 'icon': Icons.bolt_rounded},
    {'id': 'flame', 'icon': Icons.local_fire_department_rounded},
  ];

  // 색상 옵션
  final List<Map<String, dynamic>> _colorOptions = [
    {'id': 'white', 'color': 0xFFFFFFFF, 'darkColor': 0xFF6B7280},
    {'id': 'orange', 'color': 0xFFFFD6A5, 'darkColor': 0xFFFF9A56},
    {'id': 'yellow', 'color': 0xFFFDFD96, 'darkColor': 0xFFE8E86E},
    {'id': 'green', 'color': 0xFFCAFFBF, 'darkColor': 0xFF84E8A4},
    {'id': 'blue', 'color': 0xFFA0C4FF, 'darkColor': 0xFF6B9FE8},
    {'id': 'purple', 'color': 0xFFDBC4FF, 'darkColor': 0xFFB896E8},
    {'id': 'pink', 'color': 0xFFFFD6E8, 'darkColor': 0xFFFFADD2},
    {'id': 'red', 'color': 0xFFFFADAD, 'darkColor': 0xFFFF7A7A},
    {'id': 'peach', 'color': 0xFFFFC6A5, 'darkColor': 0xFFFF9270},
  ];

  // ✅ dispose 추가
  @override
  void dispose() {
    _titleController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _currentColor =>
      _colorOptions.firstWhere(
            (c) => c['id'] == _selectedColorId,
        orElse: () => _colorOptions[1], // orange
      );

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.orange,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        final hour = picked.hour.toString().padLeft(2, '0');
        final minute = picked.minute.toString().padLeft(2, '0');
        _timeController.text = "$hour:$minute";
      });
    }
  }

  // ✅ 유효성 검사
  String? _validateTitle(String title) {
    if (title.isEmpty) {
      return '제목을 입력해주세요';
    }
    if (title.length > 50) {
      return '제목은 50자 이하여야 합니다';
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    final title = _titleController.text.trim();

    // 유효성 검사
    final error = _validateTitle(title);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    // 중복 제출 방지
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      // 색상 Hex Code 변환
      String colorHex = '#${Color(_currentColor['color']).value.toRadixString(16).substring(2).toUpperCase()}';

      widget.onCreateMission(
        title,
        _selectedIconId,
        colorHex,
        _isPublic,
        _timeController.text.isEmpty ? null : _timeController.text,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isValid = _titleController.text.trim().isNotEmpty &&
        _titleController.text.trim().length <= 50;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                const Text(
                  "새 미션 만들기",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                // 닫기 버튼
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 콘텐츠
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // 제목 입력
                const Text("제목", style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  maxLength: 50,
                  decoration: InputDecoration(
                    hintText: "오늘의 소확행을 입력하세요",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.orange),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                    counterText: '',
                  ),
                  onChanged: (_) => setState(() {}),
                ),

                // ✅ 글자 수 표시
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_titleController.text.length}/50',
                    style: TextStyle(
                      fontSize: 12,
                      color: _titleController.text.length > 50
                          ? Colors.red
                          : Colors.grey,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 아이콘 선택
                const Text("아이콘", style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: _iconOptions.length,
                  itemBuilder: (context, index) {
                    final option = _iconOptions[index];
                    final isSelected = _selectedIconId == option['id'];
                    final activeColor = Color(_currentColor['darkColor']);
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIconId = option['id']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.orange.shade50
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.orange.shade300
                                : Colors.grey.shade200,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          option['icon'],
                          color: isSelected ? activeColor : Colors.grey.shade400,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // 색상 선택
                const Text("카드 색상", style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _colorOptions.map((option) {
                    final isSelected = _selectedColorId == option['id'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColorId = option['id']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(option['color']),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.grey.shade800
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                            BoxShadow(
                              color: Color(option['color']).withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                              : null,
                        ),
                        child: isSelected
                            ? Icon(
                          Icons.check,
                          size: 20,
                          color: Colors.grey.shade800,
                        )
                            : null,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // 시간 선택
                const Text("시간 (선택사항)", style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _selectTime,
                  child: AbsorbPointer(
                    child: TextField(
                      controller: _timeController,
                      decoration: InputDecoration(
                        hintText: "--:--",
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_timeController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  setState(() => _timeController.clear());
                                },
                              ),
                            const Icon(Icons.access_time),
                            const SizedBox(width: 8),
                          ],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 공개 여부
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "미션 공개",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          "다른 사람들에게 미션을 공유합니다",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isPublic,
                      onChanged: (value) => setState(() => _isPublic = value),
                      activeColor: Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 버튼
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("취소"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (isValid && !_isSubmitting) ? _handleSubmit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.orange.shade200,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      "완료",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}