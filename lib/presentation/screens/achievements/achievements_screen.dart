import 'package:flutter/material.dart';

import '../../../domain/models/user_model.dart';
import '../../../domain/models/activity_model.dart';
import '../../../domain/models/weekly_activity_stats.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../domain/repositories/activity_repository.dart';
import '../../../core/services/injector.dart';

/// アチーブメント（実績）データモデル
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int currentProgress;
  final int targetProgress;
  final String category;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
    this.unlockedAt,
    required this.currentProgress,
    required this.targetProgress,
    required this.category,
  });

  double get progressPercentage =>
      currentProgress / targetProgress * 100;
}

/// アチーブメント画面
///
/// ユーザーの実績、バッジ、マイルストーンを
/// 美しく魅力的に表示する画面です。
class AchievementsScreen extends StatefulWidget {
  final String userId;

  const AchievementsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  late final UserRepository _userRepository;
  late final ActivityRepository _activityRepository;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  User? _user;
  List<Activity> _activities = [];
  List<Achievement> _achievements = [];
  String _selectedCategory = 'All';

  bool _isLoading = true;

  final List<String> _categories = [
    'All',
    'Activity',
    'Fat Burning',
    'Consistency',
    'Milestones',
  ];

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
    _loadAchievements();
  }

  void _initializeServices() {
    _userRepository = Injector().getUserRepository();
    _activityRepository = Injector().getActivityRepository(widget.userId);
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// アチーブメントデータを読み込み
  Future<void> _loadAchievements() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _user = await _userRepository.getCurrentUser();

      // 過去1年のアクティビティを取得
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 365));
      _activities = await _activityRepository.getActivities(
        startDate: startDate,
        endDate: endDate,
      );

      _generateAchievements();

      setState(() {
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// アチーブメントを生成
  void _generateAchievements() {
    final totalActivities = _activities.length;
    final totalCalories = _activities.fold<double>(
      0, (sum, activity) => sum + activity.caloriesBurned);
    final totalFatBurned = _activities.fold<double>(
      0, (sum, activity) => sum + activity.fatGramsBurned);
    final totalDuration = _activities.fold<int>(
      0, (sum, activity) => sum + activity.durationInSeconds);

    // 連続日数を計算
    final streakDays = _calculateStreakDays();

    _achievements = [
      // Activity Achievements
      Achievement(
        id: 'first_workout',
        title: 'First Steps',
        description: 'Complete your first workout',
        icon: Icons.directions_run,
        color: Colors.green,
        isUnlocked: totalActivities >= 1,
        unlockedAt: _activities.isNotEmpty ? _activities.first.timestamp : null,
        currentProgress: totalActivities >= 1 ? 1 : 0,
        targetProgress: 1,
        category: 'Activity',
      ),
      Achievement(
        id: 'workout_10',
        title: 'Getting Started',
        description: 'Complete 10 workouts',
        icon: Icons.fitness_center,
        color: Colors.blue,
        isUnlocked: totalActivities >= 10,
        unlockedAt: totalActivities >= 10 ? _activities[9].timestamp : null,
        currentProgress: totalActivities,
        targetProgress: 10,
        category: 'Activity',
      ),
      Achievement(
        id: 'workout_50',
        title: 'Dedicated Athlete',
        description: 'Complete 50 workouts',
        icon: Icons.emoji_events,
        color: Colors.orange,
        isUnlocked: totalActivities >= 50,
        unlockedAt: totalActivities >= 50 ? _activities[49].timestamp : null,
        currentProgress: totalActivities,
        targetProgress: 50,
        category: 'Activity',
      ),

      // Fat Burning Achievements
      Achievement(
        id: 'fat_100g',
        title: 'Fat Burner',
        description: 'Burn 100g of fat',
        icon: Icons.local_fire_department,
        color: Colors.red,
        isUnlocked: totalFatBurned >= 100,
        unlockedAt: totalFatBurned >= 100 ? DateTime.now() : null,
        currentProgress: totalFatBurned.toInt(),
        targetProgress: 100,
        category: 'Fat Burning',
      ),
      Achievement(
        id: 'fat_500g',
        title: 'Fat Melter',
        description: 'Burn 500g of fat',
        icon: Icons.whatshot,
        color: Colors.deepOrange,
        isUnlocked: totalFatBurned >= 500,
        unlockedAt: totalFatBurned >= 500 ? DateTime.now() : null,
        currentProgress: totalFatBurned.toInt(),
        targetProgress: 500,
        category: 'Fat Burning',
      ),
      Achievement(
        id: 'fat_1kg',
        title: 'Fat Destroyer',
        description: 'Burn 1kg of fat',
        icon: Icons.flash_on,
        color: Colors.purple,
        isUnlocked: totalFatBurned >= 1000,
        unlockedAt: totalFatBurned >= 1000 ? DateTime.now() : null,
        currentProgress: totalFatBurned.toInt(),
        targetProgress: 1000,
        category: 'Fat Burning',
      ),

      // Consistency Achievements
      Achievement(
        id: 'streak_3',
        title: 'Three Day Streak',
        description: 'Work out 3 days in a row',
        icon: Icons.schedule,
        color: Colors.teal,
        isUnlocked: streakDays >= 3,
        unlockedAt: streakDays >= 3 ? DateTime.now() : null,
        currentProgress: streakDays,
        targetProgress: 3,
        category: 'Consistency',
      ),
      Achievement(
        id: 'streak_7',
        title: 'Week Warrior',
        description: 'Work out 7 days in a row',
        icon: Icons.calendar_today,
        color: Colors.indigo,
        isUnlocked: streakDays >= 7,
        unlockedAt: streakDays >= 7 ? DateTime.now() : null,
        currentProgress: streakDays,
        targetProgress: 7,
        category: 'Consistency',
      ),

      // Milestone Achievements
      Achievement(
        id: 'calories_10k',
        title: 'Calorie Crusher',
        description: 'Burn 10,000 calories',
        icon: Icons.speed,
        color: Colors.amber,
        isUnlocked: totalCalories >= 10000,
        unlockedAt: totalCalories >= 10000 ? DateTime.now() : null,
        currentProgress: totalCalories.toInt(),
        targetProgress: 10000,
        category: 'Milestones',
      ),
      Achievement(
        id: 'time_100h',
        title: 'Time Champion',
        description: 'Exercise for 100 hours',
        icon: Icons.access_time,
        color: Colors.cyan,
        isUnlocked: totalDuration >= 360000, // 100 hours in seconds
        unlockedAt: totalDuration >= 360000 ? DateTime.now() : null,
        currentProgress: (totalDuration / 3600).toInt(),
        targetProgress: 100,
        category: 'Milestones',
      ),
    ];
  }

  /// 連続日数を計算
  int _calculateStreakDays() {
    if (_activities.isEmpty) return 0;

    final sortedActivities = List<Activity>.from(_activities)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    int streak = 0;
    DateTime? lastDate;

    for (final activity in sortedActivities) {
      final activityDate = DateTime(
        activity.timestamp.year,
        activity.timestamp.month,
        activity.timestamp.day,
      );

      if (lastDate == null) {
        lastDate = activityDate;
        streak = 1;
      } else {
        final difference = lastDate.difference(activityDate).inDays;
        if (difference == 1) {
          streak++;
          lastDate = activityDate;
        } else if (difference > 1) {
          break;
        }
      }
    }

    return streak;
  }

  /// フィルタリングされたアチーブメントを取得
  List<Achievement> get _filteredAchievements {
    if (_selectedCategory == 'All') {
      return _achievements;
    }
    return _achievements.where((a) => a.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? _buildLoadingView()
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // 統計サマリー
                  _buildStatsSummary(),

                  // カテゴリフィルター
                  _buildCategoryFilter(),

                  // アチーブメントリスト
                  Expanded(
                    child: _buildAchievementsList(),
                  ),
                ],
              ),
            ),
    );
  }

  /// ローディング表示
  Widget _buildLoadingView() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  /// 統計サマリー
  Widget _buildStatsSummary() {
    final unlockedCount = _achievements.where((a) => a.isUnlocked).length;
    final totalCount = _achievements.length;
    final progressPercentage = (unlockedCount / totalCount * 100).toInt();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            '$unlockedCount / $totalCount',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Achievements Unlocked',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: unlockedCount / totalCount,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            '$progressPercentage% Complete',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// カテゴリフィルター
  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  /// アチーブメントリスト
  Widget _buildAchievementsList() {
    final filteredAchievements = _filteredAchievements;

    if (filteredAchievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No achievements in this category',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredAchievements.length,
      itemBuilder: (context, index) {
        final achievement = filteredAchievements[index];
        return _buildAchievementCard(achievement, index);
      },
    );
  }

  /// アチーブメントカード
  Widget _buildAchievementCard(Achievement achievement, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: achievement.isUnlocked ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: achievement.isUnlocked
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      achievement.color.withOpacity(0.1),
                      achievement.color.withOpacity(0.05),
                    ],
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // アイコン
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: achievement.isUnlocked
                        ? achievement.color
                        : Colors.grey.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    achievement.icon,
                    color: achievement.isUnlocked
                        ? Colors.white
                        : Colors.grey,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // コンテンツ
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              achievement.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: achievement.isUnlocked
                                    ? null
                                    : Colors.grey,
                              ),
                            ),
                          ),
                          if (achievement.isUnlocked)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: achievement.color,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'UNLOCKED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        achievement.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: achievement.isUnlocked
                              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // プログレスバー
                      if (!achievement.isUnlocked) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${achievement.currentProgress}/${achievement.targetProgress}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '${(achievement.progressPercentage).toInt()}%',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: achievement.currentProgress / achievement.targetProgress,
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            achievement.color.withOpacity(0.7),
                          ),
                        ),
                      ] else if (achievement.unlockedAt != null) ...[
                        Text(
                          'Unlocked ${_formatDate(achievement.unlockedAt!)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: achievement.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 日付フォーマット
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    }
  }
}