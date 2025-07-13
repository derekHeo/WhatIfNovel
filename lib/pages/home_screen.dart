import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/diary_provider.dart';
import '../providers/user_profile_provider.dart';
import '../models/diary_model.dart';
import 'settings_screen.dart';
import 'diary_list_page.dart';
import 'novel_detail_page.dart';
import 'bookmark_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;

  int? _studyHours;
  int? _sleepHours;
  int? _exerciseHours;

  // 💡 --- 여기가 핵심 수정 부분입니다 --- 💡
  Future<void> _generateNovelFromSelection() async {
    // 1. 시간 선택 유효성 검사
    if (_studyHours == null || _sleepHours == null || _exerciseHours == null) {
      _showAlert('모든 시간을 선택해주세요.');
      return;
    }
    if ((_studyHours! + _sleepHours!) > 24) {
      _showAlert('선택한 시간의 총합(공부+수면)이 24시간을 초과할 수 없습니다. 다시 선택해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);
      final profileProvider =
          Provider.of<UserProfileProvider>(context, listen: false);
      final userProfile = profileProvider.userProfile;

      // 2. 사용자에게 보여줄 입력값 (userInput) 정의
      final userInput =
          "하루 공부 ${_studyHours}시간, 하루 수면 ${_sleepHours}시간, 일주일에 운동 ${_exerciseHours}시간";

      // 3. AI에게 전달할 상세 프로필 정보 (profileDetails) 정의
      final profileDetails = """
      - 이름: ${userProfile.name}
      - 직업: ${userProfile.job ?? '정보 없음'}
      - 성별: ${userProfile.gender ?? '정보 없음'}
      - 요즘 하는 일: ${userProfile.additionalInfo ?? '정보 없음'}
      - 단기 목표: ${userProfile.shortTermGoal ?? '정보 없음'}
      - 장기 목표: ${userProfile.longTermGoal ?? '정보 없음'}
      - 추가적인 설명: ${userProfile.extraInfo ?? '정보 없음'}
      - 성격/스타일: ${userProfile.styleAnswers?.values.expand((x) => x).join(', ') ?? '정보 없음'}
      """;

      // 4. AI에게 보낼 최종 프롬프트 (fullPrompt) 조합
      final fullPrompt =
          "아래 정보를 가진 사람의 미래를 예측해서 소설을 써줘.\n\n[프로필 정보]\n$profileDetails\n\n[선택한 시간]\n$userInput";

      // 5. 수정한 Provider의 generateNovel 함수 호출
      await diaryProvider.generateNovel(userInput, fullPrompt);

      final lastNovel = diaryProvider.lastNovel;
      if (lastNovel != null) {
        _showSuccessAlert(lastNovel);
      } else {
        _showAlert('소설 생성에 실패했습니다.');
      }
    } catch (e) {
      _showAlert('오류가 발생했습니다: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAlert(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('확인'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showSuccessAlert(DiaryModel generatedNovel) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('완료!'),
        content: const Text('소설이 생성되었습니다!\n바로 확인하시겠어요?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('나중에'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('확인'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => NovelDetailPage(diary: generatedNovel),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFCF3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.menu,
            color: Colors.black,
            size: 24,
          ),
          onPressed: () {
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            );
          },
        ),
        title: const Text(''),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              '선택한 목표 시간을 바탕으로,\nAI가 다른 미래를 예측해 보여드립니다.\n지금 당신의 선택이 어떤 결과를 만들 수 있을지 확인해보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF333333),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 60),
            _buildTimeSelectorRow('하루에', '공부', _studyHours, (value) {
              setState(() {
                _studyHours = value;
              });
            }),
            const SizedBox(height: 20),
            _buildTimeSelectorRow('하루에', '수면', _sleepHours, (value) {
              setState(() {
                _sleepHours = value;
              });
            }),
            const SizedBox(height: 20),
            _buildTimeSelectorRow('일주일에', '운동', _exerciseHours, (value) {
              setState(() {
                _exerciseHours = value;
              });
            }),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _generateNovelFromSelection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A89F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'What if ?!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => const DiaryListPage(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Color(0xFFDCDCDC)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '이전 기록 보기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => const BookmarkPage(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Color(0xFFDCDCDC)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '북마크',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelectorRow(String prefix, String keyword, int? currentValue,
      ValueChanged<int?> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 18, color: Colors.black),
            children: [
              TextSpan(text: '$prefix '),
              TextSpan(
                text: keyword,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDCDCDC)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: currentValue,
                  hint: const Text('선택', style: TextStyle(color: Colors.grey)),
                  icon: const Icon(Icons.arrow_drop_down),
                  items: List.generate(24, (index) => index + 1)
                      .map((hour) => DropdownMenuItem(
                            value: hour,
                            child: Text('$hour'),
                          ))
                      .toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('시간', style: TextStyle(fontSize: 18)),
          ],
        ),
      ],
    );
  }
}
