import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/weekly_activity_stats.dart';

/// 脂肪燃焼チャートウィジェット
///
/// 週間または期間別の脂肪燃焼量を美しい棒グラフで表示します。
class FatBurnChart extends StatefulWidget {
  final WeeklyActivityStats weeklyStats;
  final int period; // 0: 今日, 1: 今週, 2: 今月

  const FatBurnChart({
    super.key,
    required this.weeklyStats,
    required this.period,
  });

  @override
  State<FatBurnChart> createState() => _FatBurnChartState();
}

class _FatBurnChartState extends State<FatBurnChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildChart(),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  /// ヘッダー部分
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fat Burning Progress',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getPeriodText(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${widget.weeklyStats.totalFatGramsBurned.toStringAsFixed(1)}g',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// チャート部分
  Widget _buildChart() {
    return SizedBox(
      height: 200,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _getMaxY(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _getMaxY() / 5,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: _buildTitlesData(),
              borderData: FlBorderData(show: false),
              barGroups: _buildBarGroups(),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Theme.of(context).colorScheme.surface,
                  tooltipBorder: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final dayName = _getDayNames()[groupIndex];
                    return BarTooltipItem(
                      '$dayName\n${rod.toY.toStringAsFixed(1)}g fat burned',
                      TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// タイトルデータを構築
  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (double value, TitleMeta meta) {
            final dayNames = _getDayNames();
            if (value.toInt() >= 0 && value.toInt() < dayNames.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  dayNames[value.toInt()],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              );
            }
            return const Text('');
          },
          reservedSize: 30,
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          interval: _getMaxY() / 5,
          getTitlesWidget: (double value, TitleMeta meta) {
            return Text(
              '${value.toInt()}g',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            );
          },
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  /// 棒グラフグループを構築
  List<BarChartGroupData> _buildBarGroups() {
    final dailyStats = widget.weeklyStats.dailyStats;
    final maxY = _getMaxY();

    return dailyStats.asMap().entries.map((entry) {
      final index = entry.key;
      final stat = entry.value;
      final animatedValue = stat.fatGramsBurned * _animation.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: animatedValue,
            color: _getBarColor(stat.fatGramsBurned, maxY),
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                _getBarColor(stat.fatGramsBurned, maxY),
                _getBarColor(stat.fatGramsBurned, maxY).withOpacity(0.7),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  /// 棒グラフの色を取得
  Color _getBarColor(double value, double maxValue) {
    final intensity = maxValue > 0 ? value / maxValue : 0.0;
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (intensity > 0.8) {
      return primaryColor;
    } else if (intensity > 0.6) {
      return primaryColor.withOpacity(0.8);
    } else if (intensity > 0.4) {
      return primaryColor.withOpacity(0.6);
    } else if (intensity > 0.2) {
      return primaryColor.withOpacity(0.4);
    } else {
      return primaryColor.withOpacity(0.2);
    }
  }

  /// 凡例
  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(
          color: Theme.of(context).colorScheme.primary,
          label: 'High Activity',
        ),
        const SizedBox(width: 16),
        _buildLegendItem(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
          label: 'Medium Activity',
        ),
        const SizedBox(width: 16),
        _buildLegendItem(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          label: 'Low Activity',
        ),
      ],
    );
  }

  /// 凡例アイテム
  Widget _buildLegendItem({
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  /// 期間テキストを取得
  String _getPeriodText() {
    switch (widget.period) {
      case 0:
        return 'Today\'s Progress';
      case 1:
        final formatter = DateFormat('MMM dd');
        return '${formatter.format(widget.weeklyStats.weekStartDate)} - ${formatter.format(widget.weeklyStats.weekEndDate)}';
      case 2:
        return 'This Month';
      default:
        return 'This Week';
    }
  }

  /// 曜日名を取得
  List<String> _getDayNames() {
    return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  }

  /// Y軸の最大値を取得
  double _getMaxY() {
    final maxValue = widget.weeklyStats.dailyStats.fold<double>(
      0,
      (max, stat) => stat.fatGramsBurned > max ? stat.fatGramsBurned : max,
    );

    // 最大値の1.2倍を上限にして、きりの良い数にする
    final upper = maxValue * 1.2;

    if (upper <= 10) {
      return 10;
    } else if (upper <= 25) {
      return 25;
    } else if (upper <= 50) {
      return 50;
    } else if (upper <= 100) {
      return 100;
    } else {
      return (upper / 50).ceil() * 50;
    }
  }
}