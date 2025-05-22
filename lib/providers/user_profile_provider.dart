import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/user_profile.dart';

class UserProfileProvider with ChangeNotifier {
  UserProfile _userProfile = UserProfile(name: '');

  UserProfile get userProfile => _userProfile;

  UserProfileProvider() {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      var box = await Hive.openBox('user_profile');
      final profileData = box.get('profile');
      if (profileData != null) {
        _userProfile =
            UserProfile.fromMap(Map<String, dynamic>.from(profileData));
        notifyListeners();
      }
    } catch (e) {
      print('프로필 로드 에러: $e');
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    try {
      var box = await Hive.openBox('user_profile');
      await box.put('profile', profile.toMap());
      _userProfile = profile;
      notifyListeners();
    } catch (e) {
      print('프로필 저장 에러: $e');
      throw Exception('프로필 저장에 실패했습니다.');
    }
  }

  Future<void> updateProfile({
    String? name,
    int? birthYear,
    int? birthMonth,
    int? birthDay,
    String? gender,
    String? job,
    String? currentActivities,
    String? additionalInfo,
    List<String>? keywords,
    bool? agreeToDataUsage,
  }) async {
    final updatedProfile = _userProfile.copyWith(
      name: name,
      birthYear: birthYear,
      birthMonth: birthMonth,
      birthDay: birthDay,
      gender: gender,
      job: job,
      currentActivities: currentActivities,
      additionalInfo: additionalInfo,
      keywords: keywords,
      agreeToDataUsage: agreeToDataUsage,
    );

    await saveProfile(updatedProfile);
  }

  Future<void> clearProfile() async {
    try {
      var box = await Hive.openBox('user_profile');
      await box.delete('profile');
      _userProfile = UserProfile(name: '');
      notifyListeners();
    } catch (e) {
      print('프로필 삭제 에러: $e');
    }
  }

  // 프로필 완성도 체크
  double get profileCompleteness {
    int totalFields = 7; // 이름, 생년월일, 성별, 직업, 현재활동, 추가정보, 키워드
    int completedFields = 0;

    if (_userProfile.name.isNotEmpty) completedFields++;
    if (_userProfile.birthYear != null) completedFields++;
    if (_userProfile.gender != null && _userProfile.gender!.isNotEmpty)
      completedFields++;
    if (_userProfile.job != null && _userProfile.job!.isNotEmpty)
      completedFields++;
    if (_userProfile.currentActivities != null &&
        _userProfile.currentActivities!.isNotEmpty) completedFields++;
    if (_userProfile.additionalInfo != null &&
        _userProfile.additionalInfo!.isNotEmpty) completedFields++;
    if (_userProfile.keywords.isNotEmpty) completedFields++;

    return completedFields / totalFields;
  }

  // GPT용 프로필 텍스트 가져오기
  String getProfileForPrompt() {
    if (_userProfile.isEmpty) {
      return '사용자 프로필: 정보 없음';
    }
    return _userProfile.toPromptText();
  }
}
