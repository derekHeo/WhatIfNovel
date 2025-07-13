import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/diary_model.dart';
// 💡 아래 import들은 generateNovel 메서드에서 직접 사용하지 않으므로 정리 가능
// import '../models/user_profile.dart';
// import '../services/gpt_service.dart';
// import '../providers/user_profile_provider.dart';

// 💡 GptService는 외부에서 호출하는 것으로 가정
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
    _novelHistory = history
        .map((item) => DiaryModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
    notifyListeners();
  }

  Future<void> _saveHistory() async {
    var box = await Hive.openBox('novel_history');
    await box.put('history', _novelHistory.map((d) => d.toMap()).toList());
  }

  // 💡 --- 여기가 핵심 수정 부분입니다 --- 💡
  // 이제 메서드는 userInput과 fullPrompt를 별도로 받습니다.
  Future<void> generateNovel(String userInput, String fullPrompt) async {
    // GptService에는 프로필 정보가 모두 포함된 fullPrompt를 전달합니다.
    String novel = await GptService.generateNovelFromDiary(fullPrompt);

    // 새로운 DiaryModel 구조에 맞게 인스턴스를 생성합니다.
    final model = DiaryModel(
        userInput: userInput,
        fullPrompt: fullPrompt,
        novel: novel,
        date: DateTime.now());

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

  // 북마크된 소설들만 가져오기
  List<DiaryModel> get bookmarkedNovels =>
      _novelHistory.where((diary) => diary.isBookmarked).toList();

  // 북마크 토글 (특정 인덱스의 항목)
  Future<void> toggleBookmark(int index) async {
    if (index >= 0 && index < _novelHistory.length) {
      final updatedDiary = _novelHistory[index].copyWith(
        isBookmarked: !_novelHistory[index].isBookmarked,
      );
      _novelHistory[index] = updatedDiary;
      await _saveHistory();
      notifyListeners();
    }
  }

  // 💡 'diary' 필드가 'userInput'으로 변경됨에 따라 비교 로직 수정
  Future<void> toggleBookmarkForDiary(DiaryModel targetDiary) async {
    final index = _novelHistory.indexWhere((diary) =>
        diary.date == targetDiary.date &&
        diary.userInput == targetDiary.userInput);

    if (index != -1) {
      await toggleBookmark(index);
    }
  }

  // 💡 'diary' 필드가 'userInput'으로 변경됨에 따라 비교 로직 수정
  bool isBookmarked(DiaryModel diary) {
    final index = _novelHistory.indexWhere(
        (d) => d.date == diary.date && d.userInput == diary.userInput);
    return index != -1 ? _novelHistory[index].isBookmarked : false;
  }

  // 💡 테스트 데이터도 새로운 모델 구조에 맞게 수정
  Future<void> addTestData() async {
    final testNovel = '''
1편: 「스마트폰의 유혹」
... (소설 내용 생략) ...
    ''';

    final testUserInput =
        "내가 취업 준비를 해야하는데, 너무 피곤해서 게임을 한 번만 하고 잠들려고 했는데 5시간 정도해서 2시간이 지나버렸어";

    final testDiary = DiaryModel(
      userInput: testUserInput,
      // 테스트 데이터에서는 userInput과 fullPrompt를 동일하게 설정해도 무방
      fullPrompt: testUserInput,
      novel: testNovel,
      date: DateTime.now(),
    );

    _novelHistory.insert(0, testDiary);
    await _saveHistory();
    notifyListeners();
  }
}
