import 'package:flutter/foundation.dart';
import '../models/comment_model.dart';
import '../models/diary_model.dart';
import '../services/firestore_service.dart';

class CommentProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<CommentModel> _comments = [];
  bool _isLoading = false;

  // Getters
  List<CommentModel> get comments => _comments;
  bool get isLoading => _isLoading;

  /// 특정 일기/소설의 댓글 가져오기
  List<CommentModel> getCommentsForDiary(DiaryModel diary) {
    final diaryId = diary.id;
    final diaryComments =
        _comments.where((comment) => comment.diaryId == diaryId).toList();
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
      final diaryId = diary.id;
      final commentData = {
        'content': content.trim(),
        'createdAt': DateTime.now().toIso8601String(), // ISO8601 문자열로 저장 (웹 호환)
        'authorName': authorName,
      };
      await _firestoreService.addComment(diaryId, commentData);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('댓글 추가 실패: $e');
      return false;
    }
  }

  /// 댓글 삭제
  Future<bool> deleteComment(String diaryId, String commentId) async {
    try {
      await _firestoreService.deleteComment(diaryId, commentId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('댓글 삭제 실패: $e');
      return false;
    }
  }

  /// 특정 일기의 댓글 수 가져오기
  int getCommentCountForDiary(DiaryModel diary) {
    final diaryId = diary.id;
    return _comments.where((comment) => comment.diaryId == diaryId).length;
  }

  /// 특정 일기의 댓글 스트림 가져오기
  Stream<List<CommentModel>> getCommentsStream(String diaryId) {
    return _firestoreService.getCommentsStream(diaryId).map((commentsList) {
      return commentsList.map((commentData) {
        return CommentModel.fromMap(commentData);
      }).toList();
    });
  }
}
