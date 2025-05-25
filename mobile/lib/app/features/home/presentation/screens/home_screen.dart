import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain/repositories/activity_repository.dart';
import '../../../../../di/injector.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FatGram'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // プロフィール画面へ遷移
            },
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          // activityRepositoryProvider を使用
          return FutureBuilder(
            future: _getActivitiesSummary(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'データの読み込みに失敗しました: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final summary = snapshot.data;

              if (summary == null) {
                return const Center(
                  child: Text('データがありません。アクティビティを同期してください。'),
                );
              }

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard(context, summary),
                      const SizedBox(height: 24),
                      _buildActivitySection(context),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // スマートウォッチデータの同期
          _syncSmartWatchData(context);
        },
        child: const Icon(Icons.sync),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, Map<String, dynamic> summary) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '今週の記録',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  context,
                  '消費カロリー',
                  '${summary['totalCalories'].toStringAsFixed(1)} kcal',
                  Icons.whatshot,
                ),
                _buildSummaryItem(
                  context,
                  '脂肪燃焼量',
                  '${summary['totalFatBurned'].toStringAsFixed(1)} g',
                  Icons.local_fire_department,
                ),
                _buildSummaryItem(
                  context,
                  'アクティビティ',
                  '${summary['totalActivities']}',
                  Icons.directions_run,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildActivitySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '最近のアクティビティ',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () {
                // アクティビティ一覧画面へ遷移
              },
              child: const Text('すべて見る'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // アクティビティが無い場合のプレースホルダー
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.directions_walk),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'スマートウォッチを連携してアクティビティを記録',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('右下の同期ボタンをタップして開始'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _getActivitiesSummary() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endDate = startDate.add(const Duration(days: 7));

    try {
      // activityRepositoryProviderを使用
      final activityRepository = activityRepositoryProvider;
      final results = await Injector.read(activityRepository).getWeeklyActivityStats(
        startDate: startDate,
        endDate: endDate,
      );

      // 仮のサンプルデータ
      return {
        'totalActivities': results['totalActivities'] ?? 0,
        'totalCalories': results['totalCalories'] ?? 0.0,
        'totalFatBurned': results['totalFatBurned'] ?? 0.0,
      };
    } catch (e) {
      // エラーの場合は仮のデータを返す
      return {
        'totalActivities': 0,
        'totalCalories': 0.0,
        'totalFatBurned': 0.0,
      };
    }
  }

  Future<void> _syncSmartWatchData(BuildContext context) async {
    try {
      // 同期処理中のダイアログを表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('スマートウォッチデータを同期中...'),
            ],
          ),
        ),
      );

      // 同期処理を実行
      final activityRepository = activityRepositoryProvider;
      final result = await Injector.read(activityRepository).syncActivities();

      // ダイアログを閉じる
      if (context.mounted) {
        Navigator.of(context).pop();

        // 結果を表示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['success'] == true
                  ? '同期が完了しました: ${result['syncedActivities'] ?? 0}件のデータを同期'
                  : '同期に失敗しました: ${result['error'] ?? '不明なエラー'}',
            ),
          ),
        );
      }
    } catch (e) {
      // エラー処理
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    }
  }
}