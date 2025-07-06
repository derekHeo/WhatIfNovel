import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/user_profile.dart';

class UserProfileProvider with ChangeNotifier {
  // ⚠️ 중요: UserProfile 모델의 생성자 기본값이 바뀌었으므로,
  // 초기화 시 빈 UserProfile 객체를 올바르게 생성하도록 수정합니다.
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
        // fromMap은 UserProfile 모델에서 이미 수정했으므로 이 코드는 그대로 작동합니다.
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
      // toMap은 UserProfile 모델에서 이미 수정했으므로 이 코드는 그대로 작동합니다.
      await box.put('profile', profile.toMap());
      _userProfile = profile;
      notifyListeners();
    } catch (e) {
      print('프로필 저장 에러: $e');
      throw Exception('프로필 저장에 실패했습니다.');
    }
  }

  // 변경: updateProfile 메서드의 파라미터를 새 모델에 맞게 수정
  Future<void> updateProfile({
    String? name,
    int? birthYear,
    int? birthMonth,
    int? birthDay,
    String? gender,
    String? job,
    String? longTermGoal, // currentActivities -> longTermGoal
    String? shortTermGoal, // shortTermGoal 추가
    String? additionalInfo,
    List<String>? keywords,
    Map<String, List<String>>? styleAnswers, // styleAnswers 추가
    bool? agreeToDataUsage,
  }) async {
    // copyWith 호출을 새 모델에 맞게 수정
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
      keywords: keywords,
      styleAnswers: styleAnswers,
      agreeToDataUsage: agreeToDataUsage,
    );

    await saveProfile(updatedProfile);
  }

  Future<void> clearProfile() async {
    try {
      var box = await Hive.openBox('user_profile');
      await box.delete('profile');
      // UserProfile 모델의 생성자 기본값이 바뀌었으므로, 초기화 코드를 수정합니다.
      _userProfile = UserProfile(name: '');
      notifyListeners();
    } catch (e) {
      print('프로필 삭제 에러: $e');
    }
  }

  // 변경: 프로필 완성도 체크 로직을 새 모델 필드에 맞게 수정
  double get profileCompleteness {
    // 장기/단기 목표가 추가되었으므로 총 필드 수를 8개로 변경
    int totalFields = 8;
    int completedFields = 0;

    if (_userProfile.name.isNotEmpty) completedFields++;
    if (_userProfile.birthYear != null) completedFields++;
    if (_userProfile.gender != null && _userProfile.gender!.isNotEmpty) {
      completedFields++;
    }
    if (_userProfile.job != null && _userProfile.job!.isNotEmpty) {
      completedFields++;
    }
    // currentActivities 대신 longTermGoal, shortTermGoal을 각각 체크
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
    // styleAnswers가 비어있지 않다면 필드를 채운 것으로 간주 (기존 keywords도 호환)
    if ((_userProfile.styleAnswers != null &&
            _userProfile.styleAnswers!.values.any((list) => list.isNotEmpty)) ||
        _userProfile.keywords.isNotEmpty) {
      completedFields++;
    }

    if (totalFields == 0) return 0.0;
    return completedFields / totalFields;
  }

  // GPT용 프로필 텍스트 가져오기
  String getProfileForPrompt() {
    // UserProfile 모델의 isEmpty와 toPromptText는 이미 수정되었으므로
    // 이 코드는 그대로 작동합니다.
    if (_userProfile.isEmpty) {
      return '사용자 프로필: 정보 없음';
    }
    return _userProfile.toPromptText();
  }
}
