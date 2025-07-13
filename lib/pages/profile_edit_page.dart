import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/user_profile_provider.dart';
import '../models/user_profile.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late TextEditingController _nameController;
  late TextEditingController _yearController;
  late TextEditingController _dayController;
  late TextEditingController _jobController;
  late TextEditingController _longTermGoalController;
  late TextEditingController _shortTermGoalController;
  late TextEditingController _extraInfoController; // '추가적인 설명'
  late TextEditingController _additionalInfoController; // '요즘 주로 하는 일'에 해당

  int? _selectedMonth;
  String? _selectedGender;

  final List<String> _genderOptions = ['남성', '여성', '기타'];

  // 5가지 스타일 문항 데이터 (기존과 동일)
  final Map<String, List<Map<String, String>>> _styleQuestions = {
    '상황 대처 스타일': [
      {'emoji': '🧍', 'text': '혼자서 끙끙 앓는 편이에요'},
      {'emoji': '🗣', 'text': '바로 말하거나 표현해서 푸는 편이에요'},
      {'emoji': '😅', 'text': '대충 넘기고 금방 잊는 편이에요'},
      {'emoji': '📚', 'text': '곱씹고 정리하면서 이해하려고 해요'},
      {'emoji': '🔁', 'text': '같은 실수를 반복하면서도 계속 해보는 편이에요'},
      {'emoji': '⛔', 'text': '일단 피하고 싶은 마음이 먼저 들어요'},
    ],
    '감정 반응 스타일': [
      {'emoji': '😭', 'text': '감정 표현이 얼굴이나 말에 잘 드러나요'},
      {'emoji': '😐', 'text': '걸으로는 잘 안 드러내요'},
      {'emoji': '😠', 'text': '감정에 휘둘릴 때가 많아요'},
      {'emoji': '🤔', 'text': '감정보다 이성적으로 판단하려고 해요'},
      {'emoji': '😶', 'text': '아무렇지 않은 척하면서 속으로 요동쳐요'},
      {'emoji': '🎢', 'text': '감정 기복이 크고 빨리 바뀌는 편이에요'},
    ],
    '행동 패턴': [
      {'emoji': '⏰', 'text': '하루 루틴을 잘 지키는 편이에요'},
      {'emoji': '🌪', 'text': '즉흥적으로 움직이는 걸 좋아해요'},
      {'emoji': '🧽', 'text': '세세한 부분에 민감하고 정리정돈도 잘해요'},
      {'emoji': '📚', 'text': '한 번 빠지면 깊이 몰입하는 편이에요'},
      {'emoji': '🎯', 'text': '목표가 생기면 일단 해보는 스타일이에요'},
      {'emoji': '🛋', 'text': '미루는 버릇이 있고 자주 흐름 놓쳐요'},
    ],
    '사고 인식/판성 경향': [
      {'emoji': '🔍', 'text': '자주 스스로를 돌아보는 편이에요'},
      {'emoji': '🎭', 'text': '실수는 곧잘 넘기고 별로 깊게 안 파요'},
      {'emoji': '🧩', 'text': '머릿속 생각이 많고 자기반성이 깊어요'},
      {'emoji': '😬', 'text': '나를 좀 냉정하게 보는 편이에요'},
      {'emoji': '🙈', 'text': '일부러 모른 척하거나 무시하려 해요'},
      {'emoji': '💬', 'text': '누가 말해줘야 내가 뭘 했는지 알게 돼요'},
    ],
    '관계 스타일': [
      {'emoji': '🧍', 'text': '혼자 있는 시간이 꼭 필요해요'},
      {'emoji': '👥', 'text': '사람들과 있을 때 에너지를 받아요'},
      {'emoji': '🎭', 'text': '처음엔 낯을 좀 가리는 편이에요'},
      {'emoji': '🐥', 'text': '처음 보는 사람에게도 금방 다가가요'},
      {'emoji': '🤝', 'text': '다른 사람 감정에 잘 휘둘려요'},
      {'emoji': '🧱', 'text': '관계에서 거리감을 유지하는 걸 좋아해요'},
    ],
  };

  Map<String, List<String>> _selectedStyleAnswers = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeStyleAnswers();
    _loadExistingProfile();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _yearController = TextEditingController();
    _dayController = TextEditingController();
    _jobController = TextEditingController();
    _longTermGoalController = TextEditingController();
    _shortTermGoalController = TextEditingController();
    _additionalInfoController = TextEditingController();
    _extraInfoController = TextEditingController();
  }

  void _initializeStyleAnswers() {
    _selectedStyleAnswers = {};
    for (String category in _styleQuestions.keys) {
      _selectedStyleAnswers[category] = [];
    }
  }

  void _loadExistingProfile() {
    final profileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);
    final profile = profileProvider.userProfile;

    _nameController.text = profile.name;
    _yearController.text = profile.birthYear?.toString() ?? '';
    _dayController.text = profile.birthDay?.toString() ?? '';
    _selectedMonth = profile.birthMonth;
    _selectedGender = profile.gender;
    _jobController.text = profile.job ?? '';
    _longTermGoalController.text = profile.longTermGoal ?? '';
    _shortTermGoalController.text = profile.shortTermGoal ?? '';
    _additionalInfoController.text = profile.additionalInfo ?? '';
    _extraInfoController.text = profile.extraInfo ?? '';

    if (profile.styleAnswers != null && profile.styleAnswers!.isNotEmpty) {
      _selectedStyleAnswers = Map.from(profile.styleAnswers!.map(
        (key, value) => MapEntry(key, List<String>.from(value)),
      ));
    } else if (profile.keywords.isNotEmpty) {
      final firstCategory = _styleQuestions.keys.first;
      _selectedStyleAnswers[firstCategory] = List.from(profile.keywords);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    _dayController.dispose();
    _jobController.dispose();
    _longTermGoalController.dispose();
    _shortTermGoalController.dispose();
    _additionalInfoController.dispose();
    _extraInfoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFCF3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '프로필 입력',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text(
              '저장',
              style: TextStyle(
                color: Color(0xFF007AFF),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 UI (기존과 동일)
            const Center(
              child: Column(
                children: [
                  Text(
                    '자세히 입력 해주실 수록',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  Text(
                    '더 재밌는 이야기가 생성됩니다!',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: GestureDetector(
                onTap: _showDataUsageInfo,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      '입력된 정보는 어떻게 사용되나요?',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 기본 정보 입력 (기존과 동일)
            _buildTextField(
              controller: _nameController,
              label: '이름',
              placeholder: '이름',
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _yearController,
                    label: '년',
                    placeholder: '년',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildDropdownField(
                    value: _selectedMonth,
                    items: List.generate(12, (index) => index + 1)
                        .map((month) => DropdownMenuItem(
                              value: month,
                              child: Text('${month}월'),
                            ))
                        .toList(),
                    placeholder: '월',
                    onChanged: (value) {
                      setState(() {
                        _selectedMonth = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _dayController,
                    label: '일',
                    placeholder: '일',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDropdownField(
              value: _selectedGender,
              items: _genderOptions
                  .map((gender) => DropdownMenuItem(
                        value: gender,
                        child: Text(gender),
                      ))
                  .toList(),
              placeholder: '성별',
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _jobController,
              placeholder: '직업 - ex) 직장인, 대학생',
            ),
            const SizedBox(height: 30),

            // --- 💡 여기가 수정된 부분입니다 ---

            // 질문 1: 요즘 주로 어떤 일들을 하고 지내시나요?
            const Text(
              '요즘 주로 어떤 일들을 하고 지내시나요?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildTextArea(
              controller: _additionalInfoController,
              placeholder: 'ex) 시험 공부, 자격증 준비 등',
              maxLines: 3,
            ),

            const SizedBox(height: 30),

            // 질문 2: 앞으로 몇 달 또는 몇 년 안에 이루고 싶은 목표
            const Text(
              '앞으로 몇 달 / 몇 년 안에 이루고 싶은 목표를 적어주세요.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildTextArea(
              controller: _longTermGoalController,
              placeholder: 'ex) 10kg 감량, 공무원 시험 합격 등',
              maxLines: 3,
            ),

            const SizedBox(height: 30),

            // 질문 3: 이번 주나 이번 달 안에 이루고 싶은 목표
            const Text(
              '이번 주나 이번 달 안에 이루고 싶은 목표를 적어주세요.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildTextArea(
              controller: _shortTermGoalController,
              placeholder: 'ex) 시험 과목 정리, 논문 초안 작성 등',
              maxLines: 3,
            ),

            const SizedBox(height: 30),

            const Text(
              '추가적인 설명을 자유롭게 적어주세요.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildTextArea(
              controller: _extraInfoController,
              placeholder: 'ex) 취미, 가치관, 종교, 라이프 스타일 등',
              maxLines: 3,
            ),

            // --- 수정된 부분 끝 ---

            const SizedBox(height: 30),

            // 스타일 문항 (기존과 동일)
            const Text(
              '당신을 가장 잘 표현하는 스타일을 골라주세요!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ..._styleQuestions.entries.map((entry) {
              final category = entry.key;
              final options = entry.value;
              final selectedAnswers = _selectedStyleAnswers[category] ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: selectedAnswers.isNotEmpty
                              ? Colors.green
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: selectedAnswers.isNotEmpty
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 14)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '"${_getCategoryDescription(category)}"',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...options.map((option) {
                    final emoji = option['emoji']!;
                    final text = option['text']!;
                    final isSelected = selectedAnswers.contains(text);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedAnswers.remove(text);
                          } else {
                            selectedAnswers.add(text);
                          }
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF007AFF).withOpacity(0.1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF007AFF)
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              emoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                text,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isSelected
                                      ? const Color(0xFF007AFF)
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              );
            }).toList(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // 나머지 헬퍼 함수들 (기존과 동일)
  String _getCategoryDescription(String category) {
    switch (category) {
      case '상황 대처 스타일':
        return '상황에 부딪혔을 때, 나는 보통 이렇게 반응해요.';
      case '감정 반응 스타일':
        return '감정이 생겼을 때, 나는 이렇게 반응해요.';
      case '행동 패턴':
        return '일상에서 나는 이런 방식으로 행동해요.';
      case '사고 인식/판성 경향':
        return '내 생각이나 신념을 바라보는 방식이에요.';
      case '관계 스타일':
        return '사람들과의 거리나 소통 방식이에요.';
      default:
        return '';
    }
  }

  List<String> _getAllSelectedAnswers() {
    List<String> allAnswers = [];
    _selectedStyleAnswers.forEach((category, answers) {
      allAnswers.addAll(answers);
    });
    return allAnswers;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? label,
    required String placeholder,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF007AFF)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required String placeholder,
    required Function(T?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        dropdownColor: Colors.white,
      ),
    );
  }

  Widget _buildTextArea({
    required TextEditingController controller,
    required String placeholder,
    int maxLines = 3,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF007AFF)),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  void _showDataUsageInfo() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('입력된 정보는 어떻게 사용되나요?'),
        content: const Text(
          '당신이 입력한 정보는\n소설을 더 \'당신답게\' 만들기 위해 사용됩니다.\n'
          '이름, 성격, 취미 설명을 바탕으로\n이야기가 더 구체적이고 몰입감 있게 구성되요.\n\n'
          '이 정보는 외부에 저장되지 않으며,\n다른 용도로 절대 사용되지 않아요.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('확인'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    try {
      final profileProvider =
          Provider.of<UserProfileProvider>(context, listen: false);
      final allSelectedAnswers = _getAllSelectedAnswers();
      final profile = UserProfile(
        name: _nameController.text.trim(),
        birthYear: _yearController.text.trim().isNotEmpty
            ? int.tryParse(_yearController.text.trim())
            : null,
        birthMonth: _selectedMonth,
        birthDay: _dayController.text.trim().isNotEmpty
            ? int.tryParse(_dayController.text.trim())
            : null,
        gender: _selectedGender,
        job: _jobController.text.trim().isNotEmpty
            ? _jobController.text.trim()
            : null,
        longTermGoal: _longTermGoalController.text.trim().isNotEmpty
            ? _longTermGoalController.text.trim()
            : null,
        shortTermGoal: _shortTermGoalController.text.trim().isNotEmpty
            ? _shortTermGoalController.text.trim()
            : null,
        additionalInfo: _additionalInfoController.text.trim().isNotEmpty
            ? _additionalInfoController.text.trim()
            : null,
        extraInfo: _extraInfoController.text.trim().isNotEmpty // 💡 새로 추가
            ? _extraInfoController.text.trim()
            : null,
        keywords: allSelectedAnswers,
        styleAnswers: Map.from(_selectedStyleAnswers),
        agreeToDataUsage: true,
      );

      await profileProvider.saveProfile(profile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필이 저장되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
