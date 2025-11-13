// providers/app_goal_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:usage_stats/usage_stats.dart';
import '../models/app_goal_model.dart';
import '../services/android_usage_service.dart';

class AppGoalProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;

  // 초기 기본 데이터 (Firestore에 데이터가 없을 때 빈 리스트로 시작)
  List<AppGoal> _goals = [];

  // 마지막 동기화 날짜 (날짜 변경 감지용)
  DateTime? _lastSyncDate;

  List<AppGoal> get goals => _goals;
  bool get isLoading => _isLoading;
  DateTime? get lastSyncDate => _lastSyncDate;

  // 생성자에서 Firestore 데이터 로드
  AppGoalProvider() {
    _loadGoals();
  }

  /// Firestore에서 목표 데이터 로드
  Future<void> _loadGoals() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('목표 로드: 로그인된 사용자가 없습니다.');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore
          .collection('app_goals')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        // 목표 데이터 로드
        if (data['goals'] != null) {
          final List<dynamic> goalsData = data['goals'] as List<dynamic>;
          _goals = goalsData
              .map((goalMap) => AppGoal.fromMap(goalMap as Map<String, dynamic>))
              .toList();
          print('목표 로드 성공: ${_goals.length}개');
        }

        // 마지막 동기화 날짜 로드
        if (data['lastSyncDate'] != null) {
          _lastSyncDate = (data['lastSyncDate'] as Timestamp).toDate();
          print('마지막 동기화 날짜: ${_lastSyncDate.toString().substring(0, 10)}');
        }
      } else {
        print('목표 데이터 없음, 기본값 사용');
      }
    } catch (e) {
      print('목표 로드 에러: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Firestore에 목표 데이터 저장
  Future<void> _saveGoals() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('목표 저장: 로그인된 사용자가 없습니다.');
      return;
    }

    try {
      final goalsData = _goals.map((goal) => goal.toMap()).toList();
      final dataToSave = {
        'goals': goalsData,
        if (_lastSyncDate != null) 'lastSyncDate': Timestamp.fromDate(_lastSyncDate!),
      };

      await _firestore
          .collection('app_goals')
          .doc(user.uid)
          .set(dataToSave, SetOptions(merge: true));
      print('목표 저장 완료 (lastSyncDate: ${_lastSyncDate?.toString().substring(0, 10)})');
    } catch (e) {
      print('목표 저장 에러: $e');
      throw Exception('목표 저장에 실패했습니다.');
    }
  }

  // 특정 앱의 목표 시간을 업데이트하는 함수
  Future<void> updateGoal(String appName, int newHours, int newMinutes) async {
    final index = _goals.indexWhere((goal) => goal.name == appName);
    if (index != -1) {
      _goals[index].goalHours = newHours;
      _goals[index].goalMinutes = newMinutes;
      notifyListeners(); // 변경 사항을 모든 리스너에게 알림
      await _saveGoals(); // Firestore에 저장
    }
  }

  // 특정 앱의 실제 사용 시간을 업데이트하는 함수
  Future<void> updateUsage(String appName, double newUsageHours, int newUsageMinutes) async {
    final index = _goals.indexWhere((goal) => goal.name == appName);
    if (index != -1) {
      _goals[index].usageHours = newUsageHours;
      _goals[index].usageMinutes = newUsageMinutes;
      notifyListeners();
      await _saveGoals(); // Firestore에 저장
    }
  }

  /// 로그인 후 목표를 다시 로드하는 메서드
  Future<void> reloadGoals() async {
    await _loadGoals();
  }

  /// 모든 사용 시간 초기화 (목표 변경 시 사용)
  Future<void> resetAllUsage() async {
    for (var goal in _goals) {
      goal.usageHours = 0.0;
      goal.usageMinutes = 0;
    }
    notifyListeners();
    await _saveGoals();
    print('사용 시간 초기화 완료');
  }

  // 전체 사용 시간 합계 계산 (시간 단위)
  double getTotalUsageHours() {
    double total = 0;
    for (var goal in _goals) {
      total += goal.usageHours + (goal.usageMinutes / 60.0);
    }
    return total;
  }

  // 전체 사용 시간을 "X시간 Y분" 형식으로 반환
  String getTotalUsageFormatted() {
    double totalHours = getTotalUsageHours();
    int hours = totalHours.floor();
    int minutes = ((totalHours - hours) * 60).round();
    return '$hours시간 $minutes분';
  }

  /// 새로운 앱 추가 (사용자 커스텀 앱명)
  Future<void> addApp(String appName) async {
    // 중복 체크
    if (_goals.any((goal) => goal.name.toLowerCase() == appName.toLowerCase())) {
      throw Exception('이미 등록된 앱입니다.');
    }

    final newGoal = AppGoal(
      name: appName,
      imagePath: 'assets/images/default_app.png', // 기본 아이콘
      goalHours: 1,
      goalMinutes: 0,
      usageHours: 0.0,
      usageMinutes: 0,
    );

    _goals.add(newGoal);
    notifyListeners();
    await _saveGoals();
    print('앱 추가 완료: $appName');
  }

  /// 패키지명과 함께 앱 추가 (Android UsageStats용)
  Future<void> addAppWithPackageName({
    required String appName,
    required String packageName,
  }) async {
    // 패키지명으로 중복 체크
    if (_goals.any((goal) => goal.packageName == packageName)) {
      throw Exception('이미 등록된 앱입니다.');
    }

    final newGoal = AppGoal(
      name: appName,
      imagePath: 'assets/images/default_app.png', // 기본 아이콘
      packageName: packageName,
      goalHours: 1,
      goalMinutes: 0,
      usageHours: 0.0,
      usageMinutes: 0,
    );

    _goals.add(newGoal);
    notifyListeners();
    await _saveGoals();
    print('앱 추가 완료: $appName ($packageName)');
  }

  /// 앱 삭제
  Future<void> deleteApp(String appName) async {
    _goals.removeWhere((goal) => goal.name == appName);
    notifyListeners();
    await _saveGoals();
    print('앱 삭제 완료: $appName');
  }

  /// UsageStats 동기화 (00:00 기준, 날짜 변경 감지 포함)
  /// 1. 날짜가 바뀌었으면 오늘→어제로 데이터 이동
  /// 2. 오늘/어제 사용량 새로 조회
  Future<void> syncAllUsageData() async {
    // Android가 아니면 스킵
    if (!Platform.isAndroid) {
      print('Android가 아니므로 UsageStats 동기화 스킵');
      return;
    }

    try {
      final usageService = AndroidUsageService();

      // 권한 확인
      final hasPermission = await usageService.checkUsagePermission();
      if (!hasPermission) {
        print('UsageStats 권한이 없습니다');
        return;
      }

      // 패키지명이 있는 앱들
      final packageNames = _goals
          .where((g) => g.packageName != null && g.packageName!.isNotEmpty)
          .map((g) => g.packageName!)
          .toList();

      if (packageNames.isEmpty) {
        print('패키지명이 있는 앱이 없습니다');
        return;
      }

      // 00:00 기준 오늘 시작 시간
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);

      print('📅 오늘 날짜: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}');
      print('📅 오늘 시작: ${todayStart.toString()}');

      // 날짜 변경 감지 (lastSyncDate가 오늘이 아니면 날짜 변경)
      final lastSyncDay = _lastSyncDate == null
          ? null
          : DateTime(_lastSyncDate!.year, _lastSyncDate!.month, _lastSyncDate!.day);
      final today = DateTime(now.year, now.month, now.day);
      final bool dateChanged = lastSyncDay == null || lastSyncDay.isBefore(today);

      if (dateChanged) {
        print('📅 날짜가 변경되었습니다! 오늘 데이터를 어제로 이동합니다.');
        print('   lastSyncDate: ${_lastSyncDate?.toString() ?? "null"}');
        print('   today: ${today.toString()}');

        // 현재 오늘 데이터를 어제 데이터로 이동 (기존 Firestore 데이터)
        for (var goal in _goals) {
          print('  [이동 전] ${goal.name}: 오늘=${goal.usageHours.toInt()}h${goal.usageMinutes}m, 어제=${goal.yesterdayUsageHours.toInt()}h${goal.yesterdayUsageMinutes}m');

          goal.yesterdayUsageHours = goal.usageHours;
          goal.yesterdayUsageMinutes = goal.usageMinutes;

          print('  [이동 후] ${goal.name}: 어제로 이동됨 → ${goal.yesterdayUsageHours.toInt()}h${goal.yesterdayUsageMinutes}m');
        }
      } else {
        print('✅ 날짜 변경 없음. 오늘 데이터만 업데이트합니다.');
      }

      // 오늘 사용량 조회 (00:00부터 현재까지)
      // ⚠️ 주의: Android UsageStats는 범위 무시하고 누적값 반환하는 버그가 있음
      // 하지만 날짜가 바뀌면 오늘→어제로 이동하기 위해 계속 수집해야 함
      // UI에는 어제 사용량만 표시됨
      print('📱 오늘 사용량 수집 중 (내부 추적용, 자정에 어제로 이동)');
      print('   시작: ${todayStart.toString()}');
      print('   종료: ${now.toString()}');

      final todayUsageStats = await UsageStats.queryUsageStats(todayStart, now);

      final Map<String, int> todayUsageMap = {};
      for (var packageName in packageNames) {
        final usage = todayUsageStats.firstWhere(
          (u) => u.packageName == packageName,
          orElse: () => UsageInfo(packageName: packageName, totalTimeInForeground: '0'),
        );

        final totalTimeMs = int.tryParse(usage.totalTimeInForeground?.toString() ?? '0') ?? 0;
        todayUsageMap[packageName] = totalTimeMs ~/ 1000 ~/ 60;
      }

      // 오늘 사용량 업데이트 (내부적으로만 저장, UI에는 표시 안 함)
      for (var goal in _goals) {
        if (goal.packageName != null && todayUsageMap.containsKey(goal.packageName)) {
          final usageMinutes = todayUsageMap[goal.packageName!] ?? 0;
          final hours = usageMinutes ~/ 60;
          final minutes = usageMinutes % 60;

          goal.usageHours = hours.toDouble();
          goal.usageMinutes = minutes;
        }
      }

      // 어제 사용량 조회 (어제 00:00 ~ 23:59:59)
      // ⚠️ 중요: 날짜가 바뀌었을 때는 이미 위에서 데이터를 이동했으므로 조회하지 않음!
      // 오직 최초 실행 시 (어제 데이터가 0일 때)에만 조회
      final needYesterdayData = !dateChanged &&
                               _goals.any((g) => g.yesterdayUsageHours == 0 && g.yesterdayUsageMinutes == 0);

      if (needYesterdayData) {
        print('📅 최초 실행: 어제 사용량 조회 (00:00 ~ 23:59:59)');

        final yesterday = today.subtract(const Duration(days: 1));
        final yesterdayStart = DateTime(yesterday.year, yesterday.month, yesterday.day, 0, 0, 0);
        final yesterdayEnd = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);

        print('   시작: ${yesterdayStart.toString()}');
        print('   종료: ${yesterdayEnd.toString()}');

        final yesterdayUsageStats = await UsageStats.queryUsageStats(yesterdayStart, yesterdayEnd);
        print('   조회된 앱 수: ${yesterdayUsageStats.length}개');

        final Map<String, int> yesterdayUsageMap = {};
        for (var packageName in packageNames) {
          final usage = yesterdayUsageStats.firstWhere(
            (u) => u.packageName == packageName,
            orElse: () => UsageInfo(packageName: packageName, totalTimeInForeground: '0'),
          );

          final totalTimeMs = int.tryParse(usage.totalTimeInForeground?.toString() ?? '0') ?? 0;
          yesterdayUsageMap[packageName] = totalTimeMs ~/ 1000 ~/ 60;
        }

        // 어제 사용량 업데이트
        for (var goal in _goals) {
          if (goal.packageName != null && yesterdayUsageMap.containsKey(goal.packageName)) {
            final usageMinutes = yesterdayUsageMap[goal.packageName!] ?? 0;
            final hours = usageMinutes ~/ 60;
            final minutes = usageMinutes % 60;

            goal.yesterdayUsageHours = hours.toDouble();
            goal.yesterdayUsageMinutes = minutes;

            print('  ${goal.name}: 어제=${hours}h${minutes}m');
          }
        }
      } else if (dateChanged) {
        print('📅 날짜 변경됨: 어제 데이터는 이미 이동 완료 (UsageStats 조회 안 함)');
      }

      // lastSyncDate를 현재 시간으로 업데이트
      _lastSyncDate = now;

      notifyListeners();
      await _saveGoals();

      print('✅ UsageStats 동기화 완료 (00:00 기준, ${packageNames.length}개 앱)');
      print('📊 최종 상태 (UI에는 어제만 표시):');
      for (var goal in _goals) {
        print('  ${goal.name}: 어제=${goal.yesterdayUsageHours.toInt()}h${goal.yesterdayUsageMinutes}m');
      }
    } catch (e) {
      print('UsageStats 동기화 에러: $e');
    }
  }
}
