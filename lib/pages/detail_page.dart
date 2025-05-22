import 'package:flutter/cupertino.dart';
import '../models/diary_model.dart';

class DetailPage extends StatelessWidget {
  final DiaryModel diaryModel;

  const DetailPage({super.key, required this.diaryModel});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('소설 상세보기'),
        previousPageTitle: '이전',
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 날짜
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(CupertinoIcons.calendar,
                        size: 19, color: CupertinoColors.systemGrey),
                    const SizedBox(width: 6),
                    Text(
                      diaryModel.date.toLocal().toString().split(' ')[0],
                      style: const TextStyle(
                          fontSize: 15,
                          color: CupertinoColors.systemGrey,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                // 일지 카드
                CardContainer(
                  title: '작성한 일지',
                  child: Text(
                    diaryModel.diary,
                    style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: CupertinoColors.black),
                  ),
                ),
                const SizedBox(height: 18),
                // 변환된 소설 카드
                CardContainer(
                  title: '변환된 소설',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionTitle(title: '1편'),
                      const SizedBox(height: 4),
                      Text(
                        extractPart(diaryModel.novel, 1),
                        style: const TextStyle(
                            fontSize: 16,
                            height: 1.7,
                            color: CupertinoColors.black),
                      ),
                      //
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 18),
                        width: double.infinity,
                        height: 1,
                        color: CupertinoColors.systemGrey4,
                      ),

                      SectionTitle(title: '2편'),
                      const SizedBox(height: 4),
                      Text(
                        extractPart(diaryModel.novel, 2),
                        style: const TextStyle(
                            fontSize: 16,
                            height: 1.7,
                            color: CupertinoColors.black),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 카드 컨테이너
class CardContainer extends StatelessWidget {
  final String title;
  final Widget child;

  const CardContainer({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey3.withOpacity(0.2),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: CupertinoColors.black,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// 1, 2편 소제목 강조
class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 15,
        color: CupertinoColors.activeBlue,
        letterSpacing: 0.5,
      ),
    );
  }
}

// novel에서 각 파트 추출 함수
String extractPart(String novel, int part) {
  // 1편, 2편 형태가 모두 없으면 전체 반환
  if (!novel.contains('1편') && !novel.contains('2편')) return novel;

  // 정규식: "1편", "2편" 제목 구분
  final pattern = RegExp(
      r'[#\*]*\s*([0-9]+)편[\s:：-]*([^\n]+)?\n*([\s\S]*?)(?=(?:[#\*]*\s*[0-9]+편|$))',
      multiLine: true);

  final matches = pattern.allMatches(novel);

  for (final match in matches) {
    final idx = int.tryParse(match.group(1) ?? '');
    final content = (match.group(3) ?? '').trim();
    if (idx == part) {
      return content.isNotEmpty ? content : '(내용 없음)';
    }
  }
  return '(내용 없음)';
}
