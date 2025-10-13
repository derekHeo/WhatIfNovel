import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/diary_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 컬렉션 이름들
  static const String _diariesCollection = 'diaries';
  static const String _commentsCollection = 'comments';
  static const String _userProfilesCollection = 'user_profiles';
  static const String _appGoalsCollection = 'app_goals';

  // ==================== Diary 관련 메서드 ====================

  /// 새로운 일기 생성
  Future<void> createDiary(DiaryModel diary) async {
    try {
      await _firestore
          .collection(_diariesCollection)
          .doc(diary.id)
          .set(diary.toMap());
    } catch (e) {
      throw Exception('일기 생성 실패: $e');
    }
  }

  /// 모든 일기 가져오기 (실시간 스트림)
  Stream<List<DiaryModel>> getDiariesStream() {
    return _firestore
        .collection(_diariesCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return DiaryModel.fromMap(doc.data());
      }).toList();
    });
  }

  /// 모든 일기 가져오기 (일회성)
  Future<List<DiaryModel>> getDiaries() async {
    try {
      final snapshot = await _firestore
          .collection(_diariesCollection)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        return DiaryModel.fromMap(doc.data());
      }).toList();
    } catch (e) {
      throw Exception('일기 불러오기 실패: $e');
    }
  }

  /// 특정 일기 가져오기
  Future<DiaryModel?> getDiary(String id) async {
    try {
      final doc =
          await _firestore.collection(_diariesCollection).doc(id).get();

      if (doc.exists) {
        return DiaryModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('일기 불러오기 실패: $e');
    }
  }

  /// 일기 수정
  Future<void> updateDiary(DiaryModel diary) async {
    try {
      await _firestore
          .collection(_diariesCollection)
          .doc(diary.id)
          .update(diary.toMap());
    } catch (e) {
      throw Exception('일기 수정 실패: $e');
    }
  }

  /// 일기 삭제
  Future<void> deleteDiary(String id) async {
    try {
      await _firestore.collection(_diariesCollection).doc(id).delete();
    } catch (e) {
      throw Exception('일기 삭제 실패: $e');
    }
  }

  // ==================== Comment 관련 메서드 ====================

  /// 댓글 추가
  Future<void> addComment(String diaryId, Map<String, dynamic> comment) async {
    try {
      await _firestore
          .collection(_diariesCollection)
          .doc(diaryId)
          .collection(_commentsCollection)
          .add(comment);
    } catch (e) {
      throw Exception('댓글 추가 실패: $e');
    }
  }

  /// 특정 일기의 댓글 가져오기 (실시간 스트림)
  Stream<List<Map<String, dynamic>>> getCommentsStream(String diaryId) {
    return _firestore
        .collection(_diariesCollection)
        .doc(diaryId)
        .collection(_commentsCollection)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  /// 댓글 삭제
  Future<void> deleteComment(String diaryId, String commentId) async {
    try {
      await _firestore
          .collection(_diariesCollection)
          .doc(diaryId)
          .collection(_commentsCollection)
          .doc(commentId)
          .delete();
    } catch (e) {
      throw Exception('댓글 삭제 실패: $e');
    }
  }

  // ==================== User Profile 관련 메서드 ====================

  /// 사용자 프로필 저장/업데이트
  Future<void> saveUserProfile(
      String userId, Map<String, dynamic> profile) async {
    try {
      await _firestore
          .collection(_userProfilesCollection)
          .doc(userId)
          .set(profile, SetOptions(merge: true));
    } catch (e) {
      throw Exception('프로필 저장 실패: $e');
    }
  }

  /// 사용자 프로필 가져오기
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc =
          await _firestore.collection(_userProfilesCollection).doc(userId).get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('프로필 불러오기 실패: $e');
    }
  }

  // ==================== App Goal 관련 메서드 ====================

  /// 앱 목표 저장/업데이트
  Future<void> saveAppGoal(String userId, Map<String, dynamic> goal) async {
    try {
      await _firestore
          .collection(_appGoalsCollection)
          .doc(userId)
          .set(goal, SetOptions(merge: true));
    } catch (e) {
      throw Exception('목표 저장 실패: $e');
    }
  }

  /// 앱 목표 가져오기
  Future<Map<String, dynamic>?> getAppGoal(String userId) async {
    try {
      final doc =
          await _firestore.collection(_appGoalsCollection).doc(userId).get();

      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('목표 불러오기 실패: $e');
    }
  }

  /// 앱 목표 스트림
  Stream<Map<String, dynamic>?> getAppGoalStream(String userId) {
    return _firestore
        .collection(_appGoalsCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return doc.data();
      }
      return null;
    });
  }

  // ==================== 유틸리티 메서드 ====================

  /// Firestore 연결 확인
  Future<bool> checkConnection() async {
    try {
      await _firestore.collection('_health_check').limit(1).get();
      return true;
    } catch (e) {
      return false;
    }
  }
}
