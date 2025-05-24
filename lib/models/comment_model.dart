/// 댓글 데이터 모델 (DiaryModel과 동일한 Map 방식 사용)
class CommentModel {
  final String id;
  final String content;
  final DateTime createdAt;
  final String? authorName; // 나중에 확장 가능
  final String diaryId; // 어떤 일기/소설에 대한 댓글인지

  CommentModel({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.diaryId,
    this.authorName,
  });

  /// Map에서 CommentModel 객체 생성 (DiaryModel.fromMap과 동일한 방식)
  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      id: map['id'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      diaryId: map['diaryId'] as String,
      authorName: map['authorName'] as String?,
    );
  }

  /// CommentModel 객체를 Map으로 변환 (DiaryModel.toMap과 동일한 방식)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'diaryId': diaryId,
      'authorName': authorName,
    };
  }

  /// JSON에서 CommentModel 객체 생성 (호환성을 위해 유지)
  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel.fromMap(json);
  }

  /// CommentModel 객체를 JSON으로 변환 (호환성을 위해 유지)
  Map<String, dynamic> toJson() {
    return toMap();
  }

  /// 객체 복사
  CommentModel copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    String? diaryId,
    String? authorName,
  }) {
    return CommentModel(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      diaryId: diaryId ?? this.diaryId,
      authorName: authorName ?? this.authorName,
    );
  }

  @override
  String toString() {
    return 'CommentModel(id: $id, content: $content, diaryId: $diaryId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommentModel &&
        other.id == id &&
        other.content == content &&
        other.createdAt == createdAt &&
        other.diaryId == diaryId &&
        other.authorName == authorName;
  }

  @override
  int get hashCode {
    return Object.hash(id, content, createdAt, diaryId, authorName);
  }
}
