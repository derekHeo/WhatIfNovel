import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/diary_provider.dart';
import 'detail_page.dart';

class NovelPage extends StatelessWidget {
  const NovelPage({super.key});
  @override
  Widget build(BuildContext context) {
    final diaryProvider = Provider.of<DiaryProvider>(context);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('소설 기록'),
        border: null,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 14),
              if (diaryProvider.lastNovel != null) ...[
                const Text('AI가 변환한 500자 이내의 소설', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    diaryProvider.lastNovel?.novel ?? "",
                    style: const TextStyle(fontSize: 16, color: CupertinoColors.black),
                  ),
                ),
                const SizedBox(height: 18),
              ],
              const Text('이전 소설 기록', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Expanded(
                child: diaryProvider.novelHistory.isEmpty
                    ? const Center(child: Text('기록이 없습니다.', style: TextStyle(color: CupertinoColors.systemGrey)))
                    : ListView.separated(
                        itemCount: diaryProvider.novelHistory.length,
                        separatorBuilder: (context, idx) => const SizedBox(height: 10),
                        itemBuilder: (context, idx) {
                          final model = diaryProvider.novelHistory[idx];

                          // (필요하다면 RegExp로 제목만 추출해서 표시)
                          String novel = model.novel;
                          String title1 = '';
                          String title2 = '';
                          final regExp1 = RegExp(r'1편\s*:\s*([^\n]+)');
                          final regExp2 = RegExp(r'2편\s*:\s*([^\n]+)');
                          final match1 = regExp1.firstMatch(novel);
                          if (match1 != null && match1.groupCount >= 1) {
                            title1 = match1.group(1)!.trim();
                          }
                          final match2 = regExp2.firstMatch(novel);
                          if (match2 != null && match2.groupCount >= 1) {
                            title2 = match2.group(1)!.trim();
                          }

                          return CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (_) => DetailPage(diaryModel: model),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGrey6,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('1편: $title1', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('2편: $title2', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                    model.date.toLocal().toString().split(' ')[0],
                                    style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  child: const Text('새로운 일지 작성', style: TextStyle(fontSize: 15)),
                  onPressed: () => Navigator.pop(context),
                  color: CupertinoColors.systemGrey5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
