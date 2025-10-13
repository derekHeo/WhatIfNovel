import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'goal_setting_screen.dart';
import 'diary_list_page.dart';
import 'settings_screen.dart';
import 'package:provider/provider.dart';
import '../providers/diary_provider.dart';
import '../pages/novel_detail_page.dart';
import '../providers/app_goal_provider.dart';
import '../models/app_goal_model.dart';

// import 'package:provider/provider.dart';
// import '../providers/diary_provider.dart';
// import '../providers/user_profile_provider.dart';
// import '../models/diary_model.dart';
// import 'settings_screen.dart';
// import 'diary_list_page.dart';
// import 'novel_detail_page.dart';
// import 'bookmark_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false; // ✨ 로딩 상태 변수 추가

  // --- 💡 새로운 UI를 위한 더미 데이터 💡 ---

  // 상단 차트 데이터
  final String totalScreenTime = "4시간 23분";

  // 중간 성공률 카드 데이터
  final double overallSuccessRate = 1.0; // 전체 성공률 (100%)
  final List<Map<String, dynamic>> appUsageData = [
    {
      'imagePath': 'assets/images/insta.png',
      'usage': 0.5,
      'goal': 1.0,
      'name': 'insta'
    },
    {
      'imagePath': 'assets/images/youtube.png',
      'usage': 0.5,
      'goal': 1.0,
      'name': 'YouTube'
    },
    {
      'imagePath': 'assets/images/kakao.png',
      'usage': 0.5,
      'goal': 1.0,
      'name': 'Kakao'
    },
  ];

  // 하단 To-do 리스트 데이터
  final List<Map<String, dynamic>> _todoList = [
    {'text': '할일', 'isChecked': true},
  ];
  final TextEditingController _todoInputController = TextEditingController();

  @override
  void dispose() {
    _todoInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appGoalProvider = Provider.of<AppGoalProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black, size: 28),
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // 상단 스크린 타임 차트 카드 (기존과 동일)
              _buildScreenTimeChartCard(),
              const SizedBox(height: 24),
              // ✨ 새로 추가된 중간 성공률 카드
              _buildSuccessRateCard(appGoalProvider.goals),
              const SizedBox(height: 24),
              // ✨ 새로 추가된 하단 To-do 리스트 카드
              _buildTodoListCard(),
              const SizedBox(height: 32),
              // ✨ 변경된 하단 버튼 영역
              _buildBottomButtons(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- 위젯 빌드 함수들 ---
  Widget _buildChartBar(double heightFactor, Color color) {
    // heightFactor는 0.0 ~ 1.0 사이의 값으로, 막대의 높이를 결정합니다.
    return Container(
      width: 12, // 막대의 너비
      height: 100 * heightFactor, // 최대 높이 100을 기준으로 비율만큼 높이 설정
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildScreenTimeChartCard() {
    // 이 위젯은 이전과 동일하게 유지됩니다.
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(totalScreenTime,
              style:
                  const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 간격을 균등하게
              crossAxisAlignment: CrossAxisAlignment.end,
              // ✨ _buildChartBar를 호출하여 막대들을 채워줍니다.
              children: [
                _buildChartBar(0.6, Colors.blue.shade200),
                _buildChartBar(0.8, Colors.blue.shade300),
                _buildChartBar(0.5, Colors.blue.shade200),
                const SizedBox(width: 10), // 카테고리 간 간격
                _buildChartBar(0.9, Colors.orange.shade300),
                _buildChartBar(0.7, Colors.orange.shade200),
                const SizedBox(width: 10), // 카테고리 간 간격
                _buildChartBar(0.8, Colors.teal.shade200),
                _buildChartBar(0.6, Colors.teal.shade300),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildChartLabel('생산성 및 금융', '1시간 25분'),
              _buildChartLabel('소셜 미디어', '51분'),
              _buildChartLabel('엔터테인먼트', '48분'),
            ],
          ),
        ],
      ),
    );
  }

  // ✨ 새로 추가된 성공률 카드 위젯
  Widget _buildSuccessRateCard(List<AppGoal> goals) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 전체 성공률
          const Text('성공률',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: overallSuccessRate,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${(overallSuccessRate * 100).toInt()}%',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
          const SizedBox(height: 24),
          // 앱별 사용량
          ...goals.map((goal) => _buildAppUsageRow(goal)).toList(),
        ],
      ),
    );
  }

  // home_screen.dart 또는 goal_setting_screen.dart에 포함될 함수

  Widget _buildAppUsageRow(AppGoal goal) {
    // 목표 시간과 사용 시간을 분 단위로 변환하여 진행률 계산
    final goalTotalMinutes = goal.goalHours * 60 + goal.goalMinutes;
    final usageTotalMinutes = goal.usageHours * 60;
    // 목표가 0일 경우를 대비하여 분모가 0이 되지 않도록 처리
    final progress =
        goalTotalMinutes > 0 ? (usageTotalMinutes / goalTotalMinutes) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Image.asset(goal.imagePath, width: 28, height: 28),
          const SizedBox(width: 16),
          Expanded(
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0), // 0과 1 사이 값으로 유지
              // --- ✨ 이 부분이 채워졌습니다 ---
              minHeight: 10, // 프로그레스 바의 높이
              borderRadius: BorderRadius.circular(5), // 모서리를 둥글게
              backgroundColor: Colors.grey.shade200, // 배경색
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.blue), // 진행 막대 색상
              // ---------------------------
            ),
          ),
          const SizedBox(width: 16),
          // 목표 시간에 분(minute)도 표시되도록 수정
          Text('${goal.usageHours}h / ${goal.goalHours}h ${goal.goalMinutes}m',
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  // ✨ 새로 추가된 To-do 리스트 카드 위젯
  Widget _buildTodoListCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('To do list',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          // 할 일 목록
          Column(
            children: _todoList.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> todoItem = entry.value;

              return SizedBox(
                height: 40,
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    todoItem['text'],
                    style: TextStyle(
                      decoration: todoItem['isChecked']
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: todoItem['isChecked'] ? Colors.grey : Colors.black,
                    ),
                  ),
                  value: todoItem['isChecked'],
                  onChanged: (bool? value) {
                    // 체크박스 상태 변경 로직
                    setState(() {
                      _todoList[index]['isChecked'] = value!;
                    });
                  },
                ),
              );
            }).toList(),
          ),
          // 새 할 일 입력 필드
          Row(
            children: [
              const SizedBox(width: 12), // 체크박스와 정렬을 맞추기 위한 간격
              Expanded(
                child: TextField(
                  controller: _todoInputController,
                  decoration: const InputDecoration(
                    hintText: '할 일 입력',
                    border: UnderlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addTodoItem(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.blue),
                onPressed: _addTodoItem,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✨ 3. 새 할 일을 리스트에 추가하는 함수 추가 (goal_setting_screen과 동일)
  void _addTodoItem() {
    if (_todoInputController.text.isNotEmpty) {
      setState(() {
        _todoList.add({
          'text': _todoInputController.text,
          'isChecked': false,
        });
        _todoInputController.clear();
      });
    }
  }

  // ✨ 변경된 하단 버튼 위젯
  Widget _buildBottomButtons() {
    return Column(
      children: [
        // _buildBottomButtons 메서드 안의 ElevatedButton 부분 수정

        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            // ✨ onPressed 로직을 비동기로 수정
            onPressed: _isLoading
                ? null
                : () async {
                    setState(() {
                      _isLoading = true;
                    });

                    try {
                      // 홈 화면의 데이터를 Provider가 요구하는 형식으로 가공
                      final Map<String, int?> appGoals = {
                        for (var app in appUsageData)
                          app['name']: (app['goal'] as double).toInt()
                      };
                      final Map<String, double> appUsage = {
                        for (var app in appUsageData)
                          app['name']: app['usage'] as double
                      };

                      // DiaryProvider 호출
                      await Provider.of<DiaryProvider>(context, listen: false)
                          .generateGoalBasedNovel(
                        context: context,
                        appGoals: appGoals,
                        todoList: _todoList,
                        appUsage: appUsage,
                      );

                      _showSuccessDialog(); // 성공 시 알림창
                    } catch (e) {
                      _showErrorDialog(e.toString()); // 실패 시 알림창
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            // ✨ 로딩 상태에 따라 다른 위젯을 보여주도록 child 수정
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('What if ?!',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DiaryListPage()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('이전 기록 보기',
                      style: TextStyle(color: Colors.black)),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ],
    );
  }

  // 차트 라벨 (기존과 동일)
  Widget _buildChartLabel(String title, String time) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(time,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // _HomeScreenState 클래스 안에 추가

  void _showSuccessDialog() {
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
            isDefaultAction: true,
            child: const Text('확인'),
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
              // ✨ 이 부분의 주석을 해제하고 완성합니다.
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => NovelDetailPage(diary: lastNovel),
                ),
              );
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
}
