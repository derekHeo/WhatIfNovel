import 'dart:io';
import 'package:flutter/material.dart';
import '../services/android_usage_service.dart';

/// 사용량 통계 제공 Provider
class UsageStatsProvider with ChangeNotifier {
  final AndroidUsageService _usageService = AndroidUsageService();

  // 일별 사용량 (최근 7일, 어제까지 - 오늘 제외)
  List<DailyUsageData> _dailyUsage = [];

  // 주간 사용량 (최근 4주)
  List<WeeklyUsageData> _weeklyUsage = [];

  // 월간 사용량 (최근 6개월)
  List<MonthlyUsageData> _monthlyUsage = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<DailyUsageData> get dailyUsage => _dailyUsage;
  List<WeeklyUsageData> get weeklyUsage => _weeklyUsage;
  List<MonthlyUsageData> get monthlyUsage => _monthlyUsage;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 모든 사용량 통계 로드
  Future<void> loadUsageStats() async {
    if (!Platform.isAndroid) {
      _errorMessage = 'Android 전용 기능입니다';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 권한 확인
      final hasPermission = await _usageService.checkUsagePermission();
      if (!hasPermission) {
        _errorMessage = '앱 사용 통계 권한이 필요합니다';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 병렬로 모든 데이터 로드
      await Future.wait([
        _loadDailyUsage(),
        _loadWeeklyUsage(),
        _loadMonthlyUsage(),
      ]);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = '데이터 로드 실패: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 일별 사용량 로드 (최근 7일, 어제까지)
  /// ⚠️ 주의: 그래프는 표시하지 않음 (Android UsageStats 부정확)
  /// AppGoalProvider의 어제 데이터만 사용
  Future<void> _loadDailyUsage() async {
    // 빈 데이터로 초기화 (그래프 숨김 용도)
    _dailyUsage = [];
  }

  /// 주간 사용량 로드 (최근 4주)
  Future<void> _loadWeeklyUsage() async {
    final now = DateTime.now();
    final List<WeeklyUsageData> weeklyData = [];

    for (int i = 3; i >= 0; i--) {
      // 각 주의 시작일 (월요일 기준)
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + (i * 7)));
      final weekEnd = weekStart.add(const Duration(days: 6));

      try {
        // 해당 주의 일별 데이터를 합산
        int totalMinutes = 0;

        for (int day = 0; day < 7; day++) {
          final date = weekStart.add(Duration(days: day));
          // 미래 날짜는 제외
          if (date.isAfter(now)) continue;

          final dayMinutes = await _usageService.getTotalUsageForDate(date);
          totalMinutes += dayMinutes;
        }

        weeklyData.add(WeeklyUsageData(
          weekStart: weekStart,
          weekEnd: weekEnd,
          totalMinutes: totalMinutes,
          weekLabel: '${weekStart.month}/${weekStart.day}',
        ));
      } catch (e) {
        // 에러 발생 시 0으로 추가
        weeklyData.add(WeeklyUsageData(
          weekStart: weekStart,
          weekEnd: weekEnd,
          totalMinutes: 0,
          weekLabel: '${weekStart.month}/${weekStart.day}',
        ));
      }
    }

    _weeklyUsage = weeklyData;
  }

  /// 월간 사용량 로드 (최근 6개월)
  Future<void> _loadMonthlyUsage() async {
    final now = DateTime.now();
    final List<MonthlyUsageData> monthlyData = [];

    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);

      try {
        // 해당 월의 모든 일자의 데이터를 합산
        int totalMinutes = 0;

        // 해당 월의 마지막 날 계산
        final nextMonth = DateTime(monthDate.year, monthDate.month + 1, 1);
        final lastDayOfMonth = nextMonth.subtract(const Duration(days: 1));

        // 각 날짜별로 데이터 가져와서 합산
        for (int day = 1; day <= lastDayOfMonth.day; day++) {
          final date = DateTime(monthDate.year, monthDate.month, day);
          // 미래 날짜는 제외
          if (date.isAfter(now)) break;

          final dayMinutes = await _usageService.getTotalUsageForDate(date);
          totalMinutes += dayMinutes;
        }

        monthlyData.add(MonthlyUsageData(
          month: monthDate,
          totalMinutes: totalMinutes,
          monthLabel: '${monthDate.month}월',
        ));
      } catch (e) {
        // 에러 발생 시 0으로 추가
        monthlyData.add(MonthlyUsageData(
          month: monthDate,
          totalMinutes: 0,
          monthLabel: '${monthDate.month}월',
        ));
      }
    }

    _monthlyUsage = monthlyData;
  }

  /// 요일 라벨 생성
  String _getDayLabel(DateTime date) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[date.weekday - 1];
  }

  /// 동기부여 멘트 생성
  /// ⚠️ 오늘 데이터가 제외되어 있으므로 마지막 = 어제
  String getMotivationMessage() {
    if (_dailyUsage.isEmpty || _dailyUsage.length < 3) {
      return '데이터를 수집하고 있습니다';
    }

    // 최근 3일 데이터 (모두 과거 데이터)
    final recent3Days = _dailyUsage.sublist(_dailyUsage.length - 3);
    final lastDayUsage = recent3Days.last.totalMinutes;

    // 최근 3일 중 최대/최소
    int maxUsage = recent3Days.map((d) => d.totalMinutes).reduce((a, b) => a > b ? a : b);
    int minUsage = recent3Days.map((d) => d.totalMinutes).reduce((a, b) => a < b ? a : b);

    // 마지막 날(어제)이 최대인지 최소인지 확인
    if (lastDayUsage == maxUsage && lastDayUsage != minUsage) {
      return '최근 3일 중 가장 많이 사용하셨습니다 📈';
    } else if (lastDayUsage == minUsage && lastDayUsage != maxUsage) {
      return '최근 3일 중 가장 적게 사용하셨습니다! 👏';
    } else if (lastDayUsage == maxUsage && lastDayUsage == minUsage) {
      return '최근 3일간 비슷한 사용 패턴입니다';
    } else {
      // 평균과 비교
      final avgUsage = recent3Days.map((d) => d.totalMinutes).reduce((a, b) => a + b) / 3;
      if (lastDayUsage > avgUsage) {
        return '평균보다 ${((lastDayUsage - avgUsage) / 60).toStringAsFixed(1)}시간 더 사용했습니다';
      } else {
        return '평균보다 ${((avgUsage - lastDayUsage) / 60).toStringAsFixed(1)}시간 덜 사용했습니다!';
      }
    }
  }

  /// 어제 총 사용 시간 (시간:분 형식)
  /// ⚠️ 오늘 데이터는 제외되므로 마지막 = 어제
  String getTodayTotalFormatted() {
    if (_dailyUsage.isEmpty) return '0시간 0분';

    final yesterdayMinutes = _dailyUsage.last.totalMinutes;
    final hours = yesterdayMinutes ~/ 60;
    final minutes = yesterdayMinutes % 60;

    return '$hours시간 $minutes분';
  }

  /// 주간 평균 사용 시간
  String getWeeklyAverageFormatted() {
    if (_dailyUsage.isEmpty) return '0시간 0분';

    final total = _dailyUsage.map((d) => d.totalMinutes).reduce((a, b) => a + b);
    final avgMinutes = total ~/ _dailyUsage.length;
    final hours = avgMinutes ~/ 60;
    final minutes = avgMinutes % 60;

    return '$hours시간 $minutes분';
  }

  /// 수동으로 새로고침
  Future<void> refresh() async {
    await loadUsageStats();
  }
}

/// 일별 사용량 데이터
class DailyUsageData {
  final DateTime date;
  final int totalMinutes;
  final String dayLabel;

  DailyUsageData({
    required this.date,
    required this.totalMinutes,
    required this.dayLabel,
  });

  double get hours => totalMinutes / 60.0;
}

/// 주간 사용량 데이터
class WeeklyUsageData {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int totalMinutes;
  final String weekLabel;

  WeeklyUsageData({
    required this.weekStart,
    required this.weekEnd,
    required this.totalMinutes,
    required this.weekLabel,
  });

  double get hours => totalMinutes / 60.0;
}

/// 월간 사용량 데이터
class MonthlyUsageData {
  final DateTime month;
  final int totalMinutes;
  final String monthLabel;

  MonthlyUsageData({
    required this.month,
    required this.totalMinutes,
    required this.monthLabel,
  });

  double get hours => totalMinutes / 60.0;
}
