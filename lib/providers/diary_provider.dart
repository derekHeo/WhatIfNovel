import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/diary_model.dart';
import '../models/user_profile.dart'; // UserProfile 모델 import 추가
import '../services/gpt_service.dart';
import '../providers/user_profile_provider.dart';

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

  // 업데이트된 generateNovel 메서드 (중복 제거)
  Future<void> generateNovel(String diary,
      {UserProfileProvider? profileProvider}) async {
    // 사용자 프로필 정보 가져오기
    String? profileInfo;
    if (profileProvider != null) {
      profileInfo = profileProvider.getProfileForPrompt();
    }

    // GPT 서비스 호출 시 프로필 정보 전달
    String novel = await GptService.generateNovelFromDiary(diary,
        userProfileInfo: profileInfo);

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

  // 특정 DiaryModel의 북마크 토글
  Future<void> toggleBookmarkForDiary(DiaryModel targetDiary) async {
    final index = _novelHistory.indexWhere((diary) =>
        diary.date == targetDiary.date && diary.diary == targetDiary.diary);

    if (index != -1) {
      await toggleBookmark(index);
    }
  }

  // 북마크 상태 확인
  bool isBookmarked(DiaryModel diary) {
    final index = _novelHistory
        .indexWhere((d) => d.date == diary.date && d.diary == diary.diary);
    return index != -1 ? _novelHistory[index].isBookmarked : false;
  }

  // 테스트용 더미 데이터 추가
  Future<void> addTestData() async {
    final testNovel = '''
1편: 「스마트폰의 유혹」

이하준, 25세. 피곤했다.
취업 준비를 해야 하는 걸 알았지만, 의지력이 부족했다.

"게임 한 번만 하고 공부하자."

그 한 번은 두 번이 되고, 다섯 번이 되었고, 그렇게 2시간이 지나버렸다.
면접은 8시에 예정되어 있었다.
그는 7시 59분에 노트를 열었고, 머릿속 대답들은 이미 사라져 있었다.

"하은님, 답변 저는 어디 계신가요?"
"자기소개도 준비해주시면 감사하겠습니다."
"혹시 무슨 일 있으십니까?"

하은은 마우스를 움직였지만, 손끝이 떨렸다.
답변은 만들어지지 않았다. 아니, 아예 시작도 못 했다.

2편: 「다른 선택」

그날 하은은 핸드폰 없이 시작하였고,
계획표는 차근차근 진행되었다.

8시 면접장에서 그는 자신감 넘치는 목소리로 대답했다.
"제가 이 회사에 지원한 이유는..."

면접관들의 고개가 끄덕였다.
그리고 2주 후, 합격 통보를 받았다.
    ''';

    final testDiary = DiaryModel(
      diary:
          "내가 취업 준비를 해야하는데, 너무 피곤해서 게임을 한 번만 하고 잠들려고 했는데 5시간 정도해서 2시간이 지나버렸어",
      novel: testNovel,
      date: DateTime.now(),
    );

    _novelHistory.insert(0, testDiary);
    await _saveHistory();
    notifyListeners();
  }
}
