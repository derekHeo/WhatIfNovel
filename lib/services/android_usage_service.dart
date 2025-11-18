import 'dart:io';
import 'dart:developer' as developer;
import 'package:usage_stats/usage_stats.dart';

/// Android UsageStats API를 사용하여 앱 사용 통계를 가져오는 서비스
class AndroidUsageService {
  // 싱글톤 패턴
  static final AndroidUsageService _instance = AndroidUsageService._internal();
  factory AndroidUsageService() => _instance;
  AndroidUsageService._internal();

  /// 사용 통계 권한 확인
  Future<bool> checkUsagePermission() async {
    if (!Platform.isAndroid) return false;

    try {
      final bool hasPermission = await UsageStats.checkUsagePermission() ?? false;
      developer.log('UsageStats 권한 확인: $hasPermission', name: 'AndroidUsageService');
      return hasPermission;
    } catch (e) {
      developer.log('UsageStats 권한 확인 에러: $e', name: 'AndroidUsageService');
      return false;
    }
  }

  /// 사용 통계 권한 요청 (설정 화면으로 이동)
  Future<void> requestUsagePermission() async {
    if (!Platform.isAndroid) return;

    try {
      developer.log('UsageStats 권한 요청 시작', name: 'AndroidUsageService');
      await UsageStats.grantUsagePermission();
    } catch (e) {
      developer.log('UsageStats 권한 요청 에러: $e', name: 'AndroidUsageService');
    }
  }

  /// 특정 날짜의 총 사용 시간 가져오기 (분 단위)
  Future<int> getTotalUsageForDate(DateTime date) async {
    if (!Platform.isAndroid) return 0;

    try {
      final DateTime now = DateTime.now();
      final DateTime startDate = DateTime(date.year, date.month, date.day, 0, 0, 0);

      // 오늘 날짜면 현재 시간까지, 과거 날짜면 23:59:59까지
      final DateTime endDate;
      final bool isToday = date.year == now.year &&
                          date.month == now.month &&
                          date.day == now.day;

      if (isToday) {
        endDate = now; // 오늘은 현재 시간까지만
      } else {
        endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);
      }

      final List<UsageInfo> usageStats = await UsageStats.queryUsageStats(
        startDate,
        endDate,
      );

      int totalMinutes = 0;
      for (var usage in usageStats) {
        final totalTimeMs = int.tryParse(usage.totalTimeInForeground?.toString() ?? '0') ?? 0;
        totalMinutes += totalTimeMs ~/ 1000 ~/ 60;
      }

      developer.log(
        '날짜별 총 사용 시간: ${date.toString().substring(0, 10)} = ${totalMinutes}분 ${isToday ? "(오늘, 현재 시간까지)" : ""}',
        name: 'AndroidUsageService',
      );

      return totalMinutes;
    } catch (e) {
      developer.log('날짜별 사용 시간 조회 에러: $e', name: 'AndroidUsageService');
      return 0;
    }
  }

  /// 오늘 사용한 앱 리스트 가져오기 (사용 시간 순 정렬)
  /// [minUsageMinutes]: 최소 사용 시간 (분), 기본값 1분
  /// 반환: List<AppUsageInfo> - 앱 이름, 패키지명, 사용 시간
  Future<List<AppUsageInfo>> getTodayUsedApps({int minUsageMinutes = 1}) async {
    if (!Platform.isAndroid) return [];

    try {
      final DateTime endDate = DateTime.now();
      final DateTime startDate = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        0,
        0,
        0,
      );

      developer.log(
        '오늘 사용한 앱 조회: ${startDate.toString()} ~ ${endDate.toString()}',
        name: 'AndroidUsageService',
      );

      final List<UsageInfo> usageStats = await UsageStats.queryUsageStats(
        startDate,
        endDate,
      );

      developer.log('조회된 앱 개수: ${usageStats.length}', name: 'AndroidUsageService');

      // 앱 정보를 변환하고 필터링
      final List<AppUsageInfo> apps = [];
      final minUsageMillis = minUsageMinutes * 60 * 1000;

      for (var usage in usageStats) {
        // totalTimeInForeground는 String일 수 있으므로 int로 변환
        final totalTimeMs = int.tryParse(usage.totalTimeInForeground?.toString() ?? '0') ?? 0;
        final lastUsedMs = int.tryParse(usage.lastTimeUsed?.toString() ?? '0') ?? 0;

        // 사용 시간이 최소값 이상인 앱만 포함
        if (totalTimeMs >= minUsageMillis) {
          final appName = await _getAppName(usage.packageName ?? '');

          apps.add(AppUsageInfo(
            appName: appName,
            packageName: usage.packageName ?? '',
            usageTimeMinutes: (totalTimeMs / 1000 / 60).round(),
            usageTimeMillis: totalTimeMs,
            lastTimeUsed: lastUsedMs > 0
                ? DateTime.fromMillisecondsSinceEpoch(lastUsedMs)
                : null,
          ));
        }
      }

      // 사용 시간 순으로 내림차순 정렬
      apps.sort((a, b) => b.usageTimeMinutes.compareTo(a.usageTimeMinutes));

      developer.log(
        '필터링된 앱 개수: ${apps.length} (최소 사용 시간: ${minUsageMinutes}분)',
        name: 'AndroidUsageService',
      );

      return apps;
    } catch (e) {
      developer.log('앱 사용 통계 조회 에러: $e', name: 'AndroidUsageService');
      return [];
    }
  }

  /// 어제 사용한 앱 리스트 가져오기 (사용 시간 순 정렬)
  /// [minUsageMinutes]: 최소 사용 시간 (분), 기본값 1분
  /// 반환: List<AppUsageInfo> - 앱 이름, 패키지명, 사용 시간
  Future<List<AppUsageInfo>> getYesterdayUsedApps({int minUsageMinutes = 1}) async {
    if (!Platform.isAndroid) return [];

    try {
      // 어제 날짜 계산
      final DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));
      final DateTime startDate = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
        0,
        0,
        0,
      );
      final DateTime endDate = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
        23,
        59,
        59,
      );

      developer.log(
        '어제 사용한 앱 조회: ${startDate.toString()} ~ ${endDate.toString()}',
        name: 'AndroidUsageService',
      );

      final List<UsageInfo> usageStats = await UsageStats.queryUsageStats(
        startDate,
        endDate,
      );

      developer.log('조회된 앱 개수: ${usageStats.length}', name: 'AndroidUsageService');

      // 앱 정보를 변환하고 필터링
      final List<AppUsageInfo> apps = [];
      final minUsageMillis = minUsageMinutes * 60 * 1000;

      for (var usage in usageStats) {
        // totalTimeInForeground는 String일 수 있으므로 int로 변환
        final totalTimeMs = int.tryParse(usage.totalTimeInForeground?.toString() ?? '0') ?? 0;
        final lastUsedMs = int.tryParse(usage.lastTimeUsed?.toString() ?? '0') ?? 0;

        // 사용 시간이 최소값 이상인 앱만 포함
        if (totalTimeMs >= minUsageMillis) {
          final appName = await _getAppName(usage.packageName ?? '');

          apps.add(AppUsageInfo(
            appName: appName,
            packageName: usage.packageName ?? '',
            usageTimeMinutes: (totalTimeMs / 1000 / 60).round(),
            usageTimeMillis: totalTimeMs,
            lastTimeUsed: lastUsedMs > 0
                ? DateTime.fromMillisecondsSinceEpoch(lastUsedMs)
                : null,
          ));
        }
      }

      // 사용 시간 순으로 내림차순 정렬
      apps.sort((a, b) => b.usageTimeMinutes.compareTo(a.usageTimeMinutes));

      developer.log(
        '필터링된 앱 개수: ${apps.length} (최소 사용 시간: ${minUsageMinutes}분)',
        name: 'AndroidUsageService',
      );

      return apps;
    } catch (e) {
      developer.log('앱 사용 통계 조회 에러: $e', name: 'AndroidUsageService');
      return [];
    }
  }

  /// 특정 앱의 오늘 사용 시간 가져오기 (분 단위)
  Future<int> getAppUsageTimeToday(String packageName) async {
    if (!Platform.isAndroid) return 0;

    try {
      final DateTime endDate = DateTime.now();
      final DateTime startDate = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        0,
        0,
        0,
      );

      final List<UsageInfo> usageStats = await UsageStats.queryUsageStats(
        startDate,
        endDate,
      );

      final usage = usageStats.firstWhere(
        (u) => u.packageName == packageName,
        orElse: () => UsageInfo(
          packageName: packageName,
          totalTimeInForeground: '0',
        ),
      );

      final totalTimeMs = int.tryParse(usage.totalTimeInForeground?.toString() ?? '0') ?? 0;
      final minutes = totalTimeMs ~/ 1000 ~/ 60;

      developer.log(
        '앱 사용 시간 조회: $packageName = ${minutes}분',
        name: 'AndroidUsageService',
      );

      return minutes;
    } catch (e) {
      developer.log('앱 사용 시간 조회 에러: $e', name: 'AndroidUsageService');
      return 0;
    }
  }

  /// 특정 시간 범위의 정확한 사용 시간 가져오기 (차이 계산 방식)
  /// [startTime]: 시작 시간
  /// [endTime]: 종료 시간
  /// [packageNames]: 조회할 패키지명 리스트
  /// 반환: Map<packageName, 사용시간(분)>
  ///
  /// ⚠️ 중요: queryUsageStats의 totalTimeInForeground는 범위를 무시하고
  /// 더 넓은 기간의 누적값을 반환하는 버그가 있음.
  /// 이 메서드는 차이 계산으로 정확한 범위의 사용 시간을 구함.
  Future<Map<String, int>> getAccurateUsageTime({
    required DateTime startTime,
    required DateTime endTime,
    required List<String> packageNames,
  }) async {
    if (!Platform.isAndroid) return {};

    try {
      print('🔍 정확한 사용 시간 계산 시작');
      print('   범위: ${startTime.toString()} ~ ${endTime.toString()}');
      print('   조회할 패키지: ${packageNames.length}개');

      // 방법: startTime 이전의 누적값과 endTime의 누적값 차이를 계산
      // 1. startTime 직전(1초 전)까지의 누적 사용량 조회
      final baselineTime = startTime.subtract(const Duration(seconds: 1));
      print('📊 베이스라인 조회: ~${baselineTime.toString()}');

      final baselineStats = await UsageStats.queryUsageStats(
        DateTime(2020, 1, 1), // 충분히 과거
        baselineTime,
      );
      print('   조회된 앱 수: ${baselineStats.length}개');

      final Map<String, int> baselineMap = {};
      for (var packageName in packageNames) {
        final usage = baselineStats.firstWhere(
          (u) => u.packageName == packageName,
          orElse: () => UsageInfo(packageName: packageName, totalTimeInForeground: '0'),
        );
        final totalTimeMs = int.tryParse(usage.totalTimeInForeground?.toString() ?? '0') ?? 0;
        final minutes = totalTimeMs ~/ 1000 ~/ 60;
        baselineMap[packageName] = minutes;
        print('   📱 $packageName: ${minutes}분 (${minutes ~/ 60}h ${minutes % 60}m)');
      }

      // 2. endTime까지의 누적 사용량 조회
      print('📊 현재값 조회: ~${endTime.toString()}');

      final currentStats = await UsageStats.queryUsageStats(
        DateTime(2020, 1, 1), // 충분히 과거
        endTime,
      );
      print('   조회된 앱 수: ${currentStats.length}개');

      final Map<String, int> currentMap = {};
      for (var packageName in packageNames) {
        final usage = currentStats.firstWhere(
          (u) => u.packageName == packageName,
          orElse: () => UsageInfo(packageName: packageName, totalTimeInForeground: '0'),
        );
        final totalTimeMs = int.tryParse(usage.totalTimeInForeground?.toString() ?? '0') ?? 0;
        final minutes = totalTimeMs ~/ 1000 ~/ 60;
        currentMap[packageName] = minutes;
        print('   📱 $packageName: ${minutes}분 (${minutes ~/ 60}h ${minutes % 60}m)');
      }

      // 3. 차이 계산 (현재 - 베이스라인 = 범위 내 사용량)
      print('🧮 차이 계산 중...');
      final Map<String, int> result = {};
      for (var packageName in packageNames) {
        final baseline = baselineMap[packageName] ?? 0;
        final current = currentMap[packageName] ?? 0;
        final usage = (current - baseline).clamp(0, 999999); // 음수 방지
        result[packageName] = usage;

        print('   ✅ $packageName: baseline=${baseline}분, current=${current}분, diff=${usage}분');
      }

      print('✅ 정확한 사용 시간 계산 완료');
      return result;
    } catch (e) {
      print('❌ 정확한 사용 시간 계산 에러: $e');
      print('스택 트레이스: ${StackTrace.current}');
      return {};
    }
  }

  /// 여러 앱의 오늘 사용 시간 가져오기
  /// 반환: Map<packageName, 사용시간(분)>
  Future<Map<String, int>> getMultipleAppsUsageTime(List<String> packageNames) async {
    if (!Platform.isAndroid) return {};

    try {
      final DateTime endDate = DateTime.now();
      final DateTime startDate = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        0,
        0,
        0,
      );

      final List<UsageInfo> usageStats = await UsageStats.queryUsageStats(
        startDate,
        endDate,
      );

      final Map<String, int> result = {};

      for (var packageName in packageNames) {
        final usage = usageStats.firstWhere(
          (u) => u.packageName == packageName,
          orElse: () => UsageInfo(
            packageName: packageName,
            totalTimeInForeground: '0',
          ),
        );

        final totalTimeMs = int.tryParse(usage.totalTimeInForeground?.toString() ?? '0') ?? 0;
        result[packageName] = totalTimeMs ~/ 1000 ~/ 60;
      }

      developer.log(
        '여러 앱 사용 시간 조회: ${result.length}개 앱',
        name: 'AndroidUsageService',
      );

      return result;
    } catch (e) {
      developer.log('여러 앱 사용 시간 조회 에러: $e', name: 'AndroidUsageService');
      return {};
    }
  }

  /// 패키지명으로 앱 이름 가져오기
  /// 앱 이름을 가져올 수 없으면 패키지명 반환
  Future<String> _getAppName(String packageName) async {
    try {
      // usage_stats 패키지의 제한으로 앱 이름을 직접 가져올 수 없음
      // 패키지명을 파싱하여 간단한 이름 생성
      if (packageName.isEmpty) return 'Unknown';

      // 일반적인 앱 매핑
      final commonApps = {
        'com.instagram.android': 'Instagram',
        'com.google.android.youtube': 'YouTube',
        'com.kakao.talk': 'KakaoTalk',
        'com.facebook.katana': 'Facebook',
        'com.twitter.android': 'Twitter',
        'com.whatsapp': 'WhatsApp',
        'com.tiktok.android': 'TikTok',
        'com.netflix.mediaclient': 'Netflix',
        'com.spotify.music': 'Spotify',
        'com.discord': 'Discord',
        'com.zhiliaoapp.musically': 'TikTok',
        'com.samsung.android.messaging': 'Messages',
        'com.google.android.gm': 'Gmail',
        'com.chrome.android': 'Chrome',
      };

      if (commonApps.containsKey(packageName)) {
        return commonApps[packageName]!;
      }

      // 패키지명 파싱: com.company.appname -> Appname
      final parts = packageName.split('.');
      if (parts.isNotEmpty) {
        final appName = parts.last;
        return appName[0].toUpperCase() + appName.substring(1);
      }

      return packageName;
    } catch (e) {
      developer.log('앱 이름 조회 에러: $e', name: 'AndroidUsageService');
      return packageName;
    }
  }
}

/// 앱 사용 정보 모델
class AppUsageInfo {
  final String appName;
  final String packageName;
  final int usageTimeMinutes; // 사용 시간 (분)
  final int usageTimeMillis;  // 사용 시간 (밀리초)
  final DateTime? lastTimeUsed;

  AppUsageInfo({
    required this.appName,
    required this.packageName,
    required this.usageTimeMinutes,
    required this.usageTimeMillis,
    this.lastTimeUsed,
  });

  // 사용 시간을 "X시간 Y분" 형식으로 반환
  String get formattedUsageTime {
    final hours = usageTimeMinutes ~/ 60;
    final minutes = usageTimeMinutes % 60;

    if (hours > 0) {
      return '${hours}시간 ${minutes}분';
    } else {
      return '${minutes}분';
    }
  }

  @override
  String toString() {
    return 'AppUsageInfo(appName: $appName, packageName: $packageName, usageTime: $formattedUsageTime)';
  }
}
