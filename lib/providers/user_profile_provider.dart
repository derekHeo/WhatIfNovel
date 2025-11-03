import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

class UserProfileProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserProfile _userProfile = UserProfile(name: '');
  bool _isLoading = false;

  UserProfile get userProfile => _userProfile;
  bool get isLoading => _isLoading;

  UserProfileProvider() {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('프로필 로드: 로그인된 사용자가 없습니다.');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('data')
          .get();

      if (doc.exists && doc.data() != null) {
        _userProfile = UserProfile.fromMap(doc.data()!);
        notifyListeners();
      }
    } catch (e) {
      print('프로필 로드 에러: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('로그인이 필요합니다.');
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('data')
          .set(profile.toMap(), SetOptions(merge: true));

      _userProfile = profile;
      notifyListeners();
    } catch (e) {
      print('프로필 저장 에러: $e');
      throw Exception('프로필 저장에 실패했습니다.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? name,
    int? birthYear,
    int? birthMonth,
    int? birthDay,
    String? gender,
    String? job,
    String? longTermGoal,
    String? shortTermGoal,
    String? additionalInfo,
    String? extraInfo,
    List<String>? keywords,
    Map<String, List<String>>? styleAnswers,
    bool? agreeToDataUsage,
  }) async {
    final updatedProfile = _userProfile.copyWith(
      name: name,
      birthYear: birthYear,
      birthMonth: birthMonth,
      birthDay: birthDay,
      gender: gender,
      job: job,
      longTermGoal: longTermGoal,
      shortTermGoal: shortTermGoal,
      additionalInfo: additionalInfo,
      extraInfo: extraInfo,
      keywords: keywords,
      styleAnswers: styleAnswers,
      agreeToDataUsage: agreeToDataUsage,
    );

    await saveProfile(updatedProfile);
  }

  Future<void> clearProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('프로필 삭제: 로그인된 사용자가 없습니다.');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('data')
          .delete();

      _userProfile = UserProfile(name: '');
      notifyListeners();
    } catch (e) {
      print('프로필 삭제 에러: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 로그인 후 프로필을 다시 로드하는 메서드
  Future<void> reloadProfile() async {
    await _loadProfile();
  }

  double get profileCompleteness {
    int totalFields = 9; // extraInfo 추가로 9개
    int completedFields = 0;

    if (_userProfile.name.isNotEmpty) completedFields++;
    if (_userProfile.birthYear != null) completedFields++;
    if (_userProfile.gender != null && _userProfile.gender!.isNotEmpty) {
      completedFields++;
    }
    if (_userProfile.job != null && _userProfile.job!.isNotEmpty) {
      completedFields++;
    }
    if (_userProfile.longTermGoal != null &&
        _userProfile.longTermGoal!.isNotEmpty) {
      completedFields++;
    }
    if (_userProfile.shortTermGoal != null &&
        _userProfile.shortTermGoal!.isNotEmpty) {
      completedFields++;
    }
    if (_userProfile.additionalInfo != null &&
        _userProfile.additionalInfo!.isNotEmpty) {
      completedFields++;
    }
    if (_userProfile.extraInfo != null &&
        _userProfile.extraInfo!.isNotEmpty) {
      completedFields++;
    }
    if ((_userProfile.styleAnswers != null &&
            _userProfile.styleAnswers!.values.any((list) => list.isNotEmpty)) ||
        _userProfile.keywords.isNotEmpty) {
      completedFields++;
    }

    if (totalFields == 0) return 0.0;
    return completedFields / totalFields;
  }

  String getProfileForPrompt() {
    if (_userProfile.isEmpty) {
      return '사용자 프로필: 정보 없음';
    }
    return _userProfile.toPromptText();
  }
}
