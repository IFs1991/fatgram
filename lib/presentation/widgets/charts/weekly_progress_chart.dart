import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/activity_model.dart';

/// 週間進捗チャートウィジェット
///
/// 最近のアクティビティを使用して、
/// 美しいラインチャートで進捗を表示します。
class WeeklyProgressChart extends StatefulWidget {
  final List<Activity> recentActivities;

  const WeeklyProgressChart({
    super.key,
    required this.recentActivities,
  });

  @override
  State<WeeklyProgressChart> createState() => _WeeklyProgressChartState();
}

class _WeeklyProgressChartState extends State<WeeklyProgressChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _selectedMetric = 0; // 0: カロリー, 1: 距離, 2: 時間

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
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
            const SizedBox(height: 16),
            _buildMetricSelector(),
            const SizedBox(height: 24),
            _buildChart(),
            const SizedBox(height: 16),
            _buildStatsSummary(),
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
              'Weekly Progress',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Last 7 days activity trends',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        Icon(
          Icons.trending_up,
          color: Theme.of(context).colorScheme.primary,
          size: 28,
        ),
      ],
    );
  }

  /// メトリック選択器
  Widget _buildMetricSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildMetricButton('Calories', 0, Icons.local_fire_department),
          const SizedBox(width: 8),
          _buildMetricButton('Distance', 1, Icons.directions_run),
          const SizedBox(width: 8),
          _buildMetricButton('Duration', 2, Icons.timer),
        ],
      ),
    );
  }

  /// メトリックボタン
  Widget _buildMetricButton(String label, int index, IconData icon) {
    final isSelected = _selectedMetric == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMetric = index;
        });
        _animationController.reset();
        _animationController.forward();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// チャート部分
  Widget _buildChart() {
    return SizedBox(
      height: 180,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _getHorizontalInterval(),
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: _buildTitlesData(),
              borderData: FlBorderData(show: false),
              lineBarsData: [_buildLineChartBarData()],
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: Theme.of(context).colorScheme.surface,
                  tooltipBorder: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final value = spot.y;
                      final formattedValue = _formatValue(value);
                      return LineTooltipItem(
                        formattedValue,
                        TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              minY: 0,
              maxY: _getMaxY(),
            ),
          );
        },
      ),
    );
  }

  /// ラインチャートのデータを構築
  LineChartBarData _buildLineChartBarData() {
    final spots = _getDataSpots();

    return LineChartBarData(
      spots: spots.map((spot) {
        return FlSpot(spot.x, spot.y * _animation.value);
      }).toList(),
      isCurved: true,
      color: Theme.of(context).colorScheme.primary,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 4,
            color: Theme.of(context).colorScheme.primary,
            strokeWidth: 2,
            strokeColor: Theme.of(context).colorScheme.surface,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.3),
            Theme.of(context).colorScheme.primary.withOpacity(0.0),
          ],
        ),
      ),
    );
  }

  /// データポイントを取得
  List<FlSpot> _getDataSpots() {
    final spots = <FlSpot>[];
    final activities = widget.recentActivities.take(7).toList();

    // 過去7日間のデータを生成
    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      final dayActivities = activities.where((activity) {
        return activity.timestamp.day == date.day &&
               activity.timestamp.month == date.month;
      }).toList();

      double value = 0;
      switch (_selectedMetric) {
        case 0: // カロリー
          value = dayActivities.fold<double>(
            0,
            (sum, activity) => sum + activity.caloriesBurned,
          );
          break;
        case 1: // 距離（メートルからキロメートルに変換）
          value = dayActivities.fold<double>(
            0,
            (sum, activity) => sum + (activity.distanceInMeters ?? 0) / 1000,
          );
          break;
        case 2: // 時間（分）
          value = dayActivities.fold<double>(
            0,
            (sum, activity) => sum + (activity.durationInSeconds / 60),
          );
          break;
      }

      spots.add(FlSpot(i.toDouble(), value));
    }

    return spots;
  }

  /// タイトルデータを構築
  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          getTitlesWidget: (double value, TitleMeta meta) {
            final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          interval: _getHorizontalInterval(),
          getTitlesWidget: (double value, TitleMeta meta) {
            return Text(
              _formatAxisValue(value),
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

  /// 統計サマリー
  Widget _buildStatsSummary() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          label: 'Total',
          value: _getTotalValue(),
          icon: Icons.analytics,
        ),
        _buildStatItem(
          label: 'Average',
          value: _getAverageValue(),
          icon: Icons.trending_up,
        ),
        _buildStatItem(
          label: 'Best Day',
          value: _getBestDayValue(),
          icon: Icons.star,
        ),
      ],
    );
  }

  /// 統計アイテム
  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  /// 値をフォーマット
  String _formatValue(double value) {
    switch (_selectedMetric) {
      case 0:
        return '${value.toInt()} cal';
      case 1:
        return '${value.toStringAsFixed(1)} km';
      case 2:
        return '${value.toInt()} min';
      default:
        return value.toString();
    }
  }

  /// 軸の値をフォーマット
  String _formatAxisValue(double value) {
    switch (_selectedMetric) {
      case 0:
        return '${value.toInt()}';
      case 1:
        return '${value.toInt()}';
      case 2:
        return '${value.toInt()}';
      default:
        return value.toString();
    }
  }

  /// Y軸の最大値を取得
  double _getMaxY() {
    final spots = _getDataSpots();
    if (spots.isEmpty) return 100;

    final maxValue = spots.fold<double>(
      0,
      (max, spot) => spot.y > max ? spot.y : max,
    );

    return maxValue * 1.2;
  }

  /// 水平間隔を取得
  double _getHorizontalInterval() {
    final maxY = _getMaxY();
    return maxY / 5;
  }

  /// 合計値を取得
  String _getTotalValue() {
    final activities = widget.recentActivities;
    switch (_selectedMetric) {
      case 0:
        final total = activities.fold<double>(0, (sum, activity) => sum + activity.caloriesBurned);
        return '${total.toInt()}';
      case 1:
        final total = activities.fold<double>(0, (sum, activity) => sum + (activity.distanceInMeters ?? 0) / 1000);
        return '${total.toStringAsFixed(1)}';
      case 2:
        final total = activities.fold<int>(0, (sum, activity) => sum + activity.durationInSeconds);
        return '${(total / 60).toInt()}';
      default:
        return '0';
    }
  }

  /// 平均値を取得
  String _getAverageValue() {
    final activities = widget.recentActivities;
    if (activities.isEmpty) return '0';

    switch (_selectedMetric) {
      case 0:
        final total = activities.fold<double>(0, (sum, activity) => sum + activity.caloriesBurned);
        return '${(total / activities.length).toInt()}';
      case 1:
        final total = activities.fold<double>(0, (sum, activity) => sum + (activity.distanceInMeters ?? 0) / 1000);
        return '${(total / activities.length).toStringAsFixed(1)}';
      case 2:
        final total = activities.fold<int>(0, (sum, activity) => sum + activity.durationInSeconds);
        return '${(total / activities.length / 60).toInt()}';
      default:
        return '0';
    }
  }

  /// 最高日の値を取得
  String _getBestDayValue() {
    final spots = _getDataSpots();
    if (spots.isEmpty) return '0';

    final maxSpot = spots.reduce((max, spot) => spot.y > max.y ? spot : max);
    return _formatValue(maxSpot.y);
  }
}