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
    required Map<String, int> appUsage,
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

    // 기본 정보
    buffer.writeln('=== 기본 정보 ===');
    buffer.writeln('이름: ${userProfile.name}');
    if (userProfile.birthYear != null) {
      final age = DateTime.now().year - userProfile.birthYear!;
      buffer.writeln('나이: ${age}세');
    }
    if (userProfile.gender != null && userProfile.gender!.isNotEmpty) {
      buffer.writeln('성별: ${userProfile.gender}');
    }
    if (userProfile.job != null && userProfile.job!.isNotEmpty) {
      buffer.writeln('직업: ${userProfile.job}');
    }

    // 목표 및 활동
    buffer.writeln('\n=== 목표 및 활동 ===');
    if (userProfile.shortTermGoal != null &&
        userProfile.shortTermGoal!.isNotEmpty) {
      buffer.writeln('단기 목표: ${userProfile.shortTermGoal}');
    }
    if (userProfile.longTermGoal != null &&
        userProfile.longTermGoal!.isNotEmpty) {
      buffer.writeln('장기 목표: ${userProfile.longTermGoal}');
    }
    if (userProfile.additionalInfo != null &&
        userProfile.additionalInfo!.isNotEmpty) {
      buffer.writeln('요즘 하는 일: ${userProfile.additionalInfo}');
    }

    // 성격/스타일
    if (userProfile.styleAnswers != null &&
        userProfile.styleAnswers!.isNotEmpty) {
      buffer.writeln('\n=== 성격/스타일 ===');
      final styleText = _formatStyleAnswers(userProfile.styleAnswers);
      buffer.writeln(styleText);
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
      Map<String, int?> appGoals, Map<String, int> appUsage) {
    String summary = "";
    appGoals.forEach((appName, goalMinutes) {
      if (goalMinutes != null) {
        final usageMinutes = appUsage[appName] ?? 0;
        final rate = goalMinutes > 0
            ? (usageMinutes / goalMinutes * 100).toStringAsFixed(0)
            : "0";

        // 분을 시간과 분으로 변환하여 표시
        final goalHours = goalMinutes ~/ 60;
        final goalMins = goalMinutes % 60;
        final usageHours = usageMinutes ~/ 60;
        final usageMins = usageMinutes % 60;

        summary +=
            "- $appName: 목표 ${goalHours}시간 ${goalMins}분, 실제 사용 ${usageHours}시간 ${usageMins}분 (목표 대비 $rate% 사용)\n";
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
      Map<String, int?> appGoals, Map<String, int> appUsage) {
    String detail = "";
    appGoals.forEach((appName, goalMinutes) {
      if (goalMinutes != null) {
        final usageMinutes = appUsage[appName] ?? 0;
        final isOver = usageMinutes > goalMinutes;
        final diffMinutes = (usageMinutes - goalMinutes).abs();

        // 분을 시간과 분으로 변환
        final diffHours = diffMinutes ~/ 60;
        final diffMins = diffMinutes % 60;

        if (isOver) {
          detail += "$appName: 목표보다 ${diffHours}시간 ${diffMins}분 초과. ";
        } else {
          detail += "$appName: 목표보다 ${diffHours}시간 ${diffMins}분 적게 사용. ";
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
    required Map<String, int> appUsage,
    required List<Map<String, dynamic>> todoList,
  }) {
    // 기본 정보
    final name = userProfile.name;
    final age = _calculateAge(userProfile);
    final gender = userProfile.gender ?? "정보 없음";
    final job = userProfile.job ?? "정보 없음";

    // 목표 정보
    final longTermGoal = userProfile.longTermGoal ?? "정보 없음";
    final shortTermGoal = userProfile.shortTermGoal ?? "정보 없음";
    final currentActivities = userProfile.additionalInfo ?? "정보 없음";

    // 성격/스타일 정보
    final styleAnswers = userProfile.styleAnswers;
    final copingStyle = _formatStyleAnswers(styleAnswers);

    // 달성률 정보
    final appAchievementDetail =
        _createAppAchievementDetail(appGoals, appUsage);
    final dailyAchievementRate = _calculateDailyAchievementRate(todoList);
    final todayTasks = _extractTodayTasks(todoList);

    return '''
당신은 사용자의 스마트폰 사용 패턴을 기반으로 두 가지 대비되는 미래 시나리오를 작성하는 스토리텔러입니다.
사용자 입력 데이터
=== 기본 정보 ===
- name: $name
- age: $age
- gender: $gender
- job: $job

=== 목표 및 활동 ===
- long_term_goal(사용자의 장기적인 목표): $longTermGoal
- short_term_goal(사용자의 단기적인 목표): $shortTermGoal
- current_activities(현재 진행 중인 활동들): $currentActivities

=== 성격/스타일 ===
- coping_style(성격): $copingStyle

=== 오늘의 달성률 ===
- app_achievement_detail(앱별 목표시간/실제사용시간): $appAchievementDetail
- daily_achievement_rate(전체 달성률): $dailyAchievementRate%
- today_tasks(오늘 할 일 목록과 달성 여부): $todayTasks

성공/실패 판단
* 성공: 3개 앱 목표시간 모두 준수 → 앱 사용을 잘 조절한 결과로 찾아온 긍정적인 미래
* 실패: 하나라도 초과 → 앱 사용을 조절하지 못했다면 벌어졌을 부정적 미래
* 초과 정도(5분 vs 2시간)에 따라 시나리오 강도 조절

**시나리오 구성**
1. What you did: 실제 사용자의 행동 결과 시나리오
   * 사용자가 실제로 성공했으면 긍정적 미래 작성
   * 사용자가 실제로 실패했으면 부정적 미래 작성

2. What if you didn't: 대안 행동의 결과를 보여주는 시나리오
   * 실제 성공 → 대안은 실패 (부정적 미래)
   * 실제 실패 → 대안은 성공 (긍정적 미래)
   * "만약 ~했더라면?"이 아니라 그 결과를 직접적으로 보여주기

**작성 원칙**
* 주인공은 '나'로 설정 (1인칭 시점)
* 충격적이고 자극적으로 작성 (사용자가 충격받을 정도로)
* 매번 다른 소재와 레파토리 사용 (건강, 인간관계, 커리어, 돈, 사고, 우연한 기회 등 다양하게)
* 중요: 과거/현재(어제, 오늘)의 일과는 절대 만들어내지 않음
* 미래 시나리오 작성 시 "3개월 후, 1년 후" 같은 딱딱한 시간 표현 금지
* 자연스럽게 시간이 흐르는 소설 형식으로 작성
* 사용자 정보는 참고만 하고, 창의적인 미래 전개 가능
* 할 일 미완성 때문에 나쁜 미래라는 단순 인과 지양
* 과정은 현실적이고 공감 가능하게 (결론은 과장 가능)
* 행동-결과의 대비가 명확하게

**핵심 추가 요소: 시간의 시각화**
* 부정적 시나리오에서는 무의미하게 소비된 시간의 누적 효과를 구체적으로 묘사
* 예시: "하루 2시간씩 흘러간 시간들이 쌓여 수백 시간이 되었고..."
* 숫자로 환산된 시간 손실을 생생하게 표현 (예: "한 달이면 60시간, 일주일치 시간")
* 그 시간에 할 수 있었던 구체적인 일들을 대비시켜 보여주기
* 손가락 스크롤 동작의 반복, 화면을 보는 자세의 누적 등 신체적 변화도 암시
* "그 순간순간은 짧았지만, 모이고 모여..."와 같은 시간 누적의 무게감 강조
* 긍정적 시나리오에서는 그 시간을 다른 곳에 투자했을 때의 가시적 성과 제시

**출력 형식**
각 시나리오는 정확히 750-850토큰 분량으로 작성하세요.
## What you did (성공/실패)
[시나리오 내용]
## What if you didn't (실패/성공)
[시나리오 내용]
''';
  }

  // 나이 계산 헬퍼 함수
  String _calculateAge(UserProfile userProfile) {
    if (userProfile.birthYear == null) return "정보 없음";

    final currentYear = DateTime.now().year;
    final age = currentYear - userProfile.birthYear!;
    return "${age}세";
  }

  // 스타일 답변 포맷팅 헬퍼 함수
  String _formatStyleAnswers(Map<String, List<String>>? styleAnswers) {
    if (styleAnswers == null || styleAnswers.isEmpty) {
      return "정보 없음";
    }

    final buffer = StringBuffer();
    styleAnswers.forEach((question, answers) {
      if (answers.isNotEmpty) {
        buffer.write(answers.join(', '));
        buffer.write(' / ');
      }
    });

    String result = buffer.toString();
    if (result.endsWith(' / ')) {
      result = result.substring(0, result.length - 3);
    }

    return result.isEmpty ? "정보 없음" : result;
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
