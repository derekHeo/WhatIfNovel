// providers/app_goal_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_goal_model.dart';

class AppGoalProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;

  // 초기 기본 데이터 (Firestore에 데이터가 없을 때 사용)
  List<AppGoal> _goals = [
    AppGoal(
        name: 'Instagram',
        imagePath: 'assets/images/insta.png',
        goalHours: 1,
        goalMinutes: 0,
        usageHours: 0.0,
        usageMinutes: 30),
    AppGoal(
        name: 'YouTube',
        imagePath: 'assets/images/youtube.png',
        goalHours: 1,
        goalMinutes: 0,
        usageHours: 0.0,
        usageMinutes: 30),
    AppGoal(
        name: 'KakaoTalk',
        imagePath: 'assets/images/kakao.png',
        goalHours: 1,
        goalMinutes: 0,
        usageHours: 0.0,
        usageMinutes: 30),
  ];

  List<AppGoal> get goals => _goals;
  bool get isLoading => _isLoading;

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
        if (data['goals'] != null) {
          final List<dynamic> goalsData = data['goals'] as List<dynamic>;
          _goals = goalsData
              .map((goalMap) => AppGoal.fromMap(goalMap as Map<String, dynamic>))
              .toList();
          print('목표 로드 성공: ${_goals.length}개');
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
      await _firestore
          .collection('app_goals')
          .doc(user.uid)
          .set({'goals': goalsData}, SetOptions(merge: true));
      print('목표 저장 완료');
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
}
