import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/diary_provider.dart';
import '../models/diary_model.dart';
import 'novel_detail_page.dart';

class DiaryListPage extends StatefulWidget {
  const DiaryListPage({super.key});

  @override
  State<DiaryListPage> createState() => _DiaryListPageState();
}

class _DiaryListPageState extends State<DiaryListPage> {
  int _currentWeekIndex = 0;
  late List<String> _weekKeys;
  late Map<String, List<DiaryModel>> _groupedHistory;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);
    _groupedHistory = _groupByWeek(diaryProvider.novelHistory);
    _weekKeys = _groupedHistory.keys.toList();
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
            Icons.arrow_back_ios,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          '이전 기록',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<DiaryProvider>(
        builder: (context, diaryProvider, child) {
          final novelHistory = diaryProvider.novelHistory;

          if (novelHistory.isEmpty) {
            return const Center(
              child: Text(
                '아직 작성된 기록이 없습니다.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            );
          }

          // 데이터 업데이트
          _groupedHistory = _groupByWeek(novelHistory);
          _weekKeys = _groupedHistory.keys.toList();

          // 현재 인덱스가 범위를 벗어나면 조정
          if (_currentWeekIndex >= _weekKeys.length) {
            _currentWeekIndex = 0;
          }

          if (_weekKeys.isEmpty) {
            return const Center(
              child: Text(
                '기록이 없습니다.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final currentWeekKey = _weekKeys[_currentWeekIndex];
          final currentWeekData = _groupedHistory[currentWeekKey]!;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 주차 네비게이션 헤더
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5E6A3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 이전 주차 버튼
                      GestureDetector(
                        onTap: _goToPreviousWeek,
                        child: Icon(
                          Icons.chevron_left,
                          color: _currentWeekIndex < _weekKeys.length - 1
                              ? Colors.black
                              : Colors.grey,
                          size: 24,
                        ),
                      ),

                      // 현재 주차 제목 (클릭 가능)
                      GestureDetector(
                        onTap: _showWeekSelector,
                        child: Text(
                          currentWeekKey,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),

                      // 다음 주차 버튼
                      GestureDetector(
                        onTap: _goToNextWeek,
                        child: Icon(
                          Icons.chevron_right,
                          color: _currentWeekIndex > 0
                              ? Colors.black
                              : Colors.grey,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),

                // 현재 주차의 기록들
                Expanded(
                  child: ListView.builder(
                    itemCount: currentWeekData.length,
                    itemBuilder: (context, index) {
                      final diary = currentWeekData[index];
                      return _buildDiaryItem(context, diary);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _goToPreviousWeek() {
    if (_currentWeekIndex < _weekKeys.length - 1) {
      setState(() {
        _currentWeekIndex++;
      });
    }
  }

  void _goToNextWeek() {
    if (_currentWeekIndex > 0) {
      setState(() {
        _currentWeekIndex--;
      });
    }
  }

  void _showWeekSelector() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: Colors.white,
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey, width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('취소'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    '기록 선택',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    child: const Text('완료'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // 주차 목록
            Expanded(
              child: ListView.builder(
                itemCount: _weekKeys.length,
                itemBuilder: (context, index) {
                  final weekKey = _weekKeys[index];
                  final isSelected = index == _currentWeekIndex;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentWeekIndex = index;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFF5E6A3)
                            : Colors.transparent,
                      ),
                      child: Text(
                        weekKey,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiaryItem(BuildContext context, DiaryModel diary) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => NovelDetailPage(diary: diary),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDateTime(diary.date),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getPreviewText(diary.diary),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<DiaryModel>> _groupByWeek(List<DiaryModel> history) {
    final Map<String, List<DiaryModel>> grouped = {};

    for (final diary in history) {
      final weekKey = _getWeekKey(diary.date);
      if (grouped[weekKey] == null) {
        grouped[weekKey] = [];
      }
      grouped[weekKey]!.add(diary);
    }

    return grouped;
  }

  String _getWeekKey(DateTime date) {
    final month = date.month;
    final weekOfMonth = ((date.day - 1) ~/ 7) + 1;
    return '${month}월 ${weekOfMonth}주차의 기록';
  }

  String _formatDateTime(DateTime date) {
    final weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    final weekday = weekdays[date.weekday % 7];

    return '${date.month}월 ${date.day}일 (${weekday}) ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getPreviewText(String diary) {
    if (diary.length > 100) {
      return '${diary.substring(0, 97)}...';
    }
    return diary;
  }
}
