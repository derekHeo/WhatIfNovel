import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/diary_model.dart';
import '../services/gpt_service.dart';

class DiaryProvider with ChangeNotifier {
  List<DiaryModel> _novelHistory = [];
  DiaryModel? _lastNovel;

  List<DiaryModel> get novelHistory => _novelHistory;
  DiaryModel? get lastNovel => _lastNovel;

  DiaryProvider() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    var box = await Hive.openBox('novel_history');
    final List history = box.get('history', defaultValue: []);
    _novelHistory =
        history.map((item) => DiaryModel.fromMap(Map<String, dynamic>.from(item))).toList();
    notifyListeners();
  }

  Future<void> _saveHistory() async {
    var box = await Hive.openBox('novel_history');
    await box.put('history', _novelHistory.map((d) => d.toMap()).toList());
  }

  Future<void> generateNovel(String diary) async {
    String novel = await GptService.generateNovelFromDiary(diary);
    final model = DiaryModel(diary: diary, novel: novel, date: DateTime.now());
    _lastNovel = model;
    _novelHistory.insert(0, model); // 최신순
    await _saveHistory();
    notifyListeners();
  }

  Future<void> removeNovelAt(int idx) async {
    _novelHistory.removeAt(idx);
    await _saveHistory();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _novelHistory.clear();
    await _saveHistory();
    notifyListeners();
  }

  // (선택) 더미 데이터 자동 저장
  Future<void> addDummyData() async {
    final dummy = DiaryModel(
      diary: "예시 일지: 오늘도 폰을 너무 오래 썼다.",
      novel: "예시 소설: 그는 또다시 유혹에 져버렸다...",
      date: DateTime.now(),
    );
    _novelHistory.insert(0, dummy);
    await _saveHistory();
    notifyListeners();
  }
}
