class InquiryModel {
  final String id;
  final String title;
  final String content;
  final String userId;
  final DateTime createdAt;

  InquiryModel({
    required this.id,
    required this.title,
    required this.content,
    required this.userId,
    required this.createdAt,
  });

  // Firestore에 저장하기 위한 toMap
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Firestore에서 불러오기 위한 fromMap
  factory InquiryModel.fromMap(Map<String, dynamic> map) {
    return InquiryModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
