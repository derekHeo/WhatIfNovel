import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:novel_diary/models/screen_time_model.dart';

/// iOS와 통신하여 스크린타임 데이터를 가져오는 서비스
class ScreenTimeService {
  // MethodChannel 이름 (iOS와 동일하게 설정)
  static const MethodChannel _channel = MethodChannel('com.yourapp.screentime');

  // 싱글톤 패턴
  static final ScreenTimeService _instance = ScreenTimeService._internal();
  factory ScreenTimeService() => _instance;
  ScreenTimeService._internal();

  /// 스크린타임 권한 요청
  /// iOS에서 Screen Time API 사용 권한을 요청합니다
  Future<bool> requestScreenTimePermission() async {
    try {
      developer.log('스크린타임 권한 요청 시작', name: 'ScreenTimeService');

      final bool hasPermission =
          await _channel.invokeMethod('requestPermission');

      developer.log('스크린타임 권한 결과: $hasPermission', name: 'ScreenTimeService');
      return hasPermission;
    } on PlatformException catch (e) {
      developer.log('권한 요청 실패: ${e.message}', name: 'ScreenTimeService');
      return false;
    } catch (e) {
      developer.log('권한 요청 에러: $e', name: 'ScreenTimeService');
      return false;
    }
  }

  /// 스크린타임 권한 상태 확인
  Future<bool> checkScreenTimePermission() async {
    try {
      final bool hasPermission = await _channel.invokeMethod('checkPermission');
      return hasPermission;
    } on PlatformException catch (e) {
      developer.log('권한 확인 실패: ${e.message}', name: 'ScreenTimeService');
      return false;
    } catch (e) {
      developer.log('권한 확인 에러: $e', name: 'ScreenTimeService');
      return false;
    }
  }

  /// 오늘의 스크린타임 데이터 가져오기
  Future<ScreenTimeSummary?> getTodayScreenTime() async {
    try {
      developer.log('오늘의 스크린타임 데이터 요청', name: 'ScreenTimeService');

      final String? result = await _channel.invokeMethod('getTodayScreenTime');

      if (result == null) {
        developer.log('스크린타임 데이터가 null입니다', name: 'ScreenTimeService');
        return null;
      }

      final Map<String, dynamic> jsonData = json.decode(result);
      final summary = ScreenTimeSummary.fromJson(jsonData);

      developer.log('스크린타임 데이터 파싱 완료: ${summary.appUsageList.length}개 앱',
          name: 'ScreenTimeService');

      return summary;
    } on PlatformException catch (e) {
      developer.log('스크린타임 데이터 가져오기 실패: ${e.message}',
          name: 'ScreenTimeService');
      return null;
    } catch (e) {
      developer.log('스크린타임 데이터 파싱 에러: $e', name: 'ScreenTimeService');
      return null;
    }
  }

  /// 특정 날짜의 스크린타임 데이터 가져오기
  Future<ScreenTimeSummary?> getScreenTimeForDate(DateTime date) async {
    try {
      developer.log('특정 날짜 스크린타임 데이터 요청: ${date.toString()}',
          name: 'ScreenTimeService');

      final String? result =
          await _channel.invokeMethod('getScreenTimeForDate', {
        'date': date.millisecondsSinceEpoch,
      });

      if (result == null) {
        developer.log('해당 날짜의 스크린타임 데이터가 없습니다', name: 'ScreenTimeService');
        return null;
      }

      final Map<String, dynamic> jsonData = json.decode(result);
      return ScreenTimeSummary.fromJson(jsonData);
    } on PlatformException catch (e) {
      developer.log('특정 날짜 스크린타임 데이터 가져오기 실패: ${e.message}',
          name: 'ScreenTimeService');
      return null;
    } catch (e) {
      developer.log('특정 날짜 스크린타임 데이터 파싱 에러: $e', name: 'ScreenTimeService');
      return null;
    }
  }

  /// 특정 기간의 스크린타임 데이터 가져오기
  Future<List<ScreenTimeSummary>> getScreenTimeForDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      developer.log(
          '기간별 스크린타임 데이터 요청: ${startDate.toString()} ~ ${endDate.toString()}',
          name: 'ScreenTimeService');

      final String? result =
          await _channel.invokeMethod('getScreenTimeForDateRange', {
        'startDate': startDate.millisecondsSinceEpoch,
        'endDate': endDate.millisecondsSinceEpoch,
      });

      if (result == null) {
        developer.log('해당 기간의 스크린타임 데이터가 없습니다', name: 'ScreenTimeService');
        return [];
      }

      final List<dynamic> jsonList = json.decode(result);
      final summaries = jsonList
          .map((json) =>
              ScreenTimeSummary.fromJson(json as Map<String, dynamic>))
          .toList();

      developer.log('기간별 스크린타임 데이터 파싱 완료: ${summaries.length}일',
          name: 'ScreenTimeService');

      return summaries;
    } on PlatformException catch (e) {
      developer.log('기간별 스크린타임 데이터 가져오기 실패: ${e.message}',
          name: 'ScreenTimeService');
      return [];
    } catch (e) {
      developer.log('기간별 스크린타임 데이터 파싱 에러: $e', name: 'ScreenTimeService');
      return [];
    }
  }

  /// 특정 앱의 사용 시간 가져오기
  Future<ScreenTimeModel?> getAppScreenTime(String bundleId) async {
    try {
      developer.log('특정 앱 스크린타임 데이터 요청: $bundleId', name: 'ScreenTimeService');

      final String? result = await _channel.invokeMethod('getAppScreenTime', {
        'bundleId': bundleId,
      });

      if (result == null) {
        developer.log('해당 앱의 스크린타임 데이터가 없습니다', name: 'ScreenTimeService');
        return null;
      }

      final Map<String, dynamic> jsonData = json.decode(result);
      return ScreenTimeModel.fromJson(jsonData);
    } on PlatformException catch (e) {
      developer.log('특정 앱 스크린타임 데이터 가져오기 실패: ${e.message}',
          name: 'ScreenTimeService');
      return null;
    } catch (e) {
      developer.log('특정 앱 스크린타임 데이터 파싱 에러: $e', name: 'ScreenTimeService');
      return null;
    }
  }

  /// 주간 스크린타임 데이터 가져오기 (최근 7일)
  Future<List<ScreenTimeSummary>> getWeeklyScreenTime() async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 6));

    return await getScreenTimeForDateRange(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// 월간 스크린타임 데이터 가져오기 (최근 30일)
  Future<List<ScreenTimeSummary>> getMonthlyScreenTime() async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 29));

    return await getScreenTimeForDateRange(
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// 스크린타임 데이터 새로고침
  /// iOS에서 최신 데이터를 다시 읽어옵니다
  Future<bool> refreshScreenTimeData() async {
    try {
      developer.log('스크린타임 데이터 새로고침 요청', name: 'ScreenTimeService');

      final bool success = await _channel.invokeMethod('refreshData');

      developer.log('스크린타임 데이터 새로고침 결과: $success', name: 'ScreenTimeService');
      return success;
    } on PlatformException catch (e) {
      developer.log('스크린타임 데이터 새로고침 실패: ${e.message}',
          name: 'ScreenTimeService');
      return false;
    } catch (e) {
      developer.log('스크린타임 데이터 새로고침 에러: $e', name: 'ScreenTimeService');
      return false;
    }
  }

  /// 서비스 상태 확인
  /// iOS에서 Screen Time API 사용 가능 여부 확인
  Future<bool> isScreenTimeAvailable() async {
    try {
      final bool isAvailable =
          await _channel.invokeMethod('isScreenTimeAvailable');
      return isAvailable;
    } on PlatformException catch (e) {
      developer.log('스크린타임 사용 가능 여부 확인 실패: ${e.message}',
          name: 'ScreenTimeService');
      return false;
    } catch (e) {
      developer.log('스크린타임 사용 가능 여부 확인 에러: $e', name: 'ScreenTimeService');
      return false;
    }
  }

  /// 디바이스 정보 가져오기
  Future<Map<String, dynamic>?> getDeviceInfo() async {
    try {
      final String? result = await _channel.invokeMethod('getDeviceInfo');

      if (result == null) return null;

      return json.decode(result) as Map<String, dynamic>;
    } on PlatformException catch (e) {
      developer.log('디바이스 정보 가져오기 실패: ${e.message}', name: 'ScreenTimeService');
      return null;
    } catch (e) {
      developer.log('디바이스 정보 가져오기 에러: $e', name: 'ScreenTimeService');
      return null;
    }
  }
}

/// 스크린타임 서비스 에러 타입
enum ScreenTimeError {
  permissionDenied,
  dataNotAvailable,
  networkError,
  unknownError,
}

/// 스크린타임 서비스 예외 클래스
class ScreenTimeException implements Exception {
  final ScreenTimeError type;
  final String message;
  final dynamic originalError;

  const ScreenTimeException({
    required this.type,
    required this.message,
    this.originalError,
  });

  @override
  String toString() {
    return 'ScreenTimeException: $message (Type: $type)';
  }
}
