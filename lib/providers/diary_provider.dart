//diary_provider.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/diary_model.dart';
import '../models/user_profile.dart';
import '../services/claude_service.dart';
import '../services/firestore_service.dart';
import 'user_profile_provider.dart';

class DiaryProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  List<DiaryModel> _diaries = [];
  DiaryModel? _lastNovel;
  bool _isLoading = false;

  List<DiaryModel> get diaries => [..._diaries];
  DiaryModel? get lastNovel => _lastNovel;
  bool get isLoading => _isLoading;

  DiaryProvider() {
    _loadHistory();
  }

  /// Firestore에서 일기 목록 로드
  Future<void> _loadHistory() async {
    try {
      _diaries = await _firestoreService.getDiaries();
      notifyListeners();
    } catch (e) {
      print('일기 로드 실패: $e');
    }
  }

  /// Firestore에 일기 저장
  Future<void> _saveDiary(DiaryModel diary) async {
    try {
      await _firestoreService.createDiary(diary);
    } catch (e) {
      print('일기 저장 실패: $e');
      rethrow;
    }
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
        userProfile: userProfile,
        appGoals: appGoals,
        appUsage: appUsage,
        todoList: todoList,
      );

      final generatedText = await ClaudeService.generateNovel(finalPrompt);

      // 웹 호환성을 위한 안전한 문자열 파싱
      print('생성된 텍스트 타입: ${generatedText.runtimeType}');
      print('생성된 텍스트 길이: ${generatedText.length}');
      print(
          '생성된 텍스트 첫 100자: ${generatedText.length > 100 ? generatedText.substring(0, 100) : generatedText}');

      // userInput 생성: todo + 프로필 정보 (단기목표, 장기목표, current activities)
      final userInputText = _createUserInputText(
        userProfile: userProfile,
        todoList: todoList,
      );

      _lastNovel = DiaryModel(
        id: DateTime.now().toIso8601String(),
        content: generatedText,
        userInput: userInputText,
        createdAt: DateTime.now(),
        // 앱 사용량 정보 저장
        appGoals: Map<String, dynamic>.from(
            appGoals.map((key, value) => MapEntry(key, value))),
        appUsage: Map<String, dynamic>.from(
            appUsage.map((key, value) => MapEntry(key, value))),
      );

      // Firestore에 저장
      print('Firestore 저장 시작...');
      await _saveDiary(_lastNovel!);
      print('Firestore 저장 완료');

      // 로컬 리스트에도 추가
      _diaries.insert(0, _lastNovel!); // 최신순으로 맨 앞에 추가
      print('로컬 리스트 추가 완료');
    } catch (e, stackTrace) {
      print('일기 생성 중 오류 발생');
      print('오류 타입: ${e.runtimeType}');
      print('오류 내용: $e');
      print('스택 트레이스: $stackTrace');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// userInput 생성: todo + 프로필 정보
  String _createUserInputText({
    required UserProfile userProfile,
    required List<Map<String, dynamic>> todoList,
  }) {
    final buffer = StringBuffer();

    // 프로필 정보
    buffer.writeln('=== 프로필 정보 ===');
    if (userProfile.shortTermGoal != null && userProfile.shortTermGoal!.isNotEmpty) {
      buffer.writeln('단기 목표: ${userProfile.shortTermGoal}');
    }
    if (userProfile.longTermGoal != null && userProfile.longTermGoal!.isNotEmpty) {
      buffer.writeln('장기 목표: ${userProfile.longTermGoal}');
    }
    if (userProfile.additionalInfo != null && userProfile.additionalInfo!.isNotEmpty) {
      buffer.writeln('요즘 하는 일: ${userProfile.additionalInfo}');
    }

    // Todo 리스트
    buffer.writeln('\n=== 오늘의 할 일 ===');
    if (todoList.isEmpty) {
      buffer.writeln('작성된 할 일이 없습니다.');
    } else {
      for (var todo in todoList) {
        final text = todo['text'] ?? '';
        final isChecked = todo['isChecked'] ?? false;
        final status = isChecked ? '✓' : '☐';
        buffer.writeln('$status $text');
      }
    }

    return buffer.toString();
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

  // 새로운 데이터 처리 함수들 추가
  String _createAppAchievementDetail(
      Map<String, int?> appGoals, Map<String, double> appUsage) {
    String detail = "";
    appGoals.forEach((appName, goalHours) {
      if (goalHours != null) {
        final usageHours = appUsage[appName] ?? 0.0;
        final isOver = usageHours > goalHours;
        final diff = (usageHours - goalHours).abs();

        if (isOver) {
          detail += "$appName: 목표보다 ${diff.toStringAsFixed(1)}시간 초과. ";
        } else {
          detail += "$appName: 목표보다 ${diff.toStringAsFixed(1)}시간 적게 사용. ";
        }
      }
    });
    return detail.trim();
  }

  double _calculateDailyAchievementRate(List<Map<String, dynamic>> todoList) {
    if (todoList.isEmpty) return 0.0;
    final completed =
        todoList.where((item) => item['isChecked'] == true).length;
    return (completed / todoList.length * 100);
  }

  String _extractTodayTasks(List<Map<String, dynamic>> todoList) {
    final completed = todoList
        .where((item) => item['isChecked'] == true)
        .map((item) => item['text'])
        .join(', ');
    final incomplete = todoList
        .where((item) => item['isChecked'] == false)
        .map((item) => item['text'])
        .join(', ');

    String result = "";
    if (completed.isNotEmpty) result += "완료: $completed. ";
    if (incomplete.isNotEmpty) result += "미완료: $incomplete.";
    return result.trim();
  }

  // 새로운 프롬프트 생성 함수
  String _buildFinalPrompt({
    required String profileDetails,
    required String appUsageSummary,
    required String todoSummary,
    required UserProfile userProfile,
    required Map<String, int?> appGoals,
    required Map<String, double> appUsage,
    required List<Map<String, dynamic>> todoList,
  }) {
    final longTermGoal = userProfile.longTermGoal ?? "정보 없음";
    final shortTermGoal = userProfile.shortTermGoal ?? "정보 없음";
    final appAchievementDetail =
        _createAppAchievementDetail(appGoals, appUsage);
    final dailyAchievementRate = _calculateDailyAchievementRate(todoList);
    final todayTasks = _extractTodayTasks(todoList);
    final selectedStyleAnswers = userProfile.styleAnswers ?? "정보 없음";

    return '''
당신은 평행우주의 두 가지 하루를 기록하는 반사실적 스토리텔러다. 조건 * 작은 선택 하나가 성공과 실패를 가르는 극적인 차이를 보여줄 것., * 성공 서사에서는 구체적인 성취를 계속 이루었을 때의 압도적으로 긍정적인 미래를 보여줄 것., * 실패 서사에서는 단순한 아쉬움이 아니라, 삶 전체가 붕괴되고 비극적으로 마무리된 결과를 반드시 생생히 묘사할 것., * 실패는 하루가 망친 정도가 아니라, 반복과 누적 끝에 학업, 건강, 인간관계, 미래 계획이 모두 파국을 맞고 결국 삶이 비극적으로 끝나버린 상태로 표현할 것., * 반드시 “~되었다 / ~였다” 완료형으로 작성해, 미래 예측이 아닌 이미 벌어진 현실처럼 들리도록 할 것., * 두 이야기는 각각 소제목을 달아 “성공한 하루”와 “실패한 하루”로 뚜렷이 구분할 것., * 직접적인 교훈 문장은 쓰지 않고, 이야기 전개만으로 독자가 스스로 압박감과 경각심을 느끼게 할 것., 입력 데이터##### --- 작성 프로세스 1단계: 스토리 설계 추론 <think> 다음 사항들을 차례대로 분석하고 추론하라: 1. 목표와 할 일의 연관성 분석 * today_tasks 각각이 short_term_goal 달성에 어떻게 기여하는가?, * short_term_goal이 long_term_goal 실현에 어떤 역할을 하는가?, * current_activities가 전체 목표 체계와 어떻게 연결되는가?, ,
1. 성공 요인과 실제적 결과 분석
   * coping_style이 성공에 어떤 자연스러운 영향을 미쳤는가?,
   * 오늘의 성공이 실질적으로 어떤 변화를 가져올 것인가?,
   * 이 성공이 다음 단계 목표 달성에 미치는 실용적 영향은?,
   * app_achievement_detail과 daily_achievement_rate가 보여주는 성과는?, ,

실패 가능성과 그 결과 분석
어떤 선택이 실패로 이어질 수 있었는가?,
오늘의 실패가 목표 달성에 미칠 실질적 악영향은?,
놓친 기회의 실제적 손실은 무엇인가?,
coping_style이 실패에 어떤 미묘한 영향을 미칠 수 있었는가?, ,

전환점과 선택의 실용성
어떤 구체적 순간에서 성공과 실패가 갈라졌는가?,
그 순간의 선택이 실제로 결과를 바꾸는 이유는?,
작은 행동이 큰 차이를 만드는 메커니즘은?, ,

스토리 구성과 재미 요소
사용자의 개인적 특성(나이, 직업, 성격)을 어떻게 자연스럽게 반영할 것인가?,
coping_style을 직접 언급하지 않고 행동과 사고 패턴으로 어떻게 보여줄 것인가?,
흥미로운 상황이나 반전 요소를 어떻게 넣을 것인가?,
독자가 몰입할 수 있는 구체적 장면은 무엇인가?,
적절한 유머나 위트를 어떻게 포함시킬 것인가?,
특히 실패 서사에서는 삶이 최종적으로 비극적 종말을 맞이한 상태를 이미 되어버린 현실처럼 생생히 묘사하여, 독자가 강렬한 좌절감과 경각심을 느낄 수 있도록 할 것., , </think> 
--- 2단계: 소설 작성 작성 지침
총 분량: 1000~1400자,
성공 서사: 500~700자, 구체적인 성취를 계속 이루었을 때의 압도적으로 긍정적인 미래 묘사,
실패 서사: 500~700자, 작은 미루기가 반복되어 결국 삶이 완전히 붕괴되고 비극적으로 마무리된 상태를 이미 경험한 듯 묘사,
시점: 1인칭,
문체: 현실적이고 생생한 웹소설 톤,
반드시 완료형(“~되었다 / ~였다”)으로 서술할 것.,
반드시 소제목을 넣어 “성공한 하루” vs “실패한 하루”가 명확히 구분되도록 작성할 것.,
마지막에 교훈이나 결론을 직접 쓰지 않는다. 이야기 자체가 독자에게 숨 막히는 절망과 경각심을 남겨야 한다.
사용자 입력 데이터
- long_term_goal: {$longTermGoal}
- short_term_goal: {$shortTermGoal}
- current_activities: {$todayTasks}
- coping_style: {$selectedStyleAnswers}
- app_achievement_detail: {$appAchievementDetail}
- daily_achievement_rate: {$dailyAchievementRate}%
- today_tasks: {$todayTasks}
''';
  }

  /// 특정 인덱스의 일기 삭제
  Future<void> removeNovelAt(int idx) async {
    if (idx >= 0 && idx < _diaries.length) {
      final diaryId = _diaries[idx].id;
      try {
        await _firestoreService.deleteDiary(diaryId);
        _diaries.removeAt(idx);
        notifyListeners();
      } catch (e) {
        print('일기 삭제 실패: $e');
        rethrow;
      }
    }
  }

  /// 모든 일기 삭제
  Future<void> clearHistory() async {
    try {
      // 모든 일기를 Firestore에서 삭제
      for (var diary in _diaries) {
        await _firestoreService.deleteDiary(diary.id);
      }
      _diaries.clear();
      notifyListeners();
    } catch (e) {
      print('전체 삭제 실패: $e');
      rethrow;
    }
  }

  /// Firestore에서 실시간으로 일기 목록 스트림 구독
  Stream<List<DiaryModel>> get diariesStream {
    return _firestoreService.getDiariesStream();
  }

  /// 일기 새로고침
  Future<void> refreshDiaries() async {
    await _loadHistory();
  }

//   List<DiaryModel> get bookmarkedNovels =>
//       _diaries.where((diary) => diary.isBookmarked).toList();

//   Future<void> toggleBookmark(int index) async {
//     if (index >= 0 && index < _diaries.length) {
//       final updatedDiary = _diaries[index].copyWith(
//         isBookmarked: !_diaries[index].isBookmarked,
//       );
//       _diaries[index] = updatedDiary;
//       await _saveHistory();
//       notifyListeners();
//     }
//   }

//   Future<void> toggleBookmarkForDiary(DiaryModel targetDiary) async {
//     final index = _diaries.indexWhere((diary) => diary.id == targetDiary.id);

//     if (index != -1) {
//       await toggleBookmark(index);
//     }
//   }

//   bool isBookmarked(DiaryModel diary) {
//     final index = _diaries.indexWhere((d) => d.id == diary.id);
//     return index != -1 ? _diaries[index].isBookmarked : false;
//   }
}
