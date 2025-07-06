import 'package:flutter/material.dart'; // toPromptText에서 사용될 수 있으므로 유지

class UserProfile {
  final String name;
  final int? birthYear;
  final int? birthMonth;
  final int? birthDay;
  final String? gender;
  final String? job;
  // 변경: currentActivities를 longTermGoal과 shortTermGoal로 분리
  final String? longTermGoal;
  final String? shortTermGoal;
  final String? additionalInfo;
  final List<String> keywords;
  final Map<String, List<String>>? styleAnswers;
  final bool agreeToDataUsage;

  UserProfile({
    required this.name,
    this.birthYear,
    this.birthMonth,
    this.birthDay,
    this.gender,
    this.job,
    // 변경: 생성자 파라미터 업데이트
    this.longTermGoal,
    this.shortTermGoal,
    this.additionalInfo,
    this.keywords = const [],
    this.styleAnswers,
    this.agreeToDataUsage = false,
  });

  // toMap: 객체를 Map으로 변환 (저장용)
  Map<String, dynamic> toMap() => {
        'name': name,
        'birthYear': birthYear,
        'birthMonth': birthMonth,
        'birthDay': birthDay,
        'gender': gender,
        'job': job,
        // 변경: Map 키/값 업데이트
        'longTermGoal': longTermGoal,
        'shortTermGoal': shortTermGoal,
        'additionalInfo': additionalInfo,
        'keywords': keywords,
        'styleAnswers': styleAnswers,
        'agreeToDataUsage': agreeToDataUsage,
      };

  // fromMap: Map을 객체로 변환 (불러오기용)
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'] as String? ?? '',
      birthYear: map['birthYear'] as int?,
      birthMonth: map['birthMonth'] as int?,
      birthDay: map['birthDay'] as int?,
      gender: map['gender'] as String?,
      job: map['job'] as String?,
      // 변경: Map에서 새로운 필드 읽어오기
      longTermGoal: map['longTermGoal'] as String?,
      shortTermGoal: map['shortTermGoal'] as String?,
      additionalInfo: map['additionalInfo'] as String?,
      keywords: List<String>.from(map['keywords'] as List? ?? []),
      styleAnswers: map['styleAnswers'] != null
          ? Map<String, List<String>>.from(Map.from(map['styleAnswers'])
              .map((key, value) => MapEntry(key, List<String>.from(value))))
          : null,
      agreeToDataUsage: map['agreeToDataUsage'] as bool? ?? false,
    );
  }

  // copyWith: 객체의 일부 필드만 변경하여 복사
  UserProfile copyWith({
    String? name,
    int? birthYear,
    int? birthMonth,
    int? birthDay,
    String? gender,
    String? job,
    // 변경: copyWith 파라미터 업데이트
    String? longTermGoal,
    String? shortTermGoal,
    String? additionalInfo,
    List<String>? keywords,
    Map<String, List<String>>? styleAnswers,
    bool? agreeToDataUsage,
  }) {
    return UserProfile(
      name: name ?? this.name,
      birthYear: birthYear ?? this.birthYear,
      birthMonth: birthMonth ?? this.birthMonth,
      birthDay: birthDay ?? this.birthDay,
      gender: gender ?? this.gender,
      job: job ?? this.job,
      // 변경: 복사 로직 업데이트
      longTermGoal: longTermGoal ?? this.longTermGoal,
      shortTermGoal: shortTermGoal ?? this.shortTermGoal,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      keywords: keywords ?? this.keywords,
      styleAnswers: styleAnswers ?? this.styleAnswers,
      agreeToDataUsage: agreeToDataUsage ?? this.agreeToDataUsage,
    );
  }

  // 나이 계산
  int? get age {
    if (birthYear == null) return null;
    // 변경: 현재 날짜를 한국 시간 기준으로 가져오도록 수정
    final now = DateTime.now();
    final currentYear = now.year;
    return currentYear - birthYear!;
  }

  // 생년월일 문자열
  String get birthDateString {
    if (birthYear == null || birthMonth == null || birthDay == null) {
      return '미입력';
    }
    return '$birthYear년 $birthMonth월 $birthDay일';
  }

  // GPT 프롬프트용 프로필 텍스트 생성
  String toPromptText() {
    final buffer = StringBuffer();

    buffer.writeln('사용자 프로필:');
    buffer.writeln('- 이름: $name');

    if (age != null) {
      buffer.writeln('- 나이: ${age}세');
    }

    if (gender != null && gender!.isNotEmpty) {
      buffer.writeln('- 성별: $gender');
    }

    if (job != null && job!.isNotEmpty) {
      buffer.writeln('- 직업: $job');
    }

    // 변경: 현재 활동 대신 장기/단기 목표를 프롬프트에 추가
    if (longTermGoal != null && longTermGoal!.isNotEmpty) {
      buffer.writeln('- 장기 목표: $longTermGoal');
    }
    if (shortTermGoal != null && shortTermGoal!.isNotEmpty) {
      buffer.writeln('- 단기 목표: $shortTermGoal');
    }

    // 카테고리별 스타일 답변 표시
    if (styleAnswers != null && styleAnswers!.isNotEmpty) {
      buffer.writeln('- 성격/행동 특성:');
      styleAnswers!.forEach((category, answers) {
        if (answers.isNotEmpty) {
          buffer.writeln('  * $category: ${answers.join(', ')}');
        }
      });
    } else if (keywords.isNotEmpty) {
      // 기존 키워드 방식 호환성
      buffer.writeln('- 성격/행동 특성: ${keywords.join(', ')}');
    }

    if (additionalInfo != null && additionalInfo!.isNotEmpty) {
      buffer.writeln('- 추가 정보: $additionalInfo');
    }

    return buffer.toString();
  }

  // 프로필이 비어있는지 확인하는 getter
  bool get isEmpty {
    return name.isEmpty &&
        birthYear == null &&
        (gender == null || gender!.isEmpty) &&
        (job == null || job!.isEmpty) &&
        // 변경: isEmpty 조건 업데이트
        (longTermGoal == null || longTermGoal!.isEmpty) &&
        (shortTermGoal == null || shortTermGoal!.isEmpty) &&
        (additionalInfo == null || additionalInfo!.isEmpty) &&
        keywords.isEmpty &&
        (styleAnswers == null || styleAnswers!.isEmpty);
  }
}
