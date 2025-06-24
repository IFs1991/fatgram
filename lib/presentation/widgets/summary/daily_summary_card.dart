import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/weekly_activity_stats.dart';

/// 日次サマリーカードウィジェット
///
/// 選択された期間に基づいて健康データのサマリーを表示します。
class DailySummaryCard extends StatefulWidget {
  final WeeklyActivityStats weeklyStats;
  final int selectedPeriod; // 0: 今日, 1: 今週, 2: 今月

  const DailySummaryCard({
    super.key,
    required this.weeklyStats,
    required this.selectedPeriod,
  });

  @override
  State<DailySummaryCard> createState() => _DailySummaryCardState();
}

class _DailySummaryCardState extends State<DailySummaryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _cardAnimations = List.generate(4, (index) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          index * 0.1,
          (index * 0.1) + 0.4,
          curve: Curves.easeOutCubic,
        ),
      ));
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildSummaryCards(),
      ],
    );
  }

  /// ヘッダー部分
  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.dashboard,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          _getHeaderTitle(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _getPeriodBadge(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// サマリーカード群
  Widget _buildSummaryCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildSummaryCard(
          title: 'Fat Burned',
          value: '${widget.weeklyStats.totalFatGramsBurned.toStringAsFixed(1)}g',
          icon: Icons.local_fire_department,
          color: Colors.orange,
          animation: _cardAnimations[0],
          subtitle: _getProgressText('fat'),
        ),
        _buildSummaryCard(
          title: 'Calories',
          value: '${widget.weeklyStats.totalCaloriesBurned.toStringAsFixed(0)}',
          icon: Icons.flash_on,
          color: Colors.red,
          animation: _cardAnimations[1],
          subtitle: _getProgressText('calories'),
        ),
        _buildSummaryCard(
          title: 'Duration',
          value: _formatDuration(widget.weeklyStats.totalDurationInSeconds),
          icon: Icons.timer,
          color: Colors.blue,
          animation: _cardAnimations[2],
          subtitle: _getProgressText('duration'),
        ),
        _buildSummaryCard(
          title: 'Activities',
          value: '${widget.weeklyStats.totalActivityCount}',
          icon: Icons.fitness_center,
          color: Colors.green,
          animation: _cardAnimations[3],
          subtitle: _getProgressText('activities'),
        ),
      ],
    );
  }

  /// 個別サマリーカード
  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Animation<double> animation,
    required String subtitle,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: animation.value,
          child: Opacity(
            opacity: animation.value,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.1),
                      color.withOpacity(0.05),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            icon,
                            color: color,
                            size: 20,
                          ),
                        ),
                        Icon(
                          Icons.trending_up,
                          color: color.withOpacity(0.6),
                          size: 16,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// ヘッダータイトルを取得
  String _getHeaderTitle() {
    switch (widget.selectedPeriod) {
      case 0:
        return 'Today\'s Summary';
      case 1:
        return 'Weekly Summary';
      case 2:
        return 'Monthly Summary';
      default:
        return 'Summary';
    }
  }

  /// 期間バッジテキストを取得
  String _getPeriodBadge() {
    switch (widget.selectedPeriod) {
      case 0:
        return 'TODAY';
      case 1:
        final formatter = DateFormat('MMM dd');
        return '${formatter.format(widget.weeklyStats.weekStartDate)} - ${formatter.format(widget.weeklyStats.weekEndDate)}';
      case 2:
        return 'THIS MONTH';
      default:
        return 'CURRENT';
    }
  }

  /// 進捗テキストを取得
  String _getProgressText(String type) {
    switch (widget.selectedPeriod) {
      case 0:
        return 'vs yesterday';
      case 1:
        return 'vs last week';
      case 2:
        return 'vs last month';
      default:
        return 'progress';
    }
  }

  /// 継続時間をフォーマット
  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}