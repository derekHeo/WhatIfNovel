import 'package:flutter/material.dart';

class UserProfile {
  final String name;
  final int? birthYear;
  final int? birthMonth;
  final int? birthDay;
  final String? gender;
  final String? job;
  final String? longTermGoal;
  final String? shortTermGoal;
  final String? additionalInfo; // "요즘 주로 하는 일"
  final String? extraInfo; // 💡 "추가적인 설명"을 위한 새 필드
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
    this.longTermGoal,
    this.shortTermGoal,
    this.additionalInfo,
    this.extraInfo, // 💡 생성자에 추가
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
        'longTermGoal': longTermGoal,
        'shortTermGoal': shortTermGoal,
        'additionalInfo': additionalInfo,
        'extraInfo': extraInfo, // 💡 Map에 추가
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
      longTermGoal: map['longTermGoal'] as String?,
      shortTermGoal: map['shortTermGoal'] as String?,
      additionalInfo: map['additionalInfo'] as String?,
      extraInfo: map['extraInfo'] as String?, // 💡 Map에서 읽어오기
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
    String? longTermGoal,
    String? shortTermGoal,
    String? additionalInfo,
    String? extraInfo, // 💡 copyWith에 추가
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
      longTermGoal: longTermGoal ?? this.longTermGoal,
      shortTermGoal: shortTermGoal ?? this.shortTermGoal,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      extraInfo: extraInfo ?? this.extraInfo, // 💡 복사 로직에 추가
      keywords: keywords ?? this.keywords,
      styleAnswers: styleAnswers ?? this.styleAnswers,
      agreeToDataUsage: agreeToDataUsage ?? this.agreeToDataUsage,
    );
  }

  // 나이 계산
  int? get age {
    if (birthYear == null) return null;
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

    // longTermGoal, shortTermGoal은 toPromptText 메서드에 이미 반영되어 있었음
    if (longTermGoal != null && longTermGoal!.isNotEmpty) {
      buffer.writeln('- 장기 목표: $longTermGoal');
    }
    if (shortTermGoal != null && shortTermGoal!.isNotEmpty) {
      buffer.writeln('- 단기 목표: $shortTermGoal');
    }
    if (additionalInfo != null && additionalInfo!.isNotEmpty) {
      buffer.writeln('- 요즘 주로 하는 일: $additionalInfo');
    }

    if (extraInfo != null && extraInfo!.isNotEmpty) {
      buffer.writeln('- 추가적인 설명: $extraInfo'); // 💡 프롬프트에 추가
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

    // 기존 additionalInfo 필드는 이제 "요즘 주로 하는 일"을 나타내므로, 라벨을 명확하게 수정
    // (이미 위에서 "- 요즘 주로 하는 일:"로 처리)

    return buffer.toString();
  }

  // 프로필이 비어있는지 확인하는 getter
  bool get isEmpty {
    return name.isEmpty &&
        birthYear == null &&
        (gender == null || gender!.isEmpty) &&
        (job == null || job!.isEmpty) &&
        (longTermGoal == null || longTermGoal!.isEmpty) &&
        (shortTermGoal == null || shortTermGoal!.isEmpty) &&
        (additionalInfo == null || additionalInfo!.isEmpty) &&
        (extraInfo == null || extraInfo!.isEmpty) && // 💡 isEmpty 조건에 추가
        keywords.isEmpty &&
        (styleAnswers == null || styleAnswers!.isEmpty);
  }
}
