import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/injector.dart';
import '../../domain/models/activity_model.dart';
import '../../domain/models/weekly_activity_stats.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../domain/repositories/user_repository.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ActivityRepository _activityRepository;
  late final UserRepository _userRepository;

  WeeklyActivityStats? _weeklyStats;
  bool _isLoading = true;
  String? _errorMessage;

  // 現在の週の開始日
  DateTime _currentWeekStart = _getStartOfWeek(DateTime.now());

  // 週の開始日（月曜日）を取得
  static DateTime _getStartOfWeek(DateTime date) {
    final dayOfWeek = date.weekday;
    return date.subtract(Duration(days: dayOfWeek - 1));
  }

  @override
  void initState() {
    super.initState();
    _activityRepository = Injector().getActivityRepository(widget.userId);
    _userRepository = Injector().getUserRepository();
    _loadData();
  }

  // データ読み込み
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // スマートウォッチからデータを同期
      await _activityRepository.syncActivitiesFromHealthKit();

      // 週間統計を取得
      final weeklyStats = await _activityRepository.getWeeklyActivityStats(
        weekStartDate: _currentWeekStart,
      );

      if (mounted) {
        setState(() {
          _weeklyStats = weeklyStats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load data: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  // 前の週に移動
  void _previousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
    _loadData();
  }

  // 次の週に移動
  void _nextWeek() {
    final now = DateTime.now();
    final nextWeekStart = _currentWeekStart.add(const Duration(days: 7));

    // 未来の週は表示しない
    if (nextWeekStart.isBefore(now)) {
      setState(() {
        _currentWeekStart = nextWeekStart;
      });
      _loadData();
    }
  }

  // ログアウト処理
  Future<void> _logout() async {
    try {
      await _userRepository.logout();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FatGram'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildContent() {
    if (_weeklyStats == null) {
      return const Center(
        child: Text('No data available for this week'),
      );
    }

    final dateFormat = DateFormat('MMM dd');
    final weekRangeText = '${dateFormat.format(_weeklyStats!.weekStartDate)} - ${dateFormat.format(_weeklyStats!.weekEndDate)}';

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 週の日付範囲と移動ボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  onPressed: _previousWeek,
                ),
                Text(
                  weekRangeText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios),
                  onPressed: _nextWeek,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 総合統計
            _buildSummaryCard(),
            const SizedBox(height: 24),

            // 日別グラフ
            _buildDailyChart(),
            const SizedBox(height: 24),

            // 日別のリスト
            const Text(
              'Daily Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildDailyList(),
          ],
        ),
      ),
    );
  }

  // 総合統計カード
  Widget _buildSummaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.local_fire_department,
                  value: '${_weeklyStats!.totalFatGramsBurned.toStringAsFixed(1)}g',
                  label: 'Fat Burned',
                  color: Colors.deepOrange,
                ),
                _buildStatItem(
                  icon: Icons.bolt,
                  value: '${_weeklyStats!.totalCaloriesBurned.toStringAsFixed(0)} kcal',
                  label: 'Calories',
                  color: Colors.amber,
                ),
                _buildStatItem(
                  icon: Icons.timer,
                  value: _formatDuration(_weeklyStats!.totalDurationInSeconds),
                  label: 'Duration',
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${_weeklyStats!.totalActivityCount} activities recorded',
                style: const TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 統計アイテム
  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  // 日別グラフ
  Widget _buildDailyChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fat Burning Timeline',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildBarChart(),
            ),
          ],
        ),
      ),
    );
  }

  // 棒グラフ（シンプルな実装）
  Widget _buildBarChart() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dailyStats = _weeklyStats!.dailyStats;

    // 脂肪燃焼量の最大値を計算
    double maxFat = 0;
    for (final stat in dailyStats) {
      if (stat.fatGramsBurned > maxFat) {
        maxFat = stat.fatGramsBurned;
      }
    }
    // 最大値が0の場合は1にする（ゼロ除算防止）
    maxFat = maxFat > 0 ? maxFat : 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (index) {
        final dayIndex = index;
        final stat = dailyStats.length > dayIndex ? dailyStats[dayIndex] : DailyStats.empty(DateTime.now());
        final barHeight = (stat.fatGramsBurned / maxFat) * 150;

        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${stat.fatGramsBurned.toStringAsFixed(1)}g',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
              Container(
                height: barHeight > 0 ? barHeight : 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Text(days[index]),
            ],
          ),
        );
      }),
    );
  }

  // 日別リスト
  Widget _buildDailyList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _weeklyStats!.dailyStats.length,
      itemBuilder: (context, index) {
        final dailyStat = _weeklyStats!.dailyStats[index];
        final day = DateFormat('EEEE, MMM d').format(dailyStat.date);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(day),
            subtitle: Text(
              '${dailyStat.activityCount} activities, ${_formatDuration(dailyStat.totalDurationInSeconds)}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${dailyStat.fatGramsBurned.toStringAsFixed(1)}g',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
                Text(
                  '${dailyStat.caloriesBurned.toStringAsFixed(0)} kcal',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            onTap: () {
              // 詳細画面へ遷移するなどの処理
            },
          ),
        );
      },
    );
  }

  // 時間をフォーマット
  String _formatDuration(int seconds) {
    final hours = (seconds / 3600).floor();
    final minutes = ((seconds % 3600) / 60).floor();

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}