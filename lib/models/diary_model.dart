class DiaryModel {
  final String diary;
  final String novel;
  final DateTime date;

  DiaryModel({
    required this.diary,
    required this.novel,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'diary': diary,
        'novel': novel,
        'date': date.toIso8601String(),
      };

  factory DiaryModel.fromMap(Map<String, dynamic> map) {
    return DiaryModel(
      diary: map['diary'] as String,
      novel: map['novel'] as String,
      date: DateTime.parse(map['date']),
    );
  }
}
