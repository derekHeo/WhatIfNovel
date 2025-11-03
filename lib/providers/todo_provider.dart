import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TodoProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _todos = [
    {'text': '할일', 'isChecked': true},
  ];

  bool _isLoading = false;

  List<Map<String, dynamic>> get todos => _todos;
  bool get isLoading => _isLoading;

  // 생성자에서 Firestore 데이터 로드
  TodoProvider() {
    _loadTodos();
  }

  /// Firestore에서 Todo 데이터 로드
  Future<void> _loadTodos() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('Todo 로드: 로그인된 사용자가 없습니다.');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore
          .collection('todos')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['items'] != null) {
          _todos = List<Map<String, dynamic>>.from(data['items'] as List);
          print('Todo 로드 성공: ${_todos.length}개');
        }
      } else {
        print('Todo 데이터 없음, 기본값 사용');
      }
    } catch (e) {
      print('Todo 로드 에러: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Firestore에 Todo 데이터 저장
  Future<void> _saveTodos() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('Todo 저장: 로그인된 사용자가 없습니다.');
      return;
    }

    try {
      await _firestore
          .collection('todos')
          .doc(user.uid)
          .set({'items': _todos}, SetOptions(merge: true));
      print('Todo 저장 완료');
    } catch (e) {
      print('Todo 저장 에러: $e');
      throw Exception('Todo 저장에 실패했습니다.');
    }
  }

  /// Todo 추가
  Future<void> addTodo(String text) async {
    if (text.isEmpty) return;

    _todos.add({
      'text': text,
      'isChecked': false,
    });
    notifyListeners();
    await _saveTodos();
  }

  /// Todo 체크 상태 변경
  Future<void> toggleTodo(int index) async {
    if (index >= 0 && index < _todos.length) {
      _todos[index]['isChecked'] = !_todos[index]['isChecked'];
      notifyListeners();
      await _saveTodos();
    }
  }

  /// Todo 삭제
  Future<void> deleteTodo(int index) async {
    if (index >= 0 && index < _todos.length) {
      _todos.removeAt(index);
      notifyListeners();
      await _saveTodos();
    }
  }

  /// Todo 모두 초기화 (목표 변경 시 사용)
  Future<void> clearAllTodos() async {
    _todos = [
      {'text': '할일', 'isChecked': true},
    ];
    notifyListeners();
    await _saveTodos();
    print('Todo 초기화 완료');
  }

  /// 로그인 후 Todo를 다시 로드하는 메서드
  Future<void> reloadTodos() async {
    await _loadTodos();
  }
}
