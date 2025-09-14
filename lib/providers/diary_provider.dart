import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import '../models/diary_model.dart';
import '../models/user_profile.dart'; // 💡 1. UserProfile 모델 import 추가
import '../services/gpt_service.dart';
import 'user_profile_provider.dart';

class DiaryProvider with ChangeNotifier {
  // 💡 2. 데이터 소스를 _diaries 하나로 통일합니다.
  List<DiaryModel> _diaries = [];
  DiaryModel? _lastNovel;
  bool _isLoading = false;

  List<DiaryModel> get diaries => [..._diaries];
  DiaryModel? get lastNovel => _lastNovel;
  bool get isLoading => isLoading;

  DiaryProvider() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    var box = await Hive.openBox('novel_history');
    final List history = box.get('history', defaultValue: []);
    // 💡 3. _novelHistory 대신 _diaries에 로드합니다.
    _diaries = history
        .map((item) => DiaryModel.fromMap(Map<String, dynamic>.from(item)))
        .toList();
    notifyListeners();
  }

  Future<void> _saveHistory() async {
    var box = await Hive.openBox('novel_history');
    // 💡 4. _diaries의 내용을 저장합니다.
    await box.put('history', _diaries.map((d) => d.toMap()).toList());
  }

  Future<void> generateGoalBasedNovel({
    required BuildContext context,
    required Map<String, int?> appGoals,
    required List<Map<String, dynamic>> todoList,
    required Map<String, double> appUsage,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final profileProvider =
          Provider.of<UserProfileProvider>(context, listen: false);
      final userProfile = profileProvider.userProfile;

      final todoSummary = _createTodoSummary(todoList);
      final appUsageSummary = _createAppUsageSummary(appGoals, appUsage);
      final profileDetails = _createProfileDetails(userProfile);

      final finalPrompt = _buildFinalPrompt(
        profileDetails: profileDetails,
        appUsageSummary: appUsageSummary,
        todoSummary: todoSummary,
      );

      final generatedText = await GptService.generateNovel(finalPrompt);

      final title =
          generatedText.split('\n').first.replaceFirst('시나리오:', '').trim();
      final content = generatedText.substring(title.length + 10).trim();

      _lastNovel = DiaryModel(
        id: DateTime.now().toIso8601String(),
        title: title,
        content: content,
        userInput: "목표 기반 시나리오",
        createdAt: DateTime.now(),
      );
      _diaries.add(_lastNovel!);
      await _saveHistory(); // 💡 5. 새 소설 생성 후 저장 로직 호출
    } catch (e) {
      print(e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _createTodoSummary(List<Map<String, dynamic>> todoList) {
    if (todoList.isEmpty) return "작성된 To-do 리스트가 없습니다.";
    final total = todoList.length;
    final completed =
        todoList.where((item) => item['isChecked'] == true).length;
    final achievementRate =
        total > 0 ? (completed / total * 100).toStringAsFixed(0) : 0;

    final completedItems = todoList
        .where((item) => item['isChecked'] == true)
        .map((item) => "- ${item['text']} (완료)")
        .join('\n');
    final pendingItems = todoList
        .where((item) => item['isChecked'] == false)
        .map((item) => "- ${item['text']} (미완료)")
        .join('\n');

    return """
- 총 To-do: $total개, 완료: $completed개 (달성률: $achievementRate%)
- 완료된 항목:\n$completedItems
- 미완료된 항목:\n$pendingItems
""";
  }

  String _createAppUsageSummary(
      Map<String, int?> appGoals, Map<String, double> appUsage) {
    String summary = "";
    appGoals.forEach((appName, goalHours) {
      if (goalHours != null) {
        final usageHours = appUsage[appName] ?? 0.0;
        final rate = goalHours > 0
            ? (usageHours / goalHours * 100).toStringAsFixed(0)
            : "0";
        summary +=
            "- $appName: 목표 ${goalHours}시간, 실제 사용 ${usageHours.toStringAsFixed(1)}시간 (목표 대비 $rate% 사용)\n";
      }
    });
    return summary;
  }

  String _createProfileDetails(UserProfile userProfile) {
    return """
- 이름: ${userProfile.name}
- 직업: ${userProfile.job ?? '정보 없음'}
- 단기 목표: ${userProfile.shortTermGoal ?? '정보 없음'}
- 장기 목표: ${userProfile.longTermGoal ?? '정보 없음'}
- 성격/스타일: ${userProfile.styleAnswers?.values.expand((x) => x).join(', ') ?? '정보 없음'}
""";
  }

  // 💡 6. 비어있던 함수 내용을 채웁니다.
  String _buildFinalPrompt({
    required String profileDetails,
    required String appUsageSummary,
    required String todoSummary,
  }) {
    return '''
너는 사용자의 하루를 데이터 기반으로 분석하고 성찰적인 단편 소설을 써주는 '라이프 스토리텔러'야. 제공된 데이터를 바탕으로, 사용자가 보냈을 법한 하루를 현실적으로, 그리고 감성적으로 재구성해줘.

[사용자 프로필]
$profileDetails

[앱 사용 목표 및 결과]
$appUsageSummary

[To-do 리스트 결과]
$todoSummary

==== 작성 지침 ====
1.  **데이터 분석**: 목표와 실제 사용 시간의 '차이'에 주목해. 목표를 초과했다면 왜 그랬을지(예: 스트레스, 휴식), 목표보다 적게 썼다면 어떤 노력을 했는지 상상해봐.
2.  **To-do 리스트와 연결**: To-do 달성률이 높다면 성실하고 뿌듯한 하루, 낮다면 무기력하거나 예상치 못한 일이 생긴 하루로 묘사해봐. 완료된 To-do 항목을 이야기 속에 자연스럽게 언급해줘.
3.  **현실 기반의 서사**: 사용자의 프로필(직업, 목표 등)과 그날의 데이터를 긴밀하게 연결해. 예를 들어, '개발자'가 목표보다 유튜브를 많이 봤다면, '코드가 막혀 머리를 식히기 위해'라는 식으로 개연성을 부여해.
4.  **내면 묘사**: 단순히 사실을 나열하지 마. 그날의 성과에 대한 감정(성취감, 아쉬움, 만족감, 불안감 등)을 1인칭 시점으로 섬세하게 묘사해줘.
5.  **출력 형식**: 첫 줄에는 '시나리오: {소설 제목}'을 쓰고, 다음 줄부터 본문을 1200자 내외로 작성해. 메타 설명은 절대 넣지 마.
''';
  }

  // 💡 아래 모든 함수들이 _novelHistory 대신 _diaries를 사용하도록 수정합니다.
  Future<void> removeNovelAt(int idx) async {
    _diaries.removeAt(idx);
    await _saveHistory();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _diaries.clear();
    await _saveHistory();
    notifyListeners();
  }

  List<DiaryModel> get bookmarkedNovels =>
      _diaries.where((diary) => diary.isBookmarked).toList();

  Future<void> toggleBookmark(int index) async {
    if (index >= 0 && index < _diaries.length) {
      final updatedDiary = _diaries[index].copyWith(
        isBookmarked: !_diaries[index].isBookmarked,
      );
      _diaries[index] = updatedDiary;
      await _saveHistory();
      notifyListeners();
    }
  }

  Future<void> toggleBookmarkForDiary(DiaryModel targetDiary) async {
    final index = _diaries.indexWhere((diary) => diary.id == targetDiary.id);

    if (index != -1) {
      await toggleBookmark(index);
    }
  }

  bool isBookmarked(DiaryModel diary) {
    final index = _diaries.indexWhere((d) => d.id == diary.id);
    return index != -1 ? _diaries[index].isBookmarked : false;
  }
}
