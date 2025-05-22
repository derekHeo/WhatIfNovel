import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/diary_provider.dart';
import '../providers/user_profile_provider.dart'; // 추가
import '../providers/screen_time_provider.dart'; // ScreenTimeProvider import 추가
import '../models/diary_model.dart'; // DiaryModel import 추가
import '../widgets/screen_time_widget.dart'; // CompactScreenTimeWidget import 추가
import 'settings_screen.dart';
import 'diary_list_page.dart';
import 'novel_detail_page.dart'; // 소설 상세페이지 import 추가
import 'bookmark_page.dart'; // 북마크 페이지 import 추가

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _generateNovel() async {
    if (_textController.text.trim().isEmpty) {
      _showAlert('내용을 입력해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);
      final profileProvider =
          Provider.of<UserProfileProvider>(context, listen: false);

      // 프로필 정보와 함께 소설 생성
      await diaryProvider.generateNovel(
        _textController.text.trim(),
        profileProvider: profileProvider,
      );

      _textController.clear();

      // 생성된 소설이 있는지 확인하고 이동
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
              Navigator.of(context).pop(); // 알림창 닫기
              // 생성된 소설 상세보기로 이동
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

  void _navigateToScreenTimeDetail() {
    // 스크린타임 상세페이지로 이동 (나중에 구현 예정)
    // 지금은 임시로 알림 표시
    _showAlert('스크린타임 상세 페이지는 준비 중입니다!');

    // 나중에 이렇게 구현:
    // Navigator.of(context).push(
    //   CupertinoPageRoute(
    //     builder: (context) => const ScreenTimeDetailPage(),
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF3), // 새로운 배경색으로 변경
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFCF3), // AppBar도 동일한 배경색
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 컴팩트한 스크린 타임 위젯
            CompactScreenTimeWidget(
              onTap: _navigateToScreenTimeDetail,
            ),

            const SizedBox(height: 30),

            // 설명 텍스트
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '해야 할 일 대신 휴대폰을 잡게 된 이유',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '또는 아직 잡지 않았지만',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '마음이 흔들리는 순간을 적어보세요:)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 텍스트 입력 영역
            Container(
              width: double.infinity,
              height: 120,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                decoration: const InputDecoration(
                  hintText:
                      'ex) 영어 단어 외우려고 했는데 웹툰 알림 떠서 눌렀다. 한 편만 보려던 게 정주행 해버려서 3시간이 지났다.',
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // What if 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _generateNovel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'What if ?!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 15),

            // 이전 기록들 보기 버튼
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
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '이전 기록들 보기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // 북마크 버튼
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
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
          ],
        ),
      ),
    );
  }
}
