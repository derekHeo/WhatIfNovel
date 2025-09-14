import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'goal_setting_screen.dart';
import 'diary_list_page.dart';
import 'settings_screen.dart';

// import 'package:provider/provider.dart';
// import '../providers/diary_provider.dart';
// import '../providers/user_profile_provider.dart';
// import '../models/diary_model.dart';
// import 'settings_screen.dart';
// import 'diary_list_page.dart';
// import 'novel_detail_page.dart';
// import 'bookmark_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- 💡 더미 데이터 부분 💡 ---
  // 나중에 이 부분들을 실제 Provider나 Service에서 받아온 데이터로 교체하면 됩니다.

  // 상단 차트에 표시될 스크린 타임 총합
  final String totalScreenTime = "4시간 23분";

  // 앱별 목표 사용 시간 더미 데이터 리스트
  final List<Map<String, dynamic>> appUsageData = [
    {
      'icon': Icons.camera_alt_outlined, // 인스타그램 대체 아이콘
      'goal': 3.0, // 목표 시간 (시간 단위)
      'usage': 2.5, // 실제 사용 시간 (시간 단위)
    },
    {
      'icon': Icons.play_circle_outline, // 유튜브 대체 아이콘
      'goal': 1.0,
      'usage': 1.2, // 목표 초과
    },
    {
      'icon': Icons.chat_bubble_outline, // 채팅 앱 대체 아이콘
      'goal': 1.0,
      'usage': 0.4,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Figma 디자인의 배경색과 유사한 색상으로 설정
      backgroundColor: const Color(0xFFFDFBFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent, // 배경과 동일하게 투명 처리
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.menu,
            color: Colors.black,
            size: 28,
          ),
          onPressed: () {
            // TODO: 사이드 메뉴 또는 설정 페이지로 이동하는 로직 구현
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // 상단 스크린 타임 차트 카드
              _buildScreenTimeChartCard(),
              const SizedBox(height: 40),
              // 앱별 목표 시간 목록
              ...appUsageData.map((data) => _buildAppGoalItem(
                    icon: data['icon'],
                    goalHours: data['goal'],
                    usageHours: data['usage'],
                  )),
              const SizedBox(height: 32),
              // 기능 버튼 영역
              _buildActionButtons(),
              const SizedBox(height: 40),
              // What If 시나리오 섹션
              _buildWhatIfSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // 상단 스크린 타임 차트 위젯
  Widget _buildScreenTimeChartCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            totalScreenTime,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          // TODO: 실제 차트 라이브러리(예: fl_chart)로 교체할 것을 권장합니다.
          // 여기서는 디자인 시안을 흉내 낸 더미 차트입니다.
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildChartBar(0.8, Colors.teal),
                _buildChartBar(0.6, Colors.teal),
                const SizedBox(width: 10),
                _buildChartBar(0.9, Colors.orange),
                _buildChartBar(0.7, Colors.blue),
                const SizedBox(width: 10),
                _buildChartBar(0.5, Colors.indigo),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildChartLabel('생산성 및 금융', '1시간 25분'),
              _buildChartLabel('소셜 미디어', '51분'),
              _buildChartLabel('엔터테인먼트', '48분'),
            ],
          )
        ],
      ),
    );
  }

  // 더미 차트의 막대 하나를 그리는 위젯
  Widget _buildChartBar(double heightFactor, Color color) {
    return Container(
      width: 12,
      height: 100 * heightFactor,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // 차트 하단의 카테고리 라벨 위젯
  Widget _buildChartLabel(String title, String time) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(time,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // 앱별 목표 사용량 아이템 위젯
  Widget _buildAppGoalItem(
      {required IconData icon,
      required double goalHours,
      required double usageHours}) {
    final double progress = (usageHours / goalHours).clamp(0.0, 1.0);
    final bool isOver = usageHours > goalHours;
    final Color progressColor = isOver ? Colors.red : Colors.green.shade400;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        children: [
          Icon(icon, size: 36, color: Colors.grey.shade700),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '목표 시간 : ${goalHours.toInt()} 시간',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 중간에 위치한 기능 버튼들 위젯
  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const GoalSettingScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A89F3),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('목표 설정',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () {
              // TODO: 이전 달성률 보기 페이지로 이동하는 로직 구현
              print('이전 달성률 보기 버튼 클릭');
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('이전 달성률 보기',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800)),
          ),
        ),
      ],
    );
  }

  // What If 시나리오 섹션 위젯
  Widget _buildWhatIfSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '• What If 시나리오',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                // CupertinoPageRoute는 iOS 스타일의 화면 전환 효과를 줍니다.
                CupertinoPageRoute(builder: (context) => const DiaryListPage()),
              );
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('이전 기록 보기',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800)),
          ),
        ),
      ],
    );
  }
}
