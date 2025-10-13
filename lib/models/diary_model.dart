import 'package:flutter/foundation.dart';

@immutable
class DiaryModel {
  final String id;
  final String title;
  final String content;
  final String userInput;
  final DateTime createdAt;
  // final bool isBookmarked;

  const DiaryModel({
    required this.id,
    required this.title,
    required this.content,
    required this.userInput,
    required this.createdAt,
    // this.isBookmarked = false,
  });

  // 복사 및 수정을 위한 copyWith 메서드 (상태 관리 시 유용)
  DiaryModel copyWith({
    String? id,
    String? title,
    String? content,
    String? userInput,
    DateTime? createdAt,
    bool? isBookmarked,
  }) {
    return DiaryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      userInput: userInput ?? this.userInput,
      createdAt: createdAt ?? this.createdAt,
      // isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  // Hive 저장을 위한 toMap 메서드
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'userInput': userInput,
      'createdAt': createdAt.toIso8601String(),
      // 'isBookmarked': isBookmarked,
    };
  }

  // Hive 로드를 위한 fromMap 팩토리 생성자
  factory DiaryModel.fromMap(Map<String, dynamic> map) {
    return DiaryModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      userInput: map['userInput'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      // isBookmarked: map['isBookmarked'] ?? false,
    );
  }
}
