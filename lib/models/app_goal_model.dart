// models/app_goal_model.dart
class AppGoal {
  final String name;
  final String imagePath;
  int goalHours;
  int goalMinutes;
  final double usageHours; // 실제 사용 시간은 별도로 관리

  AppGoal({
    required this.name,
    required this.imagePath,
    required this.goalHours,
    required this.goalMinutes,
    required this.usageHours,
  });
}
