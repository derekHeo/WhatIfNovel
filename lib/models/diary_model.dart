import 'package:flutter/foundation.dart';

@immutable
class DiaryModel {
  final String id;
  final String content;
  final String userInput;
  final DateTime createdAt;
  // final bool isBookmarked;

  // 앱 사용량 정보 추가
  final Map<String, dynamic>? appGoals; // 목표 시간
  final Map<String, dynamic>? appUsage; // 실제 사용 시간

  const DiaryModel({
    required this.id,
    required this.content,
    required this.userInput,
    required this.createdAt,
    // this.isBookmarked = false,
    this.appGoals,
    this.appUsage,
  });

  // 복사 및 수정을 위한 copyWith 메서드 (상태 관리 시 유용)
  DiaryModel copyWith({
    String? id,
    String? content,
    String? userInput,
    DateTime? createdAt,
    bool? isBookmarked,
    Map<String, dynamic>? appGoals,
    Map<String, dynamic>? appUsage,
  }) {
    return DiaryModel(
      id: id ?? this.id,
      content: content ?? this.content,
      userInput: userInput ?? this.userInput,
      createdAt: createdAt ?? this.createdAt,
      // isBookmarked: isBookmarked ?? this.isBookmarked,
      appGoals: appGoals ?? this.appGoals,
      appUsage: appUsage ?? this.appUsage,
    );
  }

  // Hive 저장을 위한 toMap 메서드
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'userInput': userInput,
      'createdAt': createdAt.toIso8601String(), // ISO8601 문자열로 저장 (웹 호환)
      // 'isBookmarked': isBookmarked,
      'appGoals': appGoals,
      'appUsage': appUsage,
    };
  }

  // Hive 로드를 위한 fromMap 팩토리 생성자
  factory DiaryModel.fromMap(Map<String, dynamic> map) {
    // Firestore Timestamp를 DateTime으로 변환 (웹 호환성)
    DateTime parseCreatedAt(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      // Firestore Timestamp 처리 (toDate() 메서드 사용)
      if (value.runtimeType.toString() == 'Timestamp') {
        return (value as dynamic).toDate();
      }
      return DateTime.now();
    }

    return DiaryModel(
      id: map['id'] ?? '',
      content: map['content'] ?? '',
      userInput: map['userInput'] ?? '',
      createdAt: parseCreatedAt(map['createdAt']),
      // isBookmarked: map['isBookmarked'] ?? false,
      appGoals: map['appGoals'] as Map<String, dynamic>?,
      appUsage: map['appUsage'] as Map<String, dynamic>?,
    );
  }
}
