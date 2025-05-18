import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/diary_provider.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});
  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final diaryProvider = Provider.of<DiaryProvider>(context);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('충동 사용 일지'),
        border: null,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Column(
            children: [
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: _controller,
                placeholder: '오늘의 스마트폰 충동 사용 경험을 적어주세요.',
                padding: const EdgeInsets.all(16),
                minLines: 6,
                maxLines: 12,
                decoration: BoxDecoration(
                  color: CupertinoColors.extraLightBackgroundGray,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  borderRadius: BorderRadius.circular(10),
                  child: const Text('소설로 변환하기', style: TextStyle(fontSize: 18)),
                  onPressed: () async {
                    final diary = _controller.text.trim();
                    if (diary.isNotEmpty) {
                      await diaryProvider.generateNovel(diary);
                      _controller.clear();
                      if (mounted) {
                        Navigator.pushNamed(context, '/novel');
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
