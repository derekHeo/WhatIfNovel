// models/app_goal_model.dart
class AppGoal {
  final String name;
  final String imagePath;
  final String? packageName; // Android 패키지명 (com.instagram.android 등)
  int goalHours;
  int goalMinutes;
  double usageHours; // 오늘 실제 사용 시간 (00:00부터 누적)
  int usageMinutes; // 오늘 실제 사용 분
  double yesterdayUsageHours; // 어제 사용 시간 (What If 생성용)
  int yesterdayUsageMinutes; // 어제 사용 분

  AppGoal({
    required this.name,
    required this.imagePath,
    this.packageName,
    required this.goalHours,
    required this.goalMinutes,
    this.usageHours = 0.0,
    this.usageMinutes = 0,
    this.yesterdayUsageHours = 0.0,
    this.yesterdayUsageMinutes = 0,
  });

  // Firestore에 저장하기 위한 toMap
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imagePath': imagePath,
      'packageName': packageName,
      'goalHours': goalHours,
      'goalMinutes': goalMinutes,
      'usageHours': usageHours,
      'usageMinutes': usageMinutes,
      'yesterdayUsageHours': yesterdayUsageHours,
      'yesterdayUsageMinutes': yesterdayUsageMinutes,
    };
  }

  // Firestore에서 불러오기 위한 fromMap
  factory AppGoal.fromMap(Map<String, dynamic> map) {
    return AppGoal(
      name: map['name'] as String? ?? '',
      imagePath: map['imagePath'] as String? ?? '',
      packageName: map['packageName'] as String?,
      goalHours: map['goalHours'] as int? ?? 1,
      goalMinutes: map['goalMinutes'] as int? ?? 0,
      usageHours: (map['usageHours'] as num?)?.toDouble() ?? 0.0,
      usageMinutes: map['usageMinutes'] as int? ?? 0,
      yesterdayUsageHours: (map['yesterdayUsageHours'] as num?)?.toDouble() ?? 0.0,
      yesterdayUsageMinutes: map['yesterdayUsageMinutes'] as int? ?? 0,
    );
  }
}
