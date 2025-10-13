// providers/app_goal_provider.dart
import 'package:flutter/material.dart';
import '../models/app_goal_model.dart';

class AppGoalProvider with ChangeNotifier {
  // 초기 더미 데이터
  final List<AppGoal> _goals = [
    AppGoal(
        name: 'Instagram',
        imagePath: 'assets/images/insta.png',
        goalHours: 1,
        goalMinutes: 0,
        usageHours: 0.5),
    AppGoal(
        name: 'YouTube',
        imagePath: 'assets/images/youtube.png',
        goalHours: 1,
        goalMinutes: 0,
        usageHours: 0.5),
    AppGoal(
        name: 'KakaoTalk',
        imagePath: 'assets/images/kakao.png',
        goalHours: 1,
        goalMinutes: 0,
        usageHours: 0.5),
  ];

  List<AppGoal> get goals => _goals;

  // 특정 앱의 목표 시간을 업데이트하는 함수
  void updateGoal(String appName, int newHours, int newMinutes) {
    final index = _goals.indexWhere((goal) => goal.name == appName);
    if (index != -1) {
      _goals[index].goalHours = newHours;
      _goals[index].goalMinutes = newMinutes;
      notifyListeners(); // 변경 사항을 모든 리스너에게 알림
    }
  }
}
