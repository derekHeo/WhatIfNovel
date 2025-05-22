import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:novel_diary/models/screen_time_model.dart';
import 'package:novel_diary/services/screen_time_services.dart';

/// 스크린타임 데이터 상태 관리 Provider
class ScreenTimeProvider extends ChangeNotifier {
  final ScreenTimeService _screenTimeService = ScreenTimeService();

  // === 상태 변수들 ===

  // 개발/테스트 모드 (실제 배포시 false로 변경)
  static const bool _isDemoMode = true;

  // 로딩 상태
  bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isPermissionLoading = false;

  // 권한 상태
  bool _hasPermission = false;
  bool _isScreenTimeAvailable = false;

  // 에러 상태
  String? _errorMessage;
  ScreenTimeError? _lastError;

  // 스크린타임 데이터
  ScreenTimeSummary? _todayData;
  List<ScreenTimeSummary> _weeklyData = [];
  List<ScreenTimeSummary> _monthlyData = [];
  Map<String, ScreenTimeModel> _appData = {};

  // 설정
  bool _autoRefresh = true;
  Timer? _autoRefreshTimer;

  // === Getters ===

  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get isPermissionLoading => _isPermissionLoading;
  bool get hasPermission => _hasPermission;
  bool get isScreenTimeAvailable => _isScreenTimeAvailable;
  String? get errorMessage => _errorMessage;
  ScreenTimeError? get lastError => _lastError;
  ScreenTimeSummary? get todayData => _todayData;
  List<ScreenTimeSummary> get weeklyData => _weeklyData;
  List<ScreenTimeSummary> get monthlyData => _monthlyData;
  Map<String, ScreenTimeModel> get appData => _appData;
  bool get autoRefresh => _autoRefresh;

  // 계산된 값들
  bool get hasData => _todayData != null;
  bool get hasError => _errorMessage != null;
  String get todayFormattedTime => _todayData?.formattedTotalUsageTime ?? '0분';
  List<ScreenTimeModel> get topAppsToday => _todayData?.topUsedApps ?? [];
  int get totalAppsUsedToday => _todayData?.totalAppsUsed ?? 0;

  // === 초기화 ===

  ScreenTimeProvider() {
    _initialize();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    developer.log('ScreenTimeProvider 초기화 시작', name: 'ScreenTimeProvider');

    _setLoading(true);
    _clearError();

    try {
      if (_isDemoMode) {
        // 데모 모드: 가짜 데이터로 테스트
        developer.log('데모 모드로 실행 중', name: 'ScreenTimeProvider');
        _isScreenTimeAvailable = true;
        _hasPermission = true;
        await _loadDemoData();
        _startAutoRefresh();
      } else {
        // 실제 모드: iOS API 사용
        _isScreenTimeAvailable =
            await _screenTimeService.isScreenTimeAvailable();

        if (_isScreenTimeAvailable) {
          await checkPermission();

          if (_hasPermission) {
            await loadTodayData();
            _startAutoRefresh();
          }
        } else {
          _setError('이 기기에서는 스크린타임 기능을 사용할 수 없습니다.',
              ScreenTimeError.dataNotAvailable);
        }
      }
    } catch (e) {
      _setError('초기화 중 오류가 발생했습니다: $e', ScreenTimeError.unknownError);
    } finally {
      _setLoading(false);
    }

    developer.log('ScreenTimeProvider 초기화 완료', name: 'ScreenTimeProvider');
  }

  // === 권한 관리 ===

  /// 스크린타임 권한 상태 확인
  Future<void> checkPermission() async {
    _setPermissionLoading(true);

    try {
      _hasPermission = await _screenTimeService.checkScreenTimePermission();
      developer.log('권한 상태: $_hasPermission', name: 'ScreenTimeProvider');
      notifyListeners();
    } catch (e) {
      _setError('권한 확인 중 오류가 발생했습니다: $e', ScreenTimeError.unknownError);
    } finally {
      _setPermissionLoading(false);
    }
  }

  /// 스크린타임 권한 요청
  Future<bool> requestPermission() async {
    _setPermissionLoading(true);
    _clearError();

    try {
      _hasPermission = await _screenTimeService.requestScreenTimePermission();

      if (_hasPermission) {
        // 권한을 받았으면 데이터 로드
        await loadTodayData();
        _startAutoRefresh();
      } else {
        _setError('스크린타임 권한이 거부되었습니다.', ScreenTimeError.permissionDenied);
      }

      notifyListeners();
      return _hasPermission;
    } catch (e) {
      _setError('권한 요청 중 오류가 발생했습니다: $e', ScreenTimeError.unknownError);
      return false;
    } finally {
      _setPermissionLoading(false);
    }
  }

  // === 데이터 로딩 ===

  /// 오늘의 스크린타임 데이터 로드
  Future<void> loadTodayData() async {
    if (!_hasPermission) return;

    _setLoading(true);
    _clearError();

    try {
      if (_isDemoMode) {
        // 데모 모드에서는 가짜 데이터 로드
        await _loadDemoData();
      } else {
        // 실제 모드에서는 서비스 호출
        _todayData = await _screenTimeService.getTodayScreenTime();

        if (_todayData == null) {
          _setError(
              '오늘의 스크린타임 데이터를 찾을 수 없습니다.', ScreenTimeError.dataNotAvailable);
        } else {
          developer.log('오늘 데이터 로드 완료: ${_todayData!.appUsageList.length}개 앱',
              name: 'ScreenTimeProvider');
        }
      }

      notifyListeners();
    } catch (e) {
      _setError('오늘 데이터 로드 중 오류가 발생했습니다: $e', ScreenTimeError.unknownError);
    } finally {
      _setLoading(false);
    }
  }

  /// 주간 스크린타임 데이터 로드
  Future<void> loadWeeklyData() async {
    if (!_hasPermission) return;

    _setLoading(true);
    _clearError();

    try {
      _weeklyData = await _screenTimeService.getWeeklyScreenTime();

      developer.log('주간 데이터 로드 완료: ${_weeklyData.length}일',
          name: 'ScreenTimeProvider');

      notifyListeners();
    } catch (e) {
      _setError('주간 데이터 로드 중 오류가 발생했습니다: $e', ScreenTimeError.unknownError);
    } finally {
      _setLoading(false);
    }
  }

  /// 월간 스크린타임 데이터 로드
  Future<void> loadMonthlyData() async {
    if (!_hasPermission) return;

    _setLoading(true);
    _clearError();

    try {
      _monthlyData = await _screenTimeService.getMonthlyScreenTime();

      developer.log('월간 데이터 로드 완료: ${_monthlyData.length}일',
          name: 'ScreenTimeProvider');

      notifyListeners();
    } catch (e) {
      _setError('월간 데이터 로드 중 오류가 발생했습니다: $e', ScreenTimeError.unknownError);
    } finally {
      _setLoading(false);
    }
  }

  /// 특정 앱 데이터 로드
  Future<void> loadAppData(String bundleId) async {
    if (!_hasPermission) return;

    try {
      final appData = await _screenTimeService.getAppScreenTime(bundleId);

      if (appData != null) {
        _appData[bundleId] = appData;
        notifyListeners();
      }
    } catch (e) {
      developer.log('앱 데이터 로드 실패 ($bundleId): $e', name: 'ScreenTimeProvider');
    }
  }

  /// 모든 데이터 새로고침
  Future<void> refreshAllData() async {
    if (!_hasPermission) return;

    _setRefreshing(true);
    _clearError();

    try {
      if (_isDemoMode) {
        // 데모 모드에서는 가짜 새로고침 (0.5초 대기)
        await Future.delayed(const Duration(milliseconds: 500));
        await _loadDemoData();
        developer.log('데모 데이터 새로고침 완료', name: 'ScreenTimeProvider');
      } else {
        // 실제 모드에서는 iOS에서 데이터 새로고침 요청
        await _screenTimeService.refreshScreenTimeData();

        // 모든 데이터 다시 로드
        await Future.wait([
          loadTodayData(),
          loadWeeklyData(),
          loadMonthlyData(),
        ]);

        developer.log('모든 데이터 새로고침 완료', name: 'ScreenTimeProvider');
      }
    } catch (e) {
      _setError('데이터 새로고침 중 오류가 발생했습니다: $e', ScreenTimeError.unknownError);
    } finally {
      _setRefreshing(false);
    }
  }

  // === 자동 새로고침 ===

  /// 자동 새로고침 시작 (5분마다)
  void _startAutoRefresh() {
    if (!_autoRefresh) return;

    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      developer.log('자동 새로고침 실행', name: 'ScreenTimeProvider');
      loadTodayData();
    });
  }

  /// 자동 새로고침 설정 변경
  void setAutoRefresh(bool enabled) {
    _autoRefresh = enabled;

    if (_autoRefresh && _hasPermission) {
      _startAutoRefresh();
    } else {
      _autoRefreshTimer?.cancel();
    }

    notifyListeners();
  }

  // === 유틸리티 메서드 ===

  /// 특정 날짜의 데이터 가져오기
  Future<ScreenTimeSummary?> getDataForDate(DateTime date) async {
    if (!_hasPermission) return null;

    try {
      return await _screenTimeService.getScreenTimeForDate(date);
    } catch (e) {
      developer.log('특정 날짜 데이터 가져오기 실패: $e', name: 'ScreenTimeProvider');
      return null;
    }
  }

  /// 주간 평균 사용시간 계산
  Duration get weeklyAverageUsageTime {
    if (_weeklyData.isEmpty) return Duration.zero;

    final totalTime = _weeklyData.fold<Duration>(
      Duration.zero,
      (total, summary) => total + summary.totalUsageTime,
    );

    return Duration(seconds: totalTime.inSeconds ~/ _weeklyData.length);
  }

  /// 어제와 비교한 오늘 사용시간 변화
  Future<Duration?> getTodayVsYesterdayDifference() async {
    if (_todayData == null) return null;

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayData = await getDataForDate(yesterday);

    if (yesterdayData == null) return null;

    return _todayData!.totalUsageTime - yesterdayData.totalUsageTime;
  }

  // === 상태 관리 헬퍼 메서드 ===

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setRefreshing(bool refreshing) {
    _isRefreshing = refreshing;
    notifyListeners();
  }

  void _setPermissionLoading(bool loading) {
    _isPermissionLoading = loading;
    notifyListeners();
  }

  void _setError(String message, ScreenTimeError type) {
    _errorMessage = message;
    _lastError = type;
    developer.log('에러 발생: $message', name: 'ScreenTimeProvider');
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    _lastError = null;
  }

  /// 에러 메시지 클리어
  void clearError() {
    _clearError();
    notifyListeners();
  }

  void clearData() {
    _todayData = null;
    _weeklyData.clear();
    _monthlyData.clear();
    _appData.clear();
    notifyListeners();
  }

  // === 데모 모드 관련 메서드 ===

  /// 데모용 가짜 데이터 로드
  Future<void> _loadDemoData() async {
    developer.log('데모 데이터 로드 시작', name: 'ScreenTimeProvider');

    // 가짜 앱 데이터 생성
    final demoApps = [
      ScreenTimeModel(
        appName: 'Instagram',
        bundleId: 'com.instagram.app',
        usageTime: const Duration(hours: 2, minutes: 30),
        category: '소셜 네트워킹',
      ),
      ScreenTimeModel(
        appName: 'YouTube',
        bundleId: 'com.google.ios.youtube',
        usageTime: const Duration(hours: 1, minutes: 45),
        category: '엔터테인먼트',
      ),
      ScreenTimeModel(
        appName: 'Safari',
        bundleId: 'com.apple.mobilesafari',
        usageTime: const Duration(hours: 1, minutes: 20),
        category: '웹 브라우저',
      ),
      ScreenTimeModel(
        appName: 'TikTok',
        bundleId: 'com.zhiliaoapp.musically',
        usageTime: const Duration(minutes: 55),
        category: '소셜 네트워킹',
      ),
      ScreenTimeModel(
        appName: 'KakaoTalk',
        bundleId: 'com.kakao.talk',
        usageTime: const Duration(minutes: 40),
        category: '소셜 네트워킹',
      ),
    ];

    // 총 사용시간 계산
    final totalTime = demoApps.fold<Duration>(
      Duration.zero,
      (total, app) => total + app.usageTime,
    );

    // 가짜 요약 데이터 생성
    _todayData = ScreenTimeSummary(
      totalUsageTime: totalTime,
      appUsageList: demoApps,
      dateRange: DateTime.now(),
      totalAppsUsed: demoApps.length,
    );

    developer.log(
        '데모 데이터 로드 완료: ${demoApps.length}개 앱, 총 ${totalTime.inHours}시간 ${totalTime.inMinutes.remainder(60)}분',
        name: 'ScreenTimeProvider');

    notifyListeners();
  }

  /// 데모 모드 토글 (개발용)
  void toggleDemoMode() {
    // 실제 앱에서는 이 메서드를 제거하거나 디버그 모드에서만 사용
    if (_isDemoMode) {
      // 데모 데이터 클리어하고 실제 모드로 전환
      clearData();
      _hasPermission = false;
      _isScreenTimeAvailable = false;
    } else {
      // 데모 모드로 전환
      _hasPermission = true;
      _isScreenTimeAvailable = true;
      _loadDemoData();
    }
    notifyListeners();
  }
}
