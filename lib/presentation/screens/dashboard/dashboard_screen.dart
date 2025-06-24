import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../widgets/charts/fat_burn_chart.dart';
import '../../widgets/charts/weekly_progress_chart.dart';
import '../../widgets/summary/daily_summary_card.dart';
import '../../../core/services/injector.dart';
import '../../../domain/models/activity_model.dart';
import '../../../domain/models/weekly_activity_stats.dart';
import '../../../domain/repositories/activity_repository.dart';

/// メインダッシュボード画面
///
/// ユーザーの健康データとアクティビティを美しく表示し、
/// 直感的なナビゲーションとインタラクションを提供します。
class DashboardScreen extends StatefulWidget {
  final String userId;

  const DashboardScreen({
    super.key,
    required this.userId,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late final ActivityRepository _activityRepository;

  // アニメーションコントローラー
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // データ状態
  WeeklyActivityStats? _weeklyStats;
  List<Activity> _recentActivities = [];

  bool _isLoading = true;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();
  int _selectedPeriod = 0; // 0: 今日, 1: 今週, 2: 今月

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
    _loadDashboardData();
  }

  void _initializeServices() {
    _activityRepository = Injector().getActivityRepository(widget.userId);
  }

  void _initializeAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  /// ダッシュボードデータを読み込み
  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 並行してデータを取得
      await Future.wait([
        _loadWeeklyStats(),
        _loadRecentActivities(),
      ]);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // アニメーション開始
        _fadeAnimationController.forward();
        _slideAnimationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load dashboard data: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  /// 週間統計を取得
  Future<void> _loadWeeklyStats() async {
    final weekStart = _getStartOfWeek(_selectedDate);
    _weeklyStats = await _activityRepository.getWeeklyActivityStats(
      weekStartDate: weekStart,
    );
  }

  /// 最近のアクティビティを取得
  Future<void> _loadRecentActivities() async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 7));

    final activities = await _activityRepository.getActivities(
      startDate: startDate,
      endDate: endDate,
    );

    _recentActivities = activities.take(10).toList();
  }

  /// 週の開始日を取得（月曜日）
  DateTime _getStartOfWeek(DateTime date) {
    final dayOfWeek = date.weekday;
    return date.subtract(Duration(days: dayOfWeek - 1));
  }

  /// リフレッシュ処理
  Future<void> _refresh() async {
    await _loadDashboardData();
  }

  /// 期間変更ハンドラー
  void _onPeriodChanged(int period) {
    setState(() {
      _selectedPeriod = period;
    });
    _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_isLoading)
            _buildLoadingSliver()
          else if (_errorMessage != null)
            _buildErrorSliver()
          else
            _buildContentSliver(),
        ],
      ),
    );
  }

  /// アプリバーを構築
  Widget _buildAppBar() {
    return SliverAppBar.large(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      expandedHeight: 160,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FatGram Dashboard',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _getGreetingMessage(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            // 通知画面へのナビゲーション
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () {
            // 設定画面へのナビゲーション
          },
        ),
      ],
    );
  }

  /// ローディング表示
  Widget _buildLoadingSliver() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading your health data...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// エラー表示
  Widget _buildErrorSliver() {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// メインコンテンツ
  Widget _buildContentSliver() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 期間選択
                _buildPeriodSelector(),
                const SizedBox(height: 24),

                // 日次サマリーカード
                if (_weeklyStats != null)
                  DailySummaryCard(
                    weeklyStats: _weeklyStats!,
                    selectedPeriod: _selectedPeriod,
                  ),
                const SizedBox(height: 24),

                // 脂肪燃焼チャート
                if (_weeklyStats != null)
                  FatBurnChart(
                    weeklyStats: _weeklyStats!,
                    period: _selectedPeriod,
                  ),
                const SizedBox(height: 24),

                // 週間進捗チャート
                WeeklyProgressChart(
                  recentActivities: _recentActivities,
                ),
                const SizedBox(height: 24),

                // 最近のアクティビティ
                _buildRecentActivities(),
                const SizedBox(height: 100), // 下部のスペース
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 期間選択器
  Widget _buildPeriodSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPeriodButton('Today', 0),
            _buildPeriodButton('This Week', 1),
            _buildPeriodButton('This Month', 2),
          ],
        ),
      ),
    );
  }

  /// 期間ボタン
  Widget _buildPeriodButton(String label, int period) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onPeriodChanged(period),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }



  /// 最近のアクティビティ表示
  Widget _buildRecentActivities() {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activities',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // アクティビティ詳細画面へ
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentActivities.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.fitness_center_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No recent activities',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentActivities.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final activity = _recentActivities[index];
                  return _buildActivityTile(activity);
                },
              ),
          ],
        ),
      ),
    );
  }

  /// アクティビティタイル
  Widget _buildActivityTile(Activity activity) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          _getActivityIcon(activity.type),
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        _getActivityName(activity.type),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        _formatActivitySubtitle(activity),
      ),
              trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${activity.caloriesBurned.toStringAsFixed(0)} cal',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              _formatDuration(Duration(seconds: activity.durationInSeconds)),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      onTap: () {
        // アクティビティ詳細へ
      },
    );
  }

  /// アクティビティアイコンを取得
  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.running:
        return Icons.directions_run;
      case ActivityType.cycling:
        return Icons.directions_bike;
      case ActivityType.swimming:
        return Icons.pool;
      case ActivityType.walking:
        return Icons.directions_walk;
      case ActivityType.workout:
        return Icons.fitness_center;
      default:
        return Icons.fitness_center;
    }
  }

  /// アクティビティ名を取得
  String _getActivityName(ActivityType type) {
    return type.toString().split('.').last.toUpperCase();
  }

  /// アクティビティのサブタイトルをフォーマット
  String _formatActivitySubtitle(Activity activity) {
    final timeAgo = _formatTimeAgo(activity.timestamp);
    return timeAgo;
  }

  /// 時間差をフォーマット
  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// 継続時間をフォーマット
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// 挨拶メッセージを取得
  String _getGreetingMessage() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning! Ready to burn some fat?';
    } else if (hour < 17) {
      return 'Good afternoon! Keep up the great work!';
    } else {
      return 'Good evening! Time to check your progress!';
    }
  }
}