import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/diary_provider.dart';
import '../providers/user_profile_provider.dart';
import '../providers/screen_time_provider.dart';
import '../models/diary_model.dart';
import '../widgets/screen_time_widget.dart';
import 'settings_screen.dart';
import 'diary_list_page.dart';
import 'novel_detail_page.dart';
import 'bookmark_page.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;

  // ==================== 더미 데이터 섹션 ====================
  // 아래 값들을 수정하여 UI에서 다양한 데이터를 테스트할 수 있습니다.

  // 스크린타임 더미 데이터 (차트용)
  final String _totalScreenTime = '4시간 23분';

  // 스크린타임 앱별 사용 시간 (차트 데이터)
  final List<AppUsage> _screenTimeData = [
    AppUsage('오전 12시', 45, const Color(0xFF007AFF)),
    AppUsage('오전 6시', 20, const Color(0xFF007AFF)),
    AppUsage('오후 12시', 80, const Color(0xFF007AFF)),
    AppUsage('오후 6시', 25, const Color(0xFF007AFF)),
  ];

  // 앱별 세부 사용 시간
  final List<AppDetailUsage> _appDetails = [
    AppDetailUsage('인스타그램', '1시간 25분', Color.fromARGB(255, 253, 124, 234)),
    AppDetailUsage('유튜브', '51분', Color.fromARGB(255, 255, 0, 0)),
    AppDetailUsage('인터넷', '48분', Color.fromARGB(255, 0, 38, 255)),
  ];

  // 걸음 수 더미 데이터
  final String _steps = '1,536보';
  final String _distance = '0.9km';
  final String _floors = '1층';

  // 수면 시간 더미 데이터
  final String _sleepHours = '4h 30m';
  final String _sleepDays = '수면부족';

  // ==================== 더미 데이터 섹션 끝 ====================

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

      await diaryProvider.generateNovel(
        _textController.text.trim(),
        profileProvider: profileProvider,
      );

      _textController.clear();

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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 스크린타임 카드
            _buildScreenTimeCard(),

            const SizedBox(height: 12),

            // 걸음 수와 수면 카드
            Row(
              children: [
                // 수면 카드
                Expanded(
                  child: _buildSleepCard(),
                ),
                const SizedBox(width: 12),
                // 걸음 수 카드
                Expanded(
                  child: _buildStepsCard(),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 설명 텍스트
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '해야 할 일 대신 휴대폰을 잡게 된 이유',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '또는 아직 잡지 않았지만',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                Text(
                  '마음이 흔들리는 순간을 적어보세요:)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 텍스트 입력 영역
            Container(
              width: double.infinity,
              height: 100,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(8),
                color: Color.fromARGB(255, 255, 255, 255),
              ),
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
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

            const SizedBox(height: 16),

            // What if 버튼
            SizedBox(
              width: double.infinity,
              height: 44,
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

            const SizedBox(height: 12),

            // 하단 버튼들
            // 하단 버튼들
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    // OutlinedButton -> ElevatedButton으로 변경
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => const DiaryListPage(),
                          ),
                        );
                      },
                      // 버튼 스타일 수정
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // 배경색: 흰색
                        foregroundColor: Colors.black, // 글자 및 아이콘 색상: 검은색
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        // 테두리가 필요하다면 이 코드를 추가하세요.
                        side: const BorderSide(color: Colors.black, width: 1),
                        // 그림자 효과 제거
                        elevation: 0,
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
                ),
                const SizedBox(width: 10),
                Expanded(
                  // OutlinedButton -> ElevatedButton으로 변경
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => const BookmarkPage(),
                        ),
                      );
                    },
                    // 버튼 스타일 수정
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, // 배경색: 흰색
                      foregroundColor: Colors.black, // 글자 및 아이콘 색상: 검은색
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      // 테두리가 필요하다면 이 코드를 추가하세요.
                      side: const BorderSide(color: Colors.black, width: 1),
                      // 그림자 효과 제거
                      elevation: 0,
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
          ],
        ),
      ),
    );
  }

  Widget _buildScreenTimeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _totalScreenTime,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              Text(
                '60분',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 차트 영역
          Container(
            height: 40,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 차트 바들
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _screenTimeData.asMap().entries.map((entry) {
                      final data = entry.value;
                      return _buildChartBar(
                          data.usage, data.color, data.maxUsage);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // 시간 라벨들
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _screenTimeData
                .map((data) => Text(
                      data.time,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade600,
                      ),
                    ))
                .toList(),
          ),

          const SizedBox(height: 12),

          // 앱별 사용 시간
          ..._appDetails.map((app) => _buildAppUsageRow(app)).toList(),
        ],
      ),
    );
  }

  Widget _buildChartBar(double usage, Color color, double maxUsage) {
    final height = (usage / maxUsage) * 30; // 최대 높이 45로 축소
    return Container(
      width: 10,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildAppUsageRow(AppDetailUsage app) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: app.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              app.name,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black,
              ),
            ),
          ),
          Text(
            app.usage,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepCard() {
    final sleepHours = [6.5, 7.0, 5.5, 8.0, 6.0, 7.5, 6.2]; // 일~토 수면 시간

    return Container(
      height: 120,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F4FF), // 부드러운 파란 배경
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '수면시간 : 6시간31분',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A73E8), // Google Blue 느낌
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BarChart(
              BarChartData(
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['일', '월', '화', '수', '목', '금', '토'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            days[value.toInt()],
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                      reservedSize: 22,
                      interval: 1,
                    ),
                  ),
                ),
                barGroups: List.generate(7, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: sleepHours[index],
                        width: 8,
                        color: const Color(0xFF4FC3F7), // 밝은 파랑
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsCard() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5E5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 걷는 사람 아이콘
          const Icon(
            Icons.directions_walk,
            color: Color(0xFFFF6B6B),
            size: 24,
          ),
          const Spacer(),
          Text(
            _steps,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFF6B6B),
            ),
          ),
          Text(
            '$_distance  $_floors',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// 더미 데이터 클래스들
class AppUsage {
  final String time;
  final double usage;
  final Color color;
  final double maxUsage = 80; // 차트의 최대값

  AppUsage(this.time, this.usage, this.color);
}

class AppDetailUsage {
  final String name;
  final String usage;
  final Color color;

  AppDetailUsage(this.name, this.usage, this.color);
}

// 침대 아이콘을 그리는 CustomPainter
class BedIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade600
      ..style = PaintingStyle.fill;

    // 침대 프레임
    final bedRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, size.height * 0.4, size.width - 4, size.height * 0.5),
      const Radius.circular(2),
    );
    canvas.drawRRect(bedRect, paint);

    // 베개
    final pillowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.1, size.width * 0.3,
          size.height * 0.4),
      const Radius.circular(1),
    );
    canvas.drawRRect(pillowRect, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
