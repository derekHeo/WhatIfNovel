import 'package:firebase_auth/firebase_auth.dart';
import './firestore_service.dart';

/// What If 버튼의 1일 1회 사용 제한을 관리하는 서비스 (사용자 ID 기반)
class WhatIfUsageManager {
  static final FirestoreService _firestoreService = FirestoreService();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 오늘 What If를 사용했는지 확인
  /// 반환값: true = 사용 가능, false = 이미 사용함
  static Future<bool> canUseToday() async {
    final user = _auth.currentUser;
    if (user == null) {
      // 로그인하지 않은 경우 사용 불가
      return false;
    }

    try {
      final lastUsageDate = await _firestoreService.getWhatIfUsageDate(user.uid);

      if (lastUsageDate == null) {
        // 한 번도 사용하지 않음
        return true;
      }

      final today = _getTodayDateString();
      // 마지막 사용 날짜가 오늘이 아니면 사용 가능
      return lastUsageDate != today;
    } catch (e) {
      // 오류 발생 시 안전하게 false 반환
      print('What If 사용 가능 여부 확인 오류: $e');
      return false;
    }
  }

  /// What If 사용 기록 저장
  static Future<void> markAsUsedToday() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }

    final today = _getTodayDateString();
    await _firestoreService.saveWhatIfUsageDate(user.uid, today);
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
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }

    await _firestoreService.resetWhatIfUsage(user.uid);
  }
}
