// models/app_goal_model.dart
class AppGoal {
  final String name;
  final String imagePath;
  int goalHours;
  int goalMinutes;
  double usageHours; // 실제 사용 시간 (사용자가 수정 가능)
  int usageMinutes; // 실제 사용 분 추가

  AppGoal({
    required this.name,
    required this.imagePath,
    required this.goalHours,
    required this.goalMinutes,
    this.usageHours = 0.0,
    this.usageMinutes = 0,
  });

  // Firestore에 저장하기 위한 toMap
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imagePath': imagePath,
      'goalHours': goalHours,
      'goalMinutes': goalMinutes,
      'usageHours': usageHours,
      'usageMinutes': usageMinutes,
    };
  }

  // Firestore에서 불러오기 위한 fromMap
  factory AppGoal.fromMap(Map<String, dynamic> map) {
    return AppGoal(
      name: map['name'] as String? ?? '',
      imagePath: map['imagePath'] as String? ?? '',
      goalHours: map['goalHours'] as int? ?? 1,
      goalMinutes: map['goalMinutes'] as int? ?? 0,
      usageHours: (map['usageHours'] as num?)?.toDouble() ?? 0.0,
      usageMinutes: map['usageMinutes'] as int? ?? 0,
    );
  }
}
