import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // 💡 Cupertino 위젯(알림창 등)을 위한 import
import 'package:provider/provider.dart'; // 💡 Provider 패키지를 위한 import
import '../providers/diary_provider.dart';

class GoalSettingScreen extends StatefulWidget {
  const GoalSettingScreen({super.key});

  @override
  State<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends State<GoalSettingScreen> {
  // --- 💡 더미 데이터 및 상태 변수 💡 ---
  // 각 앱의 목표 시간을 저장하기 위한 변수. 나중에 모델이나 Provider로 관리할 수 있습니다.
  int? _instagramGoal = 3;
  int? _youtubeGoal = 1;
  int? _chatGoal = 1;
  bool _isLoading = false; // 💡 이 변수가 false로 초기화되어 있는지 확인

  // To-do list 텍스트를 관리하기 위한 컨트롤러
// 동적인 To-do 리스트 데이터를 관리
  final List<Map<String, dynamic>> _todoList = [
    {'text': '매일 아침 스트레칭하기', 'isChecked': false},
    {'text': 'Flutter 공부 2시간', 'isChecked': true},
  ];
// 새로운 할 일을 입력받기 위한 컨트롤러
  final TextEditingController _todoInputController = TextEditingController();

  @override
  void dispose() {
    _todoInputController.dispose(); // <-- 컨트롤러 변경
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '오늘의 목표 설정',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // 앱별 목표 시간 설정 섹션
              _buildAppGoalSetter(
                icon: Icons.camera_alt_outlined,
                usageTime: "사용 시간 : 2시간 22분",
                selectedValue: _instagramGoal,
                onChanged: (value) {
                  setState(() {
                    _instagramGoal = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              _buildAppGoalSetter(
                icon: Icons.play_circle_outline,
                usageTime: "사용 시간 : 2시간 1분",
                selectedValue: _youtubeGoal,
                onChanged: (value) {
                  setState(() {
                    _youtubeGoal = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              _buildAppGoalSetter(
                icon: Icons.chat_bubble_outline,
                usageTime: "사용 시간 : 15분",
                selectedValue: _chatGoal,
                onChanged: (value) {
                  setState(() {
                    _chatGoal = value;
                  });
                },
              ),
              const SizedBox(height: 24),

              // 앱 추가하기/변경하기 버튼
              _buildAddAppButton(),
              const SizedBox(height: 40),

              // To-do 리스트 카드
              _buildTodoListCard(),
              const SizedBox(height: 40),

              // 저장/시나리오 확인 버튼
              _buildSaveButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 앱별 목표 시간 설정 위젯
  Widget _buildAppGoalSetter({
    required IconData icon,
    required String usageTime,
    required int? selectedValue,
    required ValueChanged<int?> onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, size: 40, color: Colors.grey.shade800),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(usageTime, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text("목표 시간", style: TextStyle(fontSize: 16)),
                const SizedBox(width: 12),
                // 드롭다운 버튼
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selectedValue,
                      icon: const Icon(Icons.arrow_drop_down),
                      items: List.generate(24, (index) => index + 1)
                          .map((hour) => DropdownMenuItem(
                                value: hour,
                                child: Text('$hour'),
                              ))
                          .toList(),
                      onChanged: onChanged,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // 앱 추가하기/변경하기 버튼 위젯
  Widget _buildAddAppButton() {
    return GestureDetector(
      onTap: () {
        // TODO: 앱 추가/변경 기능 구현
        print("앱 추가하기/변경하기 클릭");
      },
      child: Row(
        children: [
          Icon(Icons.add_circle_outline, size: 40, color: Colors.grey.shade600),
          const SizedBox(width: 16),
          Text(
            "앱 추가하기/변경하기",
            style: TextStyle(
              fontSize: 16,
              color: Colors.red.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // To-do 리스트 카드 위젯
  Widget _buildTodoListCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          // --- 1. 헤더 ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF4B6),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Text(
              'To do list',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),

          // --- 2. 할 일 목록 ---
          // Column을 사용해 리스트의 각 항목을 동적으로 생성
          Column(
            children: _todoList.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> todoItem = entry.value;

              return CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading, // 체크박스를 앞으로
                title: Text(
                  todoItem['text'],
                  style: TextStyle(
                    decoration: todoItem['isChecked']
                        ? TextDecoration.lineThrough // 체크되면 취소선
                        : TextDecoration.none,
                    color: todoItem['isChecked'] ? Colors.grey : Colors.black,
                  ),
                ),
                value: todoItem['isChecked'],
                onChanged: (bool? value) {
                  setState(() {
                    _todoList[index]['isChecked'] = value!;
                  });
                },
              );
            }).toList(),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),

          // --- 3. 새 할 일 입력 필드 ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _todoInputController,
                    decoration: const InputDecoration(
                      hintText: "새 할 일 추가...",
                      border: InputBorder.none,
                    ),
                    // '완료' 버튼 눌렀을 때도 추가되도록
                    onSubmitted: (_) => _addTodoItem(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.blue),
                  onPressed: _addTodoItem,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// 새 할 일을 리스트에 추가하는 함수
  void _addTodoItem() {
    if (_todoInputController.text.isNotEmpty) {
      setState(() {
        _todoList.add({
          'text': _todoInputController.text,
          'isChecked': false,
        });
        _todoInputController.clear(); // 입력창 비우기
      });
    }
  }
  // goal_setting_screen.dart -> _GoalSettingScreenState 클래스 안에 추가

  void _showSuccessDialog() {
    // Provider에서 생성된 마지막 소설을 가져옵니다.
    final lastNovel =
        Provider.of<DiaryProvider>(context, listen: false).lastNovel;
    if (lastNovel == null) return;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('시나리오 생성 완료!'),
        content: const Text('새로운 What If 시나리오가 만들어졌습니다.\n지금 확인해 보시겠어요?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('나중에'),
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
              Navigator.of(context).pop(); // 목표 설정 화면 닫고 홈으로 이동
            },
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('확인'),
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
              Navigator.of(context).pop(); // 목표 설정 화면 닫기
              // TODO: 생성된 소설 상세 페이지로 이동하는 로직 (NovelDetailPage)
              // Navigator.of(context).push( ... NovelDetailPage(diary: lastNovel) ... );
            },
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('오류 발생'),
        content: Text('시나리오 생성에 실패했습니다.\n\n$message'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('확인'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // 저장/시나리오 확인 버튼 위젯
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        // _buildSaveButton 메서드 안의 onPressed 부분
        onPressed: _isLoading
            ? null
            : () async {
                // 실제 앱 사용 시간 데이터 (현재는 더미 데이터)
                final Map<String, double> dummyAppUsage = {
                  '인스타그램': 2.5,
                  '유튜브': 1.2,
                  '채팅': 0.5,
                };

                final Map<String, int?> appGoals = {
                  '인스타그램': _instagramGoal,
                  '유튜브': _youtubeGoal,
                  '채팅': _chatGoal,
                };

                setState(() {
                  _isLoading = true;
                });

                try {
                  // 다이어리 프로바이더를 호출하여 소설 생성
                  await Provider.of<DiaryProvider>(context, listen: false)
                      .generateGoalBasedNovel(
                    context: context,
                    appGoals: appGoals,
                    todoList: _todoList,
                    appUsage: dummyAppUsage,
                  );

                  // 💡 성공 시 알림창 띄우기
                  _showSuccessDialog();
                } catch (e) {
                  // 💡 실패 시 에러 알림창 띄우기
                  _showErrorDialog(e.toString());
                } finally {
                  // 성공/실패 여부와 관계없이 로딩 상태 해제
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00C73C), // 초록색 배경
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Text(
          '저장/시나리오 확인',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
