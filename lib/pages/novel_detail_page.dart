import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/diary_model.dart';
import '../providers/diary_provider.dart';

class NovelDetailPage extends StatefulWidget {
  final DiaryModel diary;

  const NovelDetailPage({super.key, required this.diary});

  @override
  State<NovelDetailPage> createState() => _NovelDetailPageState();
}

class _NovelDetailPageState extends State<NovelDetailPage> {
  final ScrollController _scrollController = ScrollController();
  List<DiaryModel> _currentWeekNovels = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentWeekNovels();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadCurrentWeekNovels() {
    final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);
    final allNovels = diaryProvider.novelHistory;

    // 현재 소설과 같은 주차의 소설들 찾기
    final currentWeekKey = _getWeekKey(widget.diary.date);
    _currentWeekNovels = allNovels.where((novel) {
      return _getWeekKey(novel.date) == currentWeekKey;
    }).toList();

    // 현재 소설의 인덱스 찾기
    _currentIndex = _currentWeekNovels.indexWhere((novel) =>
        novel.date == widget.diary.date && novel.diary == widget.diary.diary);

    if (_currentIndex == -1) _currentIndex = 0;
  }

  String _getWeekKey(DateTime date) {
    final month = date.month;
    final weekOfMonth = ((date.day - 1) ~/ 7) + 1;
    return '${month}월 ${weekOfMonth}주차';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DiaryProvider>(
      builder: (context, diaryProvider, child) {
        final isBookmarked = diaryProvider.isBookmarked(widget.diary);

        return Scaffold(
          backgroundColor: const Color(0xFFF5E6A3), // 노란색 배경
          appBar: AppBar(
            backgroundColor: const Color(0xFFF5E6A3),
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
            title: Text(
              _formatDateTime(widget.diary.date),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            actions: [
              // 북마크 표시 (상단)
              if (isBookmarked)
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: const Icon(
                    Icons.bookmark,
                    color: Color(0xFF007AFF),
                    size: 24,
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              // 스크롤 가능한 소설 내용 (흰색 배경)
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: Colors.white, // 텍스트 영역은 흰색 배경
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 내가 쓴 글 섹션
                        const Text(
                          '<내가 쓴 글>',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 원본 일지 내용
                        Text(
                          widget.diary.diary,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // 1편 제목
                        Text(
                          _extractFirstNovelTitle(widget.diary.novel),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 1편 내용
                        Text(
                          _extractFirstNovelContent(widget.diary.novel),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // 2편이 있다면 표시
                        if (_hasSecondNovel(widget.diary.novel)) ...[
                          Text(
                            _extractSecondNovelTitle(widget.diary.novel),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _extractSecondNovelContent(widget.diary.novel),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              height: 1.6,
                            ),
                          ),
                        ],

                        const SizedBox(height: 50), // 하단 버튼을 위한 여백
                      ],
                    ),
                  ),
                ),
              ),

              // 하단 네비게이션 바
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5E6A3), // 동일한 노란색 배경
                  border: Border(
                    top: BorderSide(color: Colors.black12, width: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 북마크 버튼
                    GestureDetector(
                      onTap: () => _toggleBookmark(context, diaryProvider),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: isBookmarked
                                  ? const Color(0xFF007AFF)
                                  : Colors.black54,
                              size: 24,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${diaryProvider.bookmarkedNovels.length}',
                              style: TextStyle(
                                color: isBookmarked
                                    ? const Color(0xFF007AFF)
                                    : Colors.black54,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 네비게이션 버튼들
                    Row(
                      children: [
                        // 이전 기록으로 이동
                        IconButton(
                          onPressed:
                              _currentIndex < _currentWeekNovels.length - 1
                                  ? _goToPrevious
                                  : null,
                          icon: Icon(
                            Icons.chevron_left,
                            color: _currentIndex < _currentWeekNovels.length - 1
                                ? Colors.black54
                                : Colors.grey.shade300,
                            size: 28,
                          ),
                        ),
                        // 목록으로 이동
                        IconButton(
                          onPressed: _showWeekList,
                          icon: const Icon(
                            Icons.menu,
                            color: Colors.black54,
                            size: 24,
                          ),
                        ),
                        // 다음 기록으로 이동
                        IconButton(
                          onPressed: _currentIndex > 0 ? _goToNext : null,
                          icon: Icon(
                            Icons.chevron_right,
                            color: _currentIndex > 0
                                ? Colors.black54
                                : Colors.grey.shade300,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 북마크 토글 기능
  void _toggleBookmark(
      BuildContext context, DiaryProvider diaryProvider) async {
    await diaryProvider.toggleBookmarkForDiary(widget.diary);

    final isNowBookmarked = diaryProvider.isBookmarked(widget.diary);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isNowBookmarked ? '북마크에 추가되었습니다' : '북마크에서 제거되었습니다'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  // 이전 소설로 이동
  void _goToPrevious() {
    if (_currentIndex < _currentWeekNovels.length - 1) {
      final previousNovel = _currentWeekNovels[_currentIndex + 1];
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(
          builder: (context) => NovelDetailPage(diary: previousNovel),
        ),
      );
    }
  }

  // 다음 소설로 이동
  void _goToNext() {
    if (_currentIndex > 0) {
      final nextNovel = _currentWeekNovels[_currentIndex - 1];
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(
          builder: (context) => NovelDetailPage(diary: nextNovel),
        ),
      );
    }
  }

  // 주차별 소설 목록 팝업
  void _showWeekList() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey, width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 60),
                  Text(
                    '${_getWeekKey(widget.diary.date)}의 기록',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('닫기'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // 소설 목록
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _currentWeekNovels.length,
                itemBuilder: (context, index) {
                  final novel = _currentWeekNovels[index];
                  final isCurrentNovel = index == _currentIndex;

                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // 팝업 닫기
                      if (!isCurrentNovel) {
                        // 다른 소설로 이동
                        Navigator.of(context).pushReplacement(
                          CupertinoPageRoute(
                            builder: (context) => NovelDetailPage(diary: novel),
                          ),
                        );
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isCurrentNovel
                            ? const Color(0xFFF5E6A3).withOpacity(0.3)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCurrentNovel
                              ? const Color(0xFFF5E6A3)
                              : Colors.grey.shade200,
                          width: isCurrentNovel ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isCurrentNovel)
                                const Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Icon(
                                    Icons.play_arrow,
                                    color: Color(0xFF007AFF),
                                    size: 20,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  _formatDateTime(novel.date),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isCurrentNovel
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isCurrentNovel
                                        ? const Color(0xFF007AFF)
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getPreviewText(novel.diary),
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 날짜 포맷팅
  String _formatDateTime(DateTime date) {
    final weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    final weekday = weekdays[date.weekday % 7];

    return '${date.month}월 ${date.day}일 (${weekday}) ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // 미리보기 텍스트
  String _getPreviewText(String diary) {
    if (diary.length > 50) {
      return '${diary.substring(0, 47)}...';
    }
    return diary;
  }

  // 첫 번째 소설의 제목 추출
  String _extractFirstNovelTitle(String novel) {
    final lines = novel.split('\n');
    for (final line in lines) {
      if (line.contains('1편') || line.toLowerCase().contains('first')) {
        // ** 제거하고 <> 괄호로 변경
        String cleanTitle = line
            .trim()
            .replaceAll('**', '')
            .replaceAll('「', '<')
            .replaceAll('」', '>');
        return cleanTitle;
      }
    }
    return '<1편: 길 잃은 시간>'; // 기본값
  }

  // 첫 번째 소설의 내용 추출
  String _extractFirstNovelContent(String novel) {
    final lines = novel.split('\n');
    bool foundFirst = false;
    bool foundContent = false;
    final List<String> content = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // 1편 시작 지점 찾기
      if (line.contains('1편') || line.toLowerCase().contains('first')) {
        foundFirst = true;
        continue;
      }

      // 2편 시작되면 1편 내용 수집 종료
      if (foundFirst &&
          (line.contains('2편') || line.toLowerCase().contains('second'))) {
        break;
      }

      // 1편 내용 수집 (** 제거)
      if (foundFirst && line.trim().isNotEmpty) {
        String cleanLine = line.trim().replaceAll('**', '');
        if (cleanLine.isNotEmpty) {
          content.add(cleanLine);
          foundContent = true;
        }
      }
    }

    // 실제 데이터가 있으면 반환, 없으면 전체 텍스트의 앞부분 반환
    if (foundContent && content.isNotEmpty) {
      return content.join('\n');
    } else {
      // 구조화된 데이터가 없으면 전체 텍스트를 반으로 나누어 첫 번째 부분 반환
      final allLines = novel
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((line) => line.replaceAll('**', ''))
          .toList();
      final halfPoint = allLines.length ~/ 2;
      return allLines.take(halfPoint).join('\n');
    }
  }

  // 두 번째 소설이 있는지 확인
  bool _hasSecondNovel(String novel) {
    return novel.contains('2편') ||
        novel.toLowerCase().contains('second') ||
        novel.split('\n').length > 10;
  }

  // 두 번째 소설의 제목 추출
  String _extractSecondNovelTitle(String novel) {
    final lines = novel.split('\n');
    for (final line in lines) {
      if (line.contains('2편') || line.toLowerCase().contains('second')) {
        // ** 제거하고 <> 괄호로 변경
        String cleanTitle = line
            .trim()
            .replaceAll('**', '')
            .replaceAll('「', '<')
            .replaceAll('」', '>');
        return cleanTitle;
      }
    }
    return '<2편: 다른 길>'; // 기본값
  }

  // 두 번째 소설의 내용 추출
  String _extractSecondNovelContent(String novel) {
    final lines = novel.split('\n');
    bool foundSecond = false;
    bool foundContent = false;
    final List<String> content = [];

    for (final line in lines) {
      // 2편 시작 지점 찾기
      if (line.contains('2편') || line.toLowerCase().contains('second')) {
        foundSecond = true;
        continue;
      }

      // 2편 내용 수집 (** 제거)
      if (foundSecond && line.trim().isNotEmpty) {
        String cleanLine = line.trim().replaceAll('**', '');
        if (cleanLine.isNotEmpty) {
          content.add(cleanLine);
          foundContent = true;
        }
      }
    }

    // 실제 데이터가 있으면 반환, 없으면 전체 텍스트의 뒷부분 반환
    if (foundContent && content.isNotEmpty) {
      return content.join('\n');
    } else {
      // 구조화된 데이터가 없으면 전체 텍스트를 반으로 나누어 두 번째 부분 반환
      final allLines = novel
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((line) => line.replaceAll('**', ''))
          .toList();
      final halfPoint = allLines.length ~/ 2;
      return allLines.skip(halfPoint).join('\n');
    }
  }
}
