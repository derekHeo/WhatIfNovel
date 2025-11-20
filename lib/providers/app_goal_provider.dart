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

  // 마지막 목표 설정 날짜 (회고 모드 vs 트래킹 모드 판별용)
  DateTime? _lastGoalDate;

  List<AppGoal> get goals => _goals;
  bool get isLoading => _isLoading;
  DateTime? get lastSyncDate => _lastSyncDate;
  DateTime? get lastGoalDate => _lastGoalDate;

  // 현재 모드 판별
  bool get isReviewMode {
    if (_lastGoalDate == null) return true; // 목표를 설정한 적 없음 → 회고 모드
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastGoalDay = DateTime(_lastGoalDate!.year, _lastGoalDate!.month, _lastGoalDate!.day);
    return lastGoalDay.isBefore(today); // 마지막 목표 설정일이 오늘 이전 → 회고 모드
  }

  bool get isTrackingMode => !isReviewMode;

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

        // 마지막 목표 설정 날짜 로드
        if (data['lastGoalDate'] != null) {
          _lastGoalDate = (data['lastGoalDate'] as Timestamp).toDate();
          print('마지막 목표 설정 날짜: ${_lastGoalDate.toString().substring(0, 10)}');
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
        if (_lastGoalDate != null) 'lastGoalDate': Timestamp.fromDate(_lastGoalDate!),
      };

      await _firestore
          .collection('app_goals')
          .doc(user.uid)
          .set(dataToSave, SetOptions(merge: true));
      print('목표 저장 완료 (lastSyncDate: ${_lastSyncDate?.toString().substring(0, 10)}, lastGoalDate: ${_lastGoalDate?.toString().substring(0, 10)})');
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

  /// 마지막 목표 설정 날짜 업데이트 (WhatIf 생성 시 호출)
  /// 회고 모드 → 트래킹 모드 전환
  Future<void> updateLastGoalDate(DateTime newDate) async {
    _lastGoalDate = newDate;
    print('✅ 마지막 목표 설정 날짜 갱신: ${_lastGoalDate.toString().substring(0, 10)}');
    print('   모드: ${isReviewMode ? "회고 모드" : "트래킹 모드"}');
    notifyListeners();
    await _saveGoals();
  }

  /// UsageStats 동기화 (회고 모드 vs 트래킹 모드)
  /// ✨ 새로운 로직: getAccurateUsageTime() 사용으로 정확한 데이터 제공
  ///
  /// 회고 모드 (Last_Goal_Date != Current_Date):
  ///   - Last_Goal_Date의 00:00 ~ 23:59 데이터 표시
  ///
  /// 트래킹 모드 (Last_Goal_Date == Current_Date):
  ///   - Current_Date의 00:00 ~ Now 데이터 표시
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
        print('⚠️ UsageStats 권한이 없습니다');
        return;
      }

      // 패키지명이 있는 앱들
      final packageNames = _goals
          .where((g) => g.packageName != null && g.packageName!.isNotEmpty)
          .map((g) => g.packageName!)
          .toList();

      if (packageNames.isEmpty) {
        print('⚠️ 패키지명이 있는 앱이 없습니다');
        return;
      }

      final now = DateTime.now();
      print('');
      print('═══════════════════════════════════════════════════════════');
      print('📊 UsageStats 동기화 시작');
      print('═══════════════════════════════════════════════════════════');
      print('📅 현재 시각: ${now.toString()}');
      print('📦 조회할 앱: ${packageNames.length}개');
      print('');

      // 현재 모드 판별
      final mode = isReviewMode ? "회고 모드" : "트래킹 모드";
      print('🔍 현재 모드: $mode');
      print('   Last_Goal_Date: ${_lastGoalDate?.toString().substring(0, 10) ?? "미설정"}');
      print('   Current_Date: ${now.toString().substring(0, 10)}');
      print('');

      Map<String, int> usageData = {};

      if (isReviewMode) {
        // 회고 모드: Last_Goal_Date의 00:00 ~ 23:59 데이터 조회
        print('📖 [회고 모드] Last_Goal_Date의 하루 전체 데이터 조회');

        // Last_Goal_Date가 없으면 어제 날짜 사용
        final targetDate = _lastGoalDate ?? now.subtract(const Duration(days: 1));
        final targetDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
        final startTime = DateTime(targetDay.year, targetDay.month, targetDay.day, 0, 0, 0);
        final endTime = DateTime(targetDay.year, targetDay.month, targetDay.day, 23, 59, 59);

        print('   조회 범위: ${startTime.toString()} ~ ${endTime.toString()}');
        print('   조회 날짜: ${targetDay.toString().substring(0, 10)}');
        print('');

        // ✅ 정확한 방법: getAccurateUsageTime() 사용
        usageData = await usageService.getAccurateUsageTime(
          startTime: startTime,
          endTime: endTime,
          packageNames: packageNames,
        );

        print('✅ 회고 모드 데이터 조회 완료');
      } else {
        // 트래킹 모드: Current_Date의 00:00 ~ Now 데이터 조회
        print('📈 [트래킹 모드] 오늘(00:00 ~ 현재)의 실시간 데이터 조회');

        final today = DateTime(now.year, now.month, now.day);
        final startTime = DateTime(today.year, today.month, today.day, 0, 0, 0);
        final endTime = now;

        print('   조회 범위: ${startTime.toString()} ~ ${endTime.toString()}');
        print('   경과 시간: ${now.difference(startTime).inHours}시간 ${now.difference(startTime).inMinutes % 60}분');
        print('');

        // ✅ 정확한 방법: getAccurateUsageTime() 사용
        usageData = await usageService.getAccurateUsageTime(
          startTime: startTime,
          endTime: endTime,
          packageNames: packageNames,
        );

        print('✅ 트래킹 모드 데이터 조회 완료');
      }

      print('');
      print('📊 조회된 사용량 데이터 업데이트 중...');

      // 조회된 데이터를 모드별로 적절한 필드에 저장
      for (var goal in _goals) {
        if (goal.packageName != null && usageData.containsKey(goal.packageName)) {
          final usageMinutes = usageData[goal.packageName!] ?? 0;
          final hours = usageMinutes ~/ 60;
          final minutes = usageMinutes % 60;

          if (isTrackingMode) {
            // 트래킹 모드: usageHours/Minutes에 저장 (오늘 00:00 ~ 현재)
            goal.usageHours = hours.toDouble();
            goal.usageMinutes = minutes;
          } else {
            // 회고 모드: yesterdayUsageHours/Minutes에 저장 (어제 하루)
            goal.yesterdayUsageHours = hours.toDouble();
            goal.yesterdayUsageMinutes = minutes;
          }

          print('   📱 ${goal.name}: ${hours}시간 ${minutes}분 (${usageMinutes}분) [$mode]');
        }
      }

      // lastSyncDate를 현재 시간으로 업데이트
      _lastSyncDate = now;

      notifyListeners();
      await _saveGoals();

      print('');
      print('✅ UsageStats 동기화 완료!');
      print('   모드: $mode');
      print('   조회된 앱: ${packageNames.length}개');
      print('   마지막 동기화: ${_lastSyncDate.toString()}');
      print('═══════════════════════════════════════════════════════════');
      print('');
    } catch (e) {
      print('');
      print('❌ UsageStats 동기화 에러: $e');
      print('   스택 트레이스: ${StackTrace.current}');
      print('');
    }
  }
}
