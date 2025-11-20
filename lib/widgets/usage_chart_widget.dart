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
    final isTrackingMode = appGoalProvider.isTrackingMode;

    // 총 사용량 계산 (모드별로 적절한 필드 사용)
    final totalMinutes = appGoalProvider.goals.fold<int>(
      0,
      (sum, goal) => sum + (isTrackingMode
          ? (goal.usageHours * 60).toInt() + goal.usageMinutes  // 트래킹 모드: 오늘 00:00 ~ 현재
          : (goal.yesterdayUsageHours * 60).toInt() + goal.yesterdayUsageMinutes)  // 회고 모드: 어제 하루
    );
    final totalHours = totalMinutes / 60.0;

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
          _buildHeader(totalMinutes, isTrackingMode),
          const SizedBox(height: 20),

          // 차트
          SizedBox(
            height: 180,
            child: _buildChart(totalHours, isTrackingMode),
          ),
          const SizedBox(height: 16),

          // 동기부여 멘트
          _buildMotivationMessage(totalMinutes),
        ],
      ),
    );
  }

  /// 헤더 (제목 & 총 사용 시간)
  Widget _buildHeader(int totalMinutes, bool isTrackingMode) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

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
          isTrackingMode ? '오늘 (00:00 ~ 현재)' : '어제',
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

  /// 사용량 차트 (단일 막대)
  Widget _buildChart(double totalHours, bool isTrackingMode) {
    if (totalHours == 0) {
      return const Center(
        child: Text('데이터가 없습니다', style: TextStyle(color: Colors.grey)),
      );
    }

    final maxY = (totalHours * 1.2).ceil().toDouble();
    final chartLabel = isTrackingMode ? '오늘' : '어제';

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
                toY: totalHours,
                color: isTrackingMode ? Colors.green : Colors.blue,
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
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      chartLabel,
                      style: TextStyle(
                        fontSize: 14,
                        color: isTrackingMode ? Colors.green : Colors.blue,
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
  Widget _buildMotivationMessage(int totalMinutes) {
    final hours = totalMinutes / 60.0;

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
