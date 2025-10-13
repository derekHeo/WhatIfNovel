// pages/goal_setting_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_goal_provider.dart';
import '../models/app_goal_model.dart';

class GoalSettingScreen extends StatefulWidget {
  const GoalSettingScreen({super.key});

  @override
  State<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends State<GoalSettingScreen> {
  // 각 앱의 목표 시간을 임시로 저장할 맵
  late Map<String, Map<String, TextEditingController>> _controllers;

  @override
  void initState() {
    super.initState();
    // Provider에서 초기 데이터를 가져와 컨트롤러를 설정
    final goals = Provider.of<AppGoalProvider>(context, listen: false).goals;
    _controllers = {
      for (var goal in goals)
        goal.name: {
          'hours': TextEditingController(text: goal.goalHours.toString()),
          'minutes': TextEditingController(text: goal.goalMinutes.toString()),
        }
    };
  }

  @override
  void dispose() {
    // 모든 컨트롤러를 정리
    _controllers.forEach((_, value) {
      value['hours']!.dispose();
      value['minutes']!.dispose();
    });
    super.dispose();
  }

  void _saveGoals() {
    final appGoalProvider =
        Provider.of<AppGoalProvider>(context, listen: false);
    _controllers.forEach((appName, controllers) {
      final hours = int.tryParse(controllers['hours']!.text) ?? 0;
      final minutes = int.tryParse(controllers['minutes']!.text) ?? 0;
      appGoalProvider.updateGoal(appName, hours, minutes);
    });
    // 저장 후 홈 화면으로 돌아가기
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // UI 빌드 시 Provider의 데이터를 사용
    final goals = Provider.of<AppGoalProvider>(context).goals;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBFA),
      appBar: AppBar(
          // ... AppBar 설정 ...
          ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // 성공률 카드
            _buildSuccessRateCard(goals),
            const SizedBox(height: 24),
            // To-do 리스트 카드
            _buildTodoListCard(),
            const SizedBox(height: 32),
            // 저장하기 버튼
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saveGoals,
                child: const Text('저장하기',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessRateCard(List<AppGoal> goals) {
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
          const Text('전날 성공률', style: TextStyle(fontWeight: FontWeight.bold)),
          // ... 성공률 바 ...
          const SizedBox(height: 24),
          ...goals.map((goal) => _buildGoalInputRow(goal)).toList(),
        ],
      ),
    );
  }

  Widget _buildGoalInputRow(AppGoal goal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Image.asset(goal.imagePath, width: 28, height: 28),
          const SizedBox(width: 16),
          const Text('목표 시간:'),
          const SizedBox(width: 8),
          _buildTimeInput(_controllers[goal.name]!['hours']!),
          const SizedBox(width: 4),
          const Text('시간'),
          const SizedBox(width: 8),
          _buildTimeInput(_controllers[goal.name]!['minutes']!),
          const SizedBox(width: 4),
          const Text('분'),
        ],
      ),
    );
  }

  Widget _buildTimeInput(TextEditingController controller) {
    return SizedBox(
      width: 50,
      height: 35,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildTodoListCard() {
    // ... To-do 리스트 UI ...
    return Container();
  }
}
