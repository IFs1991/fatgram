import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/activity_model.dart';

/// アクティビティ詳細画面
///
/// 単一のアクティビティの詳細情報を表示し、
/// 編集・共有・削除機能を提供します。
class ActivityDetailScreen extends StatefulWidget {
  final Activity activity;
  final VoidCallback? onActivityUpdated;
  final VoidCallback? onActivityDeleted;

  const ActivityDetailScreen({
    super.key,
    required this.activity,
    this.onActivityUpdated,
    this.onActivityDeleted,
  });

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          _buildContentSliver(),
        ],
      ),
    );
  }

  /// アプリバーを構築
  Widget _buildAppBar() {
    return SliverAppBar.large(
      backgroundColor: _getActivityColor(widget.activity.type),
      foregroundColor: Colors.white,
      expandedHeight: 200,
      pinned: true,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getActivityName(widget.activity.type),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              _formatDate(widget.activity.timestamp),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
        centerTitle: false,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getActivityColor(widget.activity.type),
                _getActivityColor(widget.activity.type).withOpacity(0.8),
              ],
            ),
          ),
          child: Center(
            child: Icon(
              _getActivityIcon(widget.activity.type),
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ),
      ),
      actions: [
        if (!_isEditing) ...[
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _toggleEditMode,
          ),
          PopupMenuButton<String>(
            onSelected: _onMenuSelected,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Share'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Export'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ] else ...[
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveChanges,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancelEdit,
          ),
        ],
      ],
    );
  }

  /// コンテンツスライバー
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
                // サマリーカード
                _buildSummaryCard(),
                const SizedBox(height: 16),

                // 統計カード
                _buildStatisticsCard(),
                const SizedBox(height: 16),

                // タイムライン
                _buildTimelineCard(),
                const SizedBox(height: 16),

                // メモ・ノート
                _buildNotesCard(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// サマリーカード
  Widget _buildSummaryCard() {
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
            Text(
              'Activity Summary',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    icon: Icons.timer,
                    label: 'Duration',
                    value: _formatDuration(Duration(seconds: widget.activity.durationInSeconds)),
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    icon: Icons.local_fire_department,
                    label: 'Calories',
                    value: '${widget.activity.caloriesBurned.toStringAsFixed(0)}',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    icon: Icons.directions_run,
                    label: 'Distance',
                    value: widget.activity.distanceInMeters != null
                        ? '${(widget.activity.distanceInMeters! / 1000).toStringAsFixed(2)} km'
                        : 'N/A',
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    icon: Icons.whatshot,
                    label: 'Fat Burned',
                    value: '${widget.activity.fatGramsBurned.toStringAsFixed(1)}g',
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// サマリーアイテム
  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
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

  /// 統計カード
  Widget _buildStatisticsCard() {
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
            Text(
              'Detailed Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Activity ID', widget.activity.id),
            _buildStatRow('Timestamp', _formatTime(widget.activity.timestamp)),
            _buildStatRow('Activity Type', _getActivityName(widget.activity.type)),
            _buildStatRow('Duration', _formatDuration(Duration(seconds: widget.activity.durationInSeconds))),
            _buildStatRow('Calories Burned', '${widget.activity.caloriesBurned.toStringAsFixed(0)} cal'),
            if (widget.activity.distanceInMeters != null)
              _buildStatRow('Distance', '${(widget.activity.distanceInMeters! / 1000).toStringAsFixed(2)} km'),
            _buildStatRow('Fat Burned', '${widget.activity.fatGramsBurned.toStringAsFixed(1)} g'),
          ],
        ),
      ),
    );
  }

  /// 統計行
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  /// タイムラインカード
  Widget _buildTimelineCard() {
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
            Text(
              'Activity Timeline',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTimelineItem(
              icon: Icons.play_arrow,
              title: 'Activity Started',
              time: _formatTime(widget.activity.timestamp),
              isFirst: true,
            ),
            _buildTimelineItem(
              icon: Icons.stop,
              title: 'Activity Completed',
              time: _formatTime(widget.activity.timestamp.add(Duration(seconds: widget.activity.durationInSeconds))),
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  /// タイムラインアイテム
  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String time,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      children: [
        Column(
          children: [
            if (!isFirst)
              Container(
                height: 20,
                width: 2,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
            ),
            if (!isLast)
              Container(
                height: 20,
                width: 2,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                time,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// ノートカード
  Widget _buildNotesCard() {
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
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_isEditing)
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Add notes about this activity...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) {
                  // ノートの変更を処理
                },
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.activity.metadata?['notes'] ?? 'No notes added for this activity yet.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 編集モード切り替え
  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  /// 変更保存
  void _saveChanges() {
    setState(() {
      _isEditing = false;
      _isLoading = true;
    });

    // TODO: 実際の保存処理
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });

      if (widget.onActivityUpdated != null) {
        widget.onActivityUpdated!();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activity updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  /// 編集キャンセル
  void _cancelEdit() {
    setState(() {
      _isEditing = false;
    });
  }

  /// メニュー選択処理
  void _onMenuSelected(String value) {
    switch (value) {
      case 'share':
        _shareActivity();
        break;
      case 'export':
        _exportActivity();
        break;
      case 'delete':
        _deleteActivity();
        break;
    }
  }

  /// アクティビティ共有
  void _shareActivity() {
    final text = 'I just completed a ${_getActivityName(widget.activity.type)} '
        'activity for ${_formatDuration(Duration(seconds: widget.activity.durationInSeconds))}! '
        'Burned ${widget.activity.caloriesBurned.toStringAsFixed(0)} calories and ${widget.activity.fatGramsBurned.toStringAsFixed(1)}g fat! '
        '#FatGram #Fitness';

    // TODO: 実際の共有処理
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sharing: $text')),
    );
  }

  /// アクティビティエクスポート
  void _exportActivity() {
    // TODO: エクスポート処理
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Activity exported successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// アクティビティ削除
  void _deleteActivity() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: const Text('Are you sure you want to delete this activity? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performDelete();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// 削除実行
  void _performDelete() {
    // TODO: 実際の削除処理

    if (widget.onActivityDeleted != null) {
      widget.onActivityDeleted!();
    }

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Activity deleted'),
        backgroundColor: Colors.red,
      ),
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

  /// アクティビティ色を取得
  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.running:
        return Colors.orange;
      case ActivityType.cycling:
        return Colors.blue;
      case ActivityType.swimming:
        return Colors.cyan;
      case ActivityType.walking:
        return Colors.green;
      case ActivityType.workout:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// アクティビティ名を取得
  String _getActivityName(ActivityType type) {
    switch (type) {
      case ActivityType.running:
        return 'Running';
      case ActivityType.cycling:
        return 'Cycling';
      case ActivityType.swimming:
        return 'Swimming';
      case ActivityType.walking:
        return 'Walking';
      case ActivityType.workout:
        return 'Workout';
      default:
        return 'Activity';
    }
  }

  /// 日付フォーマット
  String _formatDate(DateTime date) {
    return DateFormat('EEEE, MMMM d, yyyy').format(date);
  }

  /// 時間フォーマット
  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  /// 継続時間フォーマット
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}