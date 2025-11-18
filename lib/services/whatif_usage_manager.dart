import 'package:shared_preferences/shared_preferences.dart';

/// What If 버튼의 1일 1회 사용 제한을 관리하는 서비스
class WhatIfUsageManager {
  static const String _lastUsageDateKey = 'whatif_last_usage_date';

  /// 오늘 What If를 사용했는지 확인
  /// 반환값: true = 사용 가능, false = 이미 사용함
  static Future<bool> canUseToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastUsageDate = prefs.getString(_lastUsageDateKey);

    if (lastUsageDate == null) {
      // 한 번도 사용하지 않음
      return true;
    }

    final today = _getTodayDateString();
    // 마지막 사용 날짜가 오늘이 아니면 사용 가능
    return lastUsageDate != today;
  }

  /// What If 사용 기록 저장
  static Future<void> markAsUsedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayDateString();
    await prefs.setString(_lastUsageDateKey, today);
  }

  /// 다음 00시까지 남은 시간 (분 단위)
  static int getMinutesUntilMidnight() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1); // 다음 날 00시
    final difference = tomorrow.difference(now);
    return difference.inMinutes;
  }

  /// 다음 00시까지 남은 시간을 읽기 쉬운 형식으로 반환
  /// 예: "5시간 30분", "45분", "1시간"
  static String getTimeUntilMidnightFormatted() {
    final minutesLeft = getMinutesUntilMidnight();
    final hours = minutesLeft ~/ 60;
    final minutes = minutesLeft % 60;

    if (hours > 0 && minutes > 0) {
      return '$hours시간 $minutes분';
    } else if (hours > 0) {
      return '$hours시간';
    } else {
      return '$minutes분';
    }
  }

  /// 오늘 날짜를 'yyyy-MM-dd' 형식의 문자열로 반환
  static String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 테스트/디버깅용: 사용 기록 초기화
  static Future<void> resetUsage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastUsageDateKey);
  }
}
