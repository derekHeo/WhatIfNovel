class DiaryModel {
  // 💡 'diary' 필드 이름을 'userInput'으로 변경하여 역할을 명확히 함
  final String userInput;
  // 💡 AI에게 보낼 전체 프롬프트를 저장할 필드 추가
  final String fullPrompt;
  final String novel;
  final DateTime date;
  final bool isBookmarked;

  DiaryModel({
    required this.userInput,
    required this.fullPrompt,
    required this.novel,
    required this.date,
    this.isBookmarked = false,
  });

  Map<String, dynamic> toMap() => {
        // 💡 저장할 필드 업데이트
        'userInput': userInput,
        'fullPrompt': fullPrompt,
        'novel': novel,
        'date': date.toIso8601String(),
        'isBookmarked': isBookmarked,
      };

  factory DiaryModel.fromMap(Map<String, dynamic> map) {
    return DiaryModel(
      // 💡 불러올 필드 업데이트.
      // 하위 호환성을 위해 'userInput'이 없으면 기존 'diary' 필드에서 값을 가져옴
      userInput: map['userInput'] as String? ?? map['diary'] as String,
      // 'fullPrompt'가 없는 구버전 데이터를 대비해 null일 경우 userInput을 기본값으로 사용
      fullPrompt: map['fullPrompt'] as String? ??
          (map['userInput'] as String? ?? map['diary'] as String),
      novel: map['novel'] as String,
      date: DateTime.parse(map['date']),
      isBookmarked: map['isBookmarked'] as bool? ?? false,
    );
  }

  // copyWith 메서드도 새로운 필드에 맞게 업데이트
  DiaryModel copyWith({
    String? userInput,
    String? fullPrompt,
    String? novel,
    DateTime? date,
    bool? isBookmarked,
  }) {
    return DiaryModel(
      userInput: userInput ?? this.userInput,
      fullPrompt: fullPrompt ?? this.fullPrompt,
      novel: novel ?? this.novel,
      date: date ?? this.date,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}
