import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:page_transition/page_transition.dart';
import 'diary_list_page.dart';
import 'settings_screen.dart';
import 'profile_edit_page.dart';
import 'package:provider/provider.dart';
import '../providers/diary_provider.dart';
import '../pages/novel_detail_page.dart';
import '../providers/app_goal_provider.dart';
import '../providers/todo_provider.dart';
<<<<<<< HEAD
import '../providers/usage_stats_provider.dart';
import '../models/app_goal_model.dart';
import '../widgets/usage_chart_widget.dart';
=======
import '../providers/user_profile_provider.dart';
import '../models/app_goal_model.dart';
>>>>>>> 7519f368d92fb58f1a71ac4e849afe5556645bef
import '../widgets/loading_dialog.dart';

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
  bool _apiCompleted = false; // API 완료 여부
  bool _hasError = false; // 에러 발생 여부
  String? _errorMessage; // 에러 메시지

  final TextEditingController _todoInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 사용량 통계 로드
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final usageStatsProvider = Provider.of<UsageStatsProvider>(context, listen: false);
      final appGoalProvider = Provider.of<AppGoalProvider>(context, listen: false);

      // UsageStats 데이터 로드
      await Future.wait([
        usageStatsProvider.loadUsageStats(),
        appGoalProvider.syncAllUsageData(), // 오늘/어제 사용량 동기화 (날짜 변경 감지 포함)
      ]);
    });
  }

  // ✨ 성공률 계산 함수
  double _calculateSuccessRate(List<AppGoal> goals) {
    if (goals.isEmpty) return 1.0; // 앱이 없으면 100%

    int totalApps = goals.length;
    int exceededApps = 0;

    for (var goal in goals) {
      final goalTotalMinutes = goal.goalHours * 60 + goal.goalMinutes;
      final usageTotalMinutes = (goal.usageHours * 60).toInt() + goal.usageMinutes;

      // 목표 시간을 초과했는지 확인
      if (goalTotalMinutes > 0 && usageTotalMinutes > goalTotalMinutes) {
        exceededApps++;
      }
    }

    // 100%에서 시작해서 초과한 앱당 (100/총앱개수)%씩 차감
    double successRate = 1.0 - (exceededApps / totalApps);
    return successRate.clamp(0.0, 1.0); // 0~1 사이 값으로 제한
  }

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
              PageTransition(
                type: PageTransitionType.leftToRight,
                child: const SettingsScreen(),
                duration: const Duration(milliseconds: 300),
              ),
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
<<<<<<< HEAD
              // ✨ 사용시간 입력 카드 (주석처리 - 더 이상 사용하지 않음)
              // _buildUsageInputCard(appGoalProvider),
              // const SizedBox(height: 24),
=======
              // 상단 스크린 타임 차트 카드 (기존과 동일)
              _buildScreenTimeChartCard(appGoalProvider)
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.2, end: 0),
              const SizedBox(height: 24),
              // ✨ 사용시간 입력 카드
              _buildUsageInputCard(appGoalProvider)
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 100.ms)
                  .slideY(begin: 0.2, end: 0),
              const SizedBox(height: 24),
>>>>>>> 7519f368d92fb58f1a71ac4e849afe5556645bef
              // ✨ 새로 추가된 중간 성공률 카드
              _buildSuccessRateCard(appGoalProvider.goals)
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 200.ms)
                  .slideY(begin: 0.2, end: 0),
              const SizedBox(height: 24),
              // ✨ 새로 추가된 하단 To-do 리스트 카드
              _buildTodoListCard()
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 300.ms)
                  .slideY(begin: 0.2, end: 0),
              const SizedBox(height: 32),
              // ✨ 변경된 하단 버튼 영역
              _buildBottomButtons()
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 400.ms)
                  .slideY(begin: 0.2, end: 0),
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

  Widget _buildScreenTimeChartCard(AppGoalProvider appGoalProvider) {
    // ✨ Provider를 통해 총 사용시간을 동적으로 계산
    final totalScreenTime = appGoalProvider.getTotalUsageFormatted();

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

  // ✨ 목표 대비 사용량 카드 위젯
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
          // 제목
          const Text('목표 대비 사용량',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            '어제 데이터 기반 (What If 생성에 사용됩니다)',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          // 앱이 없을 때
          if (goals.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  '등록된 앱이 없습니다',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            )
          else
            // 앱별 목표 대비 사용량 바 그래프
            ...goals.map((goal) => _buildGoalVsUsageBar(goal)),
        ],
      ),
    );
  }

  // 목표 대비 사용량 바 그래프
  Widget _buildGoalVsUsageBar(AppGoal goal) {
    // 목표 시간 (분)
    final goalMinutes = (goal.goalHours * 60) + goal.goalMinutes;
    // 실제 사용 시간 (분, 어제 데이터)
    final usageMinutes = (goal.yesterdayUsageHours * 60).toInt() + goal.yesterdayUsageMinutes;

<<<<<<< HEAD
    // 비율 계산
    final double percentage = goalMinutes > 0 ? (usageMinutes / goalMinutes) : 0.0;
    final bool isExceeded = usageMinutes > goalMinutes;
=======
  Widget _buildAppUsageRow(AppGoal goal) {
    // 목표 시간과 사용 시간을 분 단위로 변환하여 진행률 계산
    final goalTotalMinutes = goal.goalHours * 60 + goal.goalMinutes;
    final usageTotalMinutes = (goal.usageHours * 60).toInt() + goal.usageMinutes;
    // 목표가 0일 경우를 대비하여 분모가 0이 되지 않도록 처리
    final progress =
        goalTotalMinutes > 0 ? (usageTotalMinutes / goalTotalMinutes) : 0.0;

    // 목표 초과 여부에 따라 색상 결정 (초과만 빨간색, 정확히 달성은 파란색)
    final isExceeded = progress > 1.0;
    final barColor = isExceeded ? Colors.red : Colors.blue;

    // 사용시간을 시간과 분으로 분리하여 표시
    final usageHoursPart = goal.usageHours.toInt();
    final usageMinutesPart = goal.usageMinutes;
>>>>>>> 7519f368d92fb58f1a71ac4e849afe5556645bef

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 앱 이름 & 시간
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                goal.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Text(
                '${usageMinutes ~/ 60}h ${usageMinutes % 60}m / ${goalMinutes ~/ 60}h ${goalMinutes % 60}m',
                style: TextStyle(
                  fontSize: 12,
                  color: isExceeded ? Colors.red : Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 바 그래프
          Stack(
            children: [
              // 배경 (전체 목표)
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // 실제 사용량
              FractionallySizedBox(
                widthFactor: (percentage).clamp(0.0, 1.0),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: isExceeded ? Colors.red : Colors.blue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // 목표 초과 시 추가 바
              if (isExceeded)
                FractionallySizedBox(
                  widthFactor: 1.0,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          // 퍼센트 표시
          Text(
            '${(percentage * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ✨ 사용시간 입력 카드 위젯
  Widget _buildUsageInputCard(AppGoalProvider appGoalProvider) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('오늘의 스마트폰 사용시간 입력',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () => _showAddAppDialog(appGoalProvider),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('앱 추가'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 앱이 없을 때 안내 메시지
          if (appGoalProvider.goals.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  '추적할 앱을 추가해주세요',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            )
          else
            ...appGoalProvider.goals.map((goal) => _buildUsageInputRow(goal, appGoalProvider)),
        ],
      ),
    );
  }

  // ✨ 각 앱별 사용시간 입력 행
  Widget _buildUsageInputRow(AppGoal goal, AppGoalProvider appGoalProvider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          // 앱 아이콘 또는 기본 아이콘
          _buildAppIcon(goal.imagePath),
          const SizedBox(width: 12),
          Expanded(
            child: Text(goal.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          // 시간 입력
          SizedBox(
            width: 60,
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '${goal.usageHours.toInt()}',
                suffix: const Text('h', style: TextStyle(fontSize: 12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (value) {
                final hours = double.tryParse(value) ?? 0.0;
                appGoalProvider.updateUsage(goal.name, hours, goal.usageMinutes);
              },
            ),
          ),
          const SizedBox(width: 6),
          // 분 입력
          SizedBox(
            width: 60,
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '${goal.usageMinutes}',
                suffix: const Text('m', style: TextStyle(fontSize: 12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (value) {
                final minutes = int.tryParse(value) ?? 0;
                appGoalProvider.updateUsage(goal.name, goal.usageHours, minutes);
              },
            ),
          ),
          const SizedBox(width: 6),
          // 삭제 버튼
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: Colors.grey,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _showDeleteAppDialog(goal.name, appGoalProvider),
          ),
        ],
      ),
    );
  }

  // ✨ 새로 추가된 To-do 리스트 카드 위젯
  Widget _buildTodoListCard() {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        final todoList = todoProvider.todos;

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
                children: todoList.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> todoItem = entry.value;

                  return SizedBox(
                    height: 40,
                    child: Row(
                      children: [
                        Expanded(
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
                              todoProvider.toggleTodo(index);
                            },
                          ),
                        ),
                        // 삭제 버튼 추가
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          color: Colors.grey,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => todoProvider.deleteTodo(index),
                        ),
                      ],
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
                      onSubmitted: (_) => _addTodoItem(todoProvider),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.blue),
                    onPressed: () => _addTodoItem(todoProvider),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ✨ 새 할 일을 리스트에 추가하는 함수
  void _addTodoItem(TodoProvider todoProvider) {
    if (_todoInputController.text.isNotEmpty) {
      todoProvider.addTodo(_todoInputController.text);
      _todoInputController.clear();
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
<<<<<<< HEAD
            // ✨ 새로운 로딩 다이얼로그를 사용한 로직
=======
            // ✨ onPressed 로직을 비동기로 수정 - 프로필 검증 + 로딩 다이얼로그 추가
>>>>>>> 7519f368d92fb58f1a71ac4e849afe5556645bef
            onPressed: _isLoading
                ? null
                : () async {
                    // 🔒 프로필 필수 정보 검증
                    final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
                    if (!userProfileProvider.hasRequiredProfile) {
                      _showProfileRequiredDialog();
                      return;
                    }

                    setState(() {
                      _isLoading = true;
                      _apiCompleted = false;
                      _hasError = false;
                      _errorMessage = null;
                    });

<<<<<<< HEAD
                    // API 호출 결과를 저장할 변수
                    bool apiCompleted = false;
                    bool apiSuccess = false;
                    String? apiError;
=======
                    // 🎨 로딩 다이얼로그 표시 (100% 도달 시 콜백 실행)
                    showDialog(
                      context: context,
                      barrierDismissible: false, // 사용자가 임의로 닫지 못하게
                      builder: (BuildContext dialogContext) {
                        return AIGenerationLoadingDialog(
                          onComplete: () {
                            // 100% 도달 시 실행
                            if (mounted) {
                              Navigator.of(context).pop(); // 로딩 다이얼로그 닫기

                              // API 완료 여부에 따라 처리
                              if (_hasError) {
                                _showErrorDialog(_errorMessage ?? '알 수 없는 오류');
                              } else {
                                _showSuccessDialog(); // "보러가볼까요?" 다이얼로그
                              }

                              setState(() {
                                _isLoading = false;
                              });
                            }
                          },
                        );
                      },
                    );

                    // 백그라운드에서 API 호출 (결과는 저장만 하고 대기)
                    try {
                      // ✨ AppGoalProvider에서 실제 데이터를 가져옴
                      final appGoalProvider = Provider.of<AppGoalProvider>(context, listen: false);
                      final goals = appGoalProvider.goals;
>>>>>>> 7519f368d92fb58f1a71ac4e849afe5556645bef

                    // ✨ AppGoalProvider에서 실제 데이터를 가져옴
                    final appGoalProvider = Provider.of<AppGoalProvider>(context, listen: false);
                    final goals = appGoalProvider.goals;

                    // 홈 화면의 데이터를 Provider가 요구하는 형식으로 가공
                    // 목표는 임의로 설정 (What If 시나리오용, 실제 목표는 이후 설정)
                    final Map<String, int?> appGoals = {
                      for (var goal in goals)
                        goal.name: (goal.goalHours * 60 + goal.goalMinutes)
                    };

                    // ✨ 어제 실제 사용시간 데이터 (분 단위로 변환)
                    final Map<String, int> appUsage = {
                      for (var goal in goals)
                        goal.name: (goal.yesterdayUsageHours * 60).toInt() + goal.yesterdayUsageMinutes
                    };

                    // TodoProvider에서 todoList 가져오기
                    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
                    final todoList = todoProvider.todos;

                    // API 호출을 백그라운드에서 시작
                    Provider.of<DiaryProvider>(context, listen: false)
                        .generateGoalBasedNovel(
                      context: context,
                      appGoals: appGoals,
                      todoList: todoList,
                      appUsage: appUsage,
                    ).then((_) {
                      apiCompleted = true;
                      apiSuccess = true;
                    }).catchError((e) {
                      apiCompleted = true;
                      apiSuccess = false;
                      apiError = e.toString();
                    });

                    // 로딩 다이얼로그 표시
                    if (mounted) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext dialogContext) {
                          return AIGenerationLoadingDialog(
                            onComplete: () async {
                              // 다이얼로그가 100%에 도달했을 때
                              // API 호출이 완료될 때까지 대기
                              while (!apiCompleted) {
                                await Future.delayed(const Duration(milliseconds: 500));
                              }

<<<<<<< HEAD
                              // 다이얼로그 닫기
                              if (mounted) {
                                Navigator.of(dialogContext).pop();

                                setState(() {
                                  _isLoading = false;
                                });

                                // API 결과에 따라 성공/실패 다이얼로그 표시
                                if (apiSuccess) {
                                  _showSuccessDialog();
                                } else {
                                  _showErrorDialog(apiError ?? '알 수 없는 오류');
                                }
                              }
                            },
                          );
                        },
                      );
=======
                      // ✅ API 완료 - 결과만 저장하고 대기
                      if (mounted) {
                        setState(() {
                          _apiCompleted = true;
                        });
                      }
                    } catch (e) {
                      // ❌ 에러 발생 - 에러 정보 저장하고 대기
                      if (mounted) {
                        setState(() {
                          _hasError = true;
                          _errorMessage = e.toString();
                          _apiCompleted = true;
                        });
                      }
>>>>>>> 7519f368d92fb58f1a71ac4e849afe5556645bef
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
<<<<<<< HEAD
=======
            // 버튼 텍스트
>>>>>>> 7519f368d92fb58f1a71ac4e849afe5556645bef
            child: const Text('What if ?!',
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
                      PageTransition(
                        type: PageTransitionType.fade,
                        child: const DiaryListPage(),
                        duration: const Duration(milliseconds: 300),
                      ),
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
<<<<<<< HEAD
                CupertinoPageRoute(
                  builder: (context) => NovelDetailPage(
                    diary: lastNovel,
                    showNextButton: true,
                  ),
=======
                PageTransition(
                  type: PageTransitionType.rightToLeft,
                  child: NovelDetailPage(diary: lastNovel),
                  duration: const Duration(milliseconds: 400),
>>>>>>> 7519f368d92fb58f1a71ac4e849afe5556645bef
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

  /// 프로필 미작성 시 안내 다이얼로그
  void _showProfileRequiredDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('프로필 정보가 필요해요'),
        content: const Text(
          'What If 시나리오를 만들기 위해서는\n'
          '먼저 프로필 정보를 입력해주셔야 해요.\n\n'
          '이름, 생년월일, 성별 등의 정보를 바탕으로\n'
          '당신만의 특별한 스토리를 만들어드립니다!',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('나중에'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('프로필 작성하기'),
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
              // 프로필 작성 페이지로 이동
              Navigator.of(context).push(
                PageTransition(
                  type: PageTransitionType.rightToLeft,
                  child: const ProfileEditPage(isFirstTime: false),
                  duration: const Duration(milliseconds: 300),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ✨ 앱 아이콘 또는 기본 아이콘 표시
  Widget _buildAppIcon(String imagePath) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: imagePath == 'assets/images/default_app.png'
          ? const Icon(Icons.apps, size: 20, color: Colors.grey)
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                imagePath,
                width: 32,
                height: 32,
                errorBuilder: (context, error, stackTrace) {
                  // 이미지 로드 실패 시 기본 아이콘 표시
                  return const Icon(Icons.apps, size: 20, color: Colors.grey);
                },
              ),
            ),
    );
  }

  // ✨ 앱 삭제 확인 다이얼로그
  void _showDeleteAppDialog(String appName, AppGoalProvider appGoalProvider) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('앱 삭제'),
        content: Text('$appName을(를) 목록에서 삭제하시겠습니까?'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('취소'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('삭제'),
            onPressed: () async {
              await appGoalProvider.deleteApp(appName);
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$appName이(가) 삭제되었습니다')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // ✨ 앱 추가 다이얼로그
  void _showAddAppDialog(AppGoalProvider appGoalProvider) {
    final TextEditingController appNameController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('앱 추가'),
        content: Column(
          children: [
            const SizedBox(height: 16),
            const Text('관리할 앱/서비스 이름을 입력하세요'),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: appNameController,
              placeholder: '예: Instagram, TikTok, Netflix',
              autofocus: true,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('취소'),
            onPressed: () {
              appNameController.dispose();
              Navigator.of(context).pop();
            },
          ),
          CupertinoDialogAction(
            isDestructiveAction: false,
            child: const Text('추가'),
            onPressed: () async {
              final appName = appNameController.text.trim();
              if (appName.isEmpty) {
                // 입력이 비어있으면 아무것도 하지 않음
                return;
              }

              try {
                await appGoalProvider.addApp(appName);
                appNameController.dispose();
                if (mounted) {
                  Navigator.of(context).pop();
                  // 성공 메시지 (선택사항)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$appName이(가) 추가되었습니다')),
                  );
                }
              } catch (e) {
                // 에러 처리 (예: 중복 앱)
                if (mounted) {
                  Navigator.of(context).pop();
                  showCupertinoDialog(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: const Text('오류'),
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('확인'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
