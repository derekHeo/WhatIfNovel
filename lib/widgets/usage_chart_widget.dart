import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/usage_stats_provider.dart';
import '../providers/app_goal_provider.dart';

/// 사용량 차트 위젯 (일별 - AppGoalProvider 데이터 사용)
class UsageChartWidget extends StatefulWidget {
  final UsageStatsProvider usageStatsProvider;
  final AppGoalProvider appGoalProvider;

  const UsageChartWidget({
    super.key,
    required this.usageStatsProvider,
    required this.appGoalProvider,
  });

  @override
  State<UsageChartWidget> createState() => _UsageChartWidgetState();
}

class _UsageChartWidgetState extends State<UsageChartWidget> {
  @override
  Widget build(BuildContext context) {
    final appGoalProvider = widget.appGoalProvider;

    // 어제 총 사용량 계산 (등록한 앱들의 합)
    final yesterdayTotalMinutes = appGoalProvider.goals.fold<int>(
      0,
      (sum, goal) => sum + (goal.yesterdayUsageHours * 60).toInt() + goal.yesterdayUsageMinutes
    );
    final yesterdayHours = yesterdayTotalMinutes / 60.0;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 & 총 사용 시간
          _buildHeader(yesterdayTotalMinutes),
          const SizedBox(height: 20),

          // 차트 (어제 데이터만)
          SizedBox(
            height: 180,
            child: _buildYesterdayChart(yesterdayHours),
          ),
          const SizedBox(height: 16),

          // 동기부여 멘트
          _buildMotivationMessage(yesterdayTotalMinutes),
        ],
      ),
    );
  }

  /// 헤더 (제목 & 총 사용 시간)
  Widget _buildHeader(int yesterdayTotalMinutes) {
    final hours = yesterdayTotalMinutes ~/ 60;
    final minutes = yesterdayTotalMinutes % 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '스마트폰 사용 시간',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '어제',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${hours}시간 ${minutes}분',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  /// 어제 사용량 차트 (단일 막대)
  Widget _buildYesterdayChart(double yesterdayHours) {
    if (yesterdayHours == 0) {
      return const Center(
        child: Text('데이터가 없습니다', style: TextStyle(color: Colors.grey)),
      );
    }

    final maxY = (yesterdayHours * 1.2).ceil().toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.center,
        maxY: maxY > 0 ? maxY : 5,
        minY: 0,
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: yesterdayHours,
                color: Colors.blue,
                width: 60,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ],
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}h',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      '어제',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? maxY / 5 : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  /// 동기부여 멘트
  Widget _buildMotivationMessage(int yesterdayTotalMinutes) {
    final hours = yesterdayTotalMinutes / 60.0;

    String message;
    IconData icon;

    if (hours < 3) {
      message = '스마트폰 사용 시간이 매우 적었습니다! 👏';
      icon = Icons.emoji_events;
    } else if (hours < 6) {
      message = '적절한 사용 시간을 유지하고 계십니다 ✨';
      icon = Icons.thumb_up;
    } else {
      message = '스마트폰 사용 시간을 줄여보는 건 어떨까요? 💪';
      icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.blue,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
