class DiaryModel {
  final String diary;
  final String novel;
  final DateTime date;
  final bool isBookmarked; // 북마크 필드 추가

  DiaryModel({
    required this.diary,
    required this.novel,
    required this.date,
    this.isBookmarked = false, // 기본값 false
  });

  Map<String, dynamic> toMap() => {
        'diary': diary,
        'novel': novel,
        'date': date.toIso8601String(),
        'isBookmarked': isBookmarked, // 저장에 포함
      };

  factory DiaryModel.fromMap(Map<String, dynamic> map) {
    return DiaryModel(
      diary: map['diary'] as String,
      novel: map['novel'] as String,
      date: DateTime.parse(map['date']),
      isBookmarked: map['isBookmarked'] as bool? ?? false, // null일 경우 false
    );
  }

  // 북마크 상태를 변경한 새로운 인스턴스 생성
  DiaryModel copyWith({
    String? diary,
    String? novel,
    DateTime? date,
    bool? isBookmarked,
  }) {
    return DiaryModel(
      diary: diary ?? this.diary,
      novel: novel ?? this.novel,
      date: date ?? this.date,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}
