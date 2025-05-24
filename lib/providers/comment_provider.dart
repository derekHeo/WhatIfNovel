import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/comment_model.dart';
import '../models/diary_model.dart';

class CommentProvider extends ChangeNotifier {
  static const String _boxName = 'comments';
  Box? _commentBox;

  List<CommentModel> _comments = [];
  bool _isLoading = false;

  // Getters
  List<CommentModel> get comments => _comments;
  bool get isLoading => _isLoading;

  /// Hive Box 초기화 (DiaryProvider와 동일한 방식)
  Future<void> initializeBox() async {
    try {
      _commentBox = await Hive.openBox(_boxName);
      await loadAllComments();
    } catch (e) {
      debugPrint('CommentProvider 초기화 실패: $e');
    }
  }

  /// 모든 댓글 로드 (DiaryProvider와 동일한 방식)
  Future<void> loadAllComments() async {
    if (_commentBox == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final List commentsData = _commentBox!.get('comments', defaultValue: []);
      _comments = commentsData
          .map((item) => CommentModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();

      // 날짜순으로 정렬 (최신 순)
      _comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('댓글 로드 실패: $e');
      _comments = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 댓글 저장 (DiaryProvider와 동일한 방식)
  Future<void> _saveComments() async {
    if (_commentBox == null) return;

    try {
      await _commentBox!
          .put('comments', _comments.map((c) => c.toMap()).toList());
    } catch (e) {
      debugPrint('댓글 저장 실패: $e');
    }
  }

  /// 특정 일기/소설의 댓글 가져오기
  List<CommentModel> getCommentsForDiary(DiaryModel diary) {
    final diaryId = _generateDiaryId(diary);
    final diaryComments =
        _comments.where((comment) => comment.diaryId == diaryId).toList();

    // 날짜순으로 정렬 (오래된 순)
    diaryComments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return diaryComments;
  }

  /// 댓글 추가
  Future<bool> addComment({
    required String content,
    required DiaryModel diary,
    String? authorName,
  }) async {
    try {
      final diaryId = _generateDiaryId(diary);
      final newComment = CommentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content.trim(),
        createdAt: DateTime.now(),
        diaryId: diaryId,
        authorName: authorName,
      );

      // 메모리에 추가
      _comments.add(newComment);

      // Hive에 저장
      await _saveComments();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('댓글 추가 실패: $e');
      return false;
    }
  }

  /// 댓글 삭제
  Future<bool> deleteComment(String commentId) async {
    try {
      // 메모리에서 제거
      _comments.removeWhere((comment) => comment.id == commentId);

      // Hive에 저장
      await _saveComments();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('댓글 삭제 실패: $e');
      return false;
    }
  }

  /// 댓글 수정
  Future<bool> updateComment(String commentId, String newContent) async {
    try {
      final index = _comments.indexWhere((c) => c.id == commentId);
      if (index == -1) return false;

      final updatedComment =
          _comments[index].copyWith(content: newContent.trim());
      _comments[index] = updatedComment;

      // Hive에 저장
      await _saveComments();
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('댓글 수정 실패: $e');
      return false;
    }
  }

  /// 특정 일기의 댓글 수 가져오기
  int getCommentCountForDiary(DiaryModel diary) {
    final diaryId = _generateDiaryId(diary);
    return _comments.where((comment) => comment.diaryId == diaryId).length;
  }

  /// 모든 댓글 삭제 (개발/테스트용)
  Future<void> clearAllComments() async {
    try {
      _comments.clear();
      await _saveComments();
      notifyListeners();
    } catch (e) {
      debugPrint('모든 댓글 삭제 실패: $e');
    }
  }

  /// 일기별 고유 ID 생성 (날짜 + 일기 내용 해시)
  String _generateDiaryId(DiaryModel diary) {
    // 날짜와 일기 내용을 조합해서 고유 ID 생성
    final dateString = diary.date.toIso8601String().split('T')[0]; // YYYY-MM-DD
    final contentHash = diary.diary.hashCode.toString();
    return '${dateString}_$contentHash';
  }

  /// 최근 댓글 가져오기 (전체에서 최근 N개)
  List<CommentModel> getRecentComments(int count) {
    final recentComments = List<CommentModel>.from(_comments);
    recentComments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return recentComments.take(count).toList();
  }

  /// 검색 기능 (댓글 내용으로 검색)
  List<CommentModel> searchComments(String query) {
    if (query.trim().isEmpty) return [];

    final lowercaseQuery = query.toLowerCase();
    return _comments
        .where(
            (comment) => comment.content.toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  /// Provider 종료 시 정리
  @override
  void dispose() {
    _commentBox?.close();
    super.dispose();
  }
}
