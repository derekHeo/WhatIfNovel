/// 스크린타임 데이터 모델
class ScreenTimeModel {
  final String appName; // 앱 이름
  final String bundleId; // 번들 ID (패키지명)
  final Duration usageTime; // 사용 시간
  final String? iconData; // 앱 아이콘 (Base64 인코딩된 이미지 데이터)
  final String? category; // 앱 카테고리
  final DateTime? lastUsed; // 마지막 사용 시간

  const ScreenTimeModel({
    required this.appName,
    required this.bundleId,
    required this.usageTime,
    this.iconData,
    this.category,
    this.lastUsed,
  });

  /// JSON에서 ScreenTimeModel 객체 생성
  factory ScreenTimeModel.fromJson(Map<String, dynamic> json) {
    return ScreenTimeModel(
      appName: json['appName'] as String,
      bundleId: json['bundleId'] as String,
      usageTime: Duration(seconds: (json['usageTimeSeconds'] as num).toInt()),
      iconData: json['iconData'] as String?,
      category: json['category'] as String?,
      lastUsed: json['lastUsed'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['lastUsed'] as num).toInt())
          : null,
    );
  }

  /// ScreenTimeModel 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'bundleId': bundleId,
      'usageTimeSeconds': usageTime.inSeconds,
      'iconData': iconData,
      'category': category,
      'lastUsed': lastUsed?.millisecondsSinceEpoch,
    };
  }

  /// 사용 시간을 사람이 읽기 쉬운 형태로 포맷
  String get formattedUsageTime {
    final hours = usageTime.inHours;
    final minutes = usageTime.inMinutes.remainder(60);
    final seconds = usageTime.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}시간 ${minutes}분';
    } else if (minutes > 0) {
      return '${minutes}분 ${seconds}초';
    } else {
      return '${seconds}초';
    }
  }

  /// 객체 복사 (일부 필드 변경)
  ScreenTimeModel copyWith({
    String? appName,
    String? bundleId,
    Duration? usageTime,
    String? iconData,
    String? category,
    DateTime? lastUsed,
  }) {
    return ScreenTimeModel(
      appName: appName ?? this.appName,
      bundleId: bundleId ?? this.bundleId,
      usageTime: usageTime ?? this.usageTime,
      iconData: iconData ?? this.iconData,
      category: category ?? this.category,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  @override
  String toString() {
    return 'ScreenTimeModel(appName: $appName, bundleId: $bundleId, '
        'usageTime: $formattedUsageTime, category: $category)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScreenTimeModel &&
        other.appName == appName &&
        other.bundleId == bundleId &&
        other.usageTime == usageTime &&
        other.iconData == iconData &&
        other.category == category &&
        other.lastUsed == lastUsed;
  }

  @override
  int get hashCode {
    return Object.hash(
      appName,
      bundleId,
      usageTime,
      iconData,
      category,
      lastUsed,
    );
  }
}

/// 전체 스크린타임 요약 데이터
class ScreenTimeSummary {
  final Duration totalUsageTime; // 총 사용 시간
  final List<ScreenTimeModel> appUsageList; // 앱별 사용 시간 리스트
  final DateTime dateRange; // 데이터 기준 날짜
  final int totalAppsUsed; // 사용한 앱 개수

  const ScreenTimeSummary({
    required this.totalUsageTime,
    required this.appUsageList,
    required this.dateRange,
    required this.totalAppsUsed,
  });

  /// JSON에서 ScreenTimeSummary 객체 생성
  factory ScreenTimeSummary.fromJson(Map<String, dynamic> json) {
    final appUsageListJson = json['appUsageList'] as List<dynamic>;
    final appUsageList = appUsageListJson
        .map((app) => ScreenTimeModel.fromJson(app as Map<String, dynamic>))
        .toList();

    return ScreenTimeSummary(
      totalUsageTime:
          Duration(seconds: (json['totalUsageTimeSeconds'] as num).toInt()),
      appUsageList: appUsageList,
      dateRange: DateTime.fromMillisecondsSinceEpoch(
          (json['dateRange'] as num).toInt()),
      totalAppsUsed: json['totalAppsUsed'] as int,
    );
  }

  /// ScreenTimeSummary 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'totalUsageTimeSeconds': totalUsageTime.inSeconds,
      'appUsageList': appUsageList.map((app) => app.toJson()).toList(),
      'dateRange': dateRange.millisecondsSinceEpoch,
      'totalAppsUsed': totalAppsUsed,
    };
  }

  /// 총 사용 시간을 사람이 읽기 쉬운 형태로 포맷
  String get formattedTotalUsageTime {
    final hours = totalUsageTime.inHours;
    final minutes = totalUsageTime.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}시간 ${minutes}분';
    } else {
      return '${minutes}분';
    }
  }

  /// 가장 많이 사용한 앱 (Top 5)
  List<ScreenTimeModel> get topUsedApps {
    final sortedList = List<ScreenTimeModel>.from(appUsageList);
    sortedList.sort((a, b) => b.usageTime.compareTo(a.usageTime));
    return sortedList.take(5).toList();
  }

  /// 특정 카테고리의 총 사용 시간
  Duration getCategoryUsageTime(String category) {
    final categoryApps = appUsageList.where((app) => app.category == category);
    return categoryApps.fold(
      Duration.zero,
      (total, app) => total + app.usageTime,
    );
  }

  @override
  String toString() {
    return 'ScreenTimeSummary(totalUsageTime: $formattedTotalUsageTime, '
        'totalAppsUsed: $totalAppsUsed, dateRange: $dateRange)';
  }
}
