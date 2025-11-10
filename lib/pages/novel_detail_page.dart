import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/diary_model.dart';
import '../models/comment_model.dart';
import '../providers/diary_provider.dart';
import '../providers/comment_provider.dart';
import 'goal_setting_screen.dart';

class NovelDetailPage extends StatefulWidget {
  final DiaryModel diary;

  const NovelDetailPage({super.key, required this.diary});

  @override
  State<NovelDetailPage> createState() => _NovelDetailPageState();
}

class _NovelDetailPageState extends State<NovelDetailPage> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _commentScrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  List<DiaryModel> _currentWeekNovels = [];
  int _currentIndex = 0;

  bool _isCommentSectionVisible = false;
  List<CommentModel> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentWeekNovels();
    print(widget.diary.content);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentScrollController.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _loadCurrentWeekNovels() {
    final diaryProvider = Provider.of<DiaryProvider>(context, listen: false);
    final allNovels = diaryProvider.diaries;

    final currentWeekKey = _getWeekKey(widget.diary.createdAt);
    _currentWeekNovels = allNovels.where((novel) {
      return _getWeekKey(novel.createdAt) == currentWeekKey;
    }).toList();

    _currentIndex = _currentWeekNovels.indexWhere((novel) =>
        novel.createdAt == widget.diary.createdAt &&
        novel.userInput == widget.diary.userInput);

    if (_currentIndex == -1) _currentIndex = 0;
  }

  String _getWeekKey(DateTime date) {
    final month = date.month;
    final weekOfMonth = ((date.day - 1) ~/ 7) + 1;
    return '${month}월 ${weekOfMonth}주차';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DiaryProvider, CommentProvider>(
      builder: (context, diaryProvider, commentProvider, child) {
        _comments = commentProvider.getCommentsForDiary(widget.diary);

        return Scaffold(
          backgroundColor: const Color(0xFFF5E6A3),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF5E6A3),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios,
                  color: Colors.black, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              _formatDateTime(widget.diary.createdAt),
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: Colors.white,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Text(
                          widget.diary.userInput,
                          style: const TextStyle(
                              fontSize: 16, color: Colors.black, height: 1.6),
                        ),
                        const SizedBox(height: 30),
                        // 앱 사용량 정보 표시
                        if (widget.diary.appGoals != null &&
                            widget.diary.appUsage != null)
                          _buildAppUsageCard(),
                        if (widget.diary.appGoals != null &&
                            widget.diary.appUsage != null)
                          const SizedBox(height: 30),
                        const Divider(thickness: 1, color: Colors.black12),
                        const SizedBox(height: 30),
                        Text(
                          widget.diary.content,
                          style: const TextStyle(
                              fontSize: 16, color: Colors.black, height: 1.6),
                        ),
                        const SizedBox(height: 50),
                        _buildNextButton(context),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ),
              if (_isCommentSectionVisible) _buildCommentSection(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF5E6A3),
                  border: Border(
                      top: BorderSide(color: Colors.black12, width: 0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _toggleCommentSection,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Stack(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  color: _isCommentSectionVisible
                                      ? const Color(0xFF007AFF)
                                      : Colors.black54,
                                  size: 24,
                                ),
                                if (_comments.isNotEmpty)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle),
                                      constraints: const BoxConstraints(
                                          minWidth: 16, minHeight: 16),
                                      child: Text(
                                        '${_comments.length}',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _currentIndex > 0 ? _goToPrevious : null,
                          icon: Icon(
                            Icons.chevron_left,
                            color: _currentIndex > 0
                                ? Colors.black54
                                : Colors.grey.shade300,
                            size: 28,
                          ),
                        ),
                        IconButton(
                          onPressed: _showWeekList,
                          icon: const Icon(Icons.menu,
                              color: Colors.black54, size: 24),
                        ),
                        IconButton(
                          onPressed:
                              _currentIndex < _currentWeekNovels.length - 1
                                  ? _goToNext
                                  : null,
                          icon: Icon(
                            Icons.chevron_right,
                            color: _currentIndex < _currentWeekNovels.length - 1
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

  // 앱 사용량 카드 위젯
  Widget _buildAppUsageCard() {
    final appGoals = widget.diary.appGoals!;
    final appUsage = widget.diary.appUsage!;

    // 앱 이미지 매핑
    final appImages = {
      'Instagram': 'assets/images/insta.png',
      'YouTube': 'assets/images/youtube.png',
      'KakaoTalk': 'assets/images/kakao.png',
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📱 당시 스마트폰 사용 현황',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...appGoals.keys.map((appName) {
            final goalMinutes = appGoals[appName] as int?;
            final usageMinutes = appUsage[appName] as int?;

            if (goalMinutes == null || usageMinutes == null)
              return const SizedBox.shrink();

            // 분을 시간과 분으로 변환
            final goalHours = goalMinutes ~/ 60;
            final goalMins = goalMinutes % 60;
            final usageH = usageMinutes ~/ 60;
            final usageM = usageMinutes % 60;

            // 목표 초과 여부를 먼저 계산
            final rawProgress = goalMinutes > 0
                ? (usageMinutes / goalMinutes)
                : 0.0;
            final isExceeded = rawProgress >= 1.0;
            final progress = rawProgress.clamp(0.0, 1.0);
            final barColor = isExceeded ? Colors.red : Colors.blue;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  // 앱 아이콘
                  if (appImages.containsKey(appName))
                    Image.asset(appImages[appName]!, width: 28, height: 28),
                  if (!appImages.containsKey(appName))
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.smartphone, size: 16),
                    ),
                  const SizedBox(width: 16),
                  // 프로그레스 바
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(barColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 사용량 표시
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${usageH}h ${usageM}m',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: barColor,
                        ),
                      ),
                      Text(
                        '/ ${goalHours}h ${goalMins}m',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildNextButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            CupertinoPageRoute(builder: (context) => const GoalSettingScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          'NEXT',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    return Container(
      height: 300,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: const Border(
                bottom: BorderSide(color: Colors.grey, width: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline,
                    size: 18, color: Colors.black54),
                const SizedBox(width: 8),
                Text(
                  '댓글 ${_comments.length}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _toggleCommentSection,
                  child:
                      const Icon(Icons.close, size: 20, color: Colors.black54),
                ),
              ],
            ),
          ),
          Expanded(
            child: _comments.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          '아직 댓글이 없습니다',
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                              fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '첫 번째 댓글을 남겨보세요!',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _commentScrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      return _buildCommentItem(comment);
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey, width: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _commentFocusNode,
                    maxLines: null,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '댓글을 입력해주세요...',
                      hintStyle:
                          const TextStyle(color: Colors.grey, fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Color(0xFF007AFF)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _addComment,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                        color: Color(0xFF007AFF), shape: BoxShape.circle),
                    child:
                        const Icon(Icons.send, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(CommentModel comment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comment.content,
            style: const TextStyle(
                fontSize: 14, color: Colors.black87, height: 1.4),
          ),
          const SizedBox(height: 6),
          Text(
            _formatCommentTime(comment.createdAt),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _toggleCommentSection() {
    final commentProvider =
        Provider.of<CommentProvider>(context, listen: false);
    final currentComments = commentProvider.getCommentsForDiary(widget.diary);

    setState(() {
      _isCommentSectionVisible = !_isCommentSectionVisible;
      if (_isCommentSectionVisible) {
        _commentFocusNode.unfocus();
        if (currentComments.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_commentScrollController.hasClients) {
              _commentScrollController.animateTo(
                _commentScrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
    });
  }

  void _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final commentProvider =
        Provider.of<CommentProvider>(context, listen: false);

    final success = await commentProvider.addComment(
      content: content,
      diary: widget.diary,
    );

    if (success) {
      _commentController.clear();
      _commentFocusNode.unfocus();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_commentScrollController.hasClients) {
          _commentScrollController.animateTo(
            _commentScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('댓글이 추가되었습니다'), duration: Duration(seconds: 1)),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('댓글 추가에 실패했습니다'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatCommentTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) return '${difference.inDays}일 전';
    if (difference.inHours > 0) return '${difference.inHours}시간 전';
    if (difference.inMinutes > 0) return '${difference.inMinutes}분 전';
    return '방금 전';
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      final previousNovel = _currentWeekNovels[_currentIndex - 1];
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(
            builder: (context) => NovelDetailPage(diary: previousNovel)),
      );
    }
  }

  void _goToNext() {
    if (_currentIndex < _currentWeekNovels.length - 1) {
      final nextNovel = _currentWeekNovels[_currentIndex + 1];
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(
            builder: (context) => NovelDetailPage(diary: nextNovel)),
      );
    }
  }

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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 60),
                  Text(
                    '${_getWeekKey(widget.diary.createdAt)}의 기록',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text('닫기'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _currentWeekNovels.length,
                itemBuilder: (context, index) {
                  final novel = _currentWeekNovels[index];
                  final isCurrentNovel = index == _currentIndex;

                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      if (!isCurrentNovel) {
                        Navigator.of(context).pushReplacement(
                          CupertinoPageRoute(
                              builder: (context) =>
                                  NovelDetailPage(diary: novel)),
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
                                  child: Icon(Icons.play_arrow,
                                      color: Color(0xFF007AFF), size: 20),
                                ),
                              Expanded(
                                child: Text(
                                  _formatDateTime(novel.createdAt),
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
                            _getPreviewText(novel.userInput),
                            style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                                height: 1.4),
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

  String _formatDateTime(DateTime date) {
    final weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    final weekday = weekdays[date.weekday % 7];
    return '${date.month}월 ${date.day}일 (${weekday}) ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getPreviewText(String diary) {
    if (diary.length > 50) {
      return '${diary.substring(0, 47)}...';
    }
    return diary;
  }
}
