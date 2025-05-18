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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('날짜: ${diaryModel.date.toLocal().toString().split(' ')[0]}', style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 10),
              const Text('작성한 일지', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(diaryModel.diary),
              const SizedBox(height: 18),
              const Text('변환된 소설', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(diaryModel.novel),
            ],
          ),
        ),
      ),
    );
  }
}
