class UserProfile {
  final String name;
  final int? birthYear;
  final int? birthMonth;
  final int? birthDay;
  final String? gender;
  final String? job;
  final String? currentActivities;
  final String? additionalInfo;
  final List<String> keywords;
  final Map<String, List<String>>? styleAnswers; // 카테고리별 답변 추가
  final bool agreeToDataUsage;

  UserProfile({
    required this.name,
    this.birthYear,
    this.birthMonth,
    this.birthDay,
    this.gender,
    this.job,
    this.currentActivities,
    this.additionalInfo,
    this.keywords = const [],
    this.styleAnswers,
    this.agreeToDataUsage = false,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'birthYear': birthYear,
        'birthMonth': birthMonth,
        'birthDay': birthDay,
        'gender': gender,
        'job': job,
        'currentActivities': currentActivities,
        'additionalInfo': additionalInfo,
        'keywords': keywords,
        'styleAnswers': styleAnswers,
        'agreeToDataUsage': agreeToDataUsage,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name'] as String? ?? '',
      birthYear: map['birthYear'] as int?,
      birthMonth: map['birthMonth'] as int?,
      birthDay: map['birthDay'] as int?,
      gender: map['gender'] as String?,
      job: map['job'] as String?,
      currentActivities: map['currentActivities'] as String?,
      additionalInfo: map['additionalInfo'] as String?,
      keywords: List<String>.from(map['keywords'] as List? ?? []),
      styleAnswers: map['styleAnswers'] != null
          ? Map<String, List<String>>.from(Map.from(map['styleAnswers'])
              .map((key, value) => MapEntry(key, List<String>.from(value))))
          : null,
      agreeToDataUsage: map['agreeToDataUsage'] as bool? ?? false,
    );
  }

  UserProfile copyWith({
    String? name,
    int? birthYear,
    int? birthMonth,
    int? birthDay,
    String? gender,
    String? job,
    String? currentActivities,
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
      currentActivities: currentActivities ?? this.currentActivities,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      keywords: keywords ?? this.keywords,
      styleAnswers: styleAnswers ?? this.styleAnswers,
      agreeToDataUsage: agreeToDataUsage ?? this.agreeToDataUsage,
    );
  }

  // 나이 계산
  int? get age {
    if (birthYear == null) return null;
    final currentYear = DateTime.now().year;
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

    if (currentActivities != null && currentActivities!.isNotEmpty) {
      buffer.writeln('- 현재 활동: $currentActivities');
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

  bool get isEmpty {
    return name.isEmpty &&
        birthYear == null &&
        (gender == null || gender!.isEmpty) &&
        (job == null || job!.isEmpty) &&
        (currentActivities == null || currentActivities!.isEmpty) &&
        (additionalInfo == null || additionalInfo!.isEmpty) &&
        keywords.isEmpty &&
        (styleAnswers == null || styleAnswers!.isEmpty);
  }
}
