import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fatgram/domain/models/ai/user_recommendation.dart';
import 'package:fatgram/app/features/ai/recommendation/recommendation_controller.dart';

class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends ConsumerState<RecommendationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // 初期ロード
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecommendations(RecommendationType.workout);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadRecommendations(RecommendationType type) {
    ref.read(recommendationControllerProvider.notifier).generateRecommendations(type: type);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recommendationControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('パーソナライズド推奨'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            final types = [
              RecommendationType.workout,
              RecommendationType.nutrition,
              RecommendationType.lifestyle,
              RecommendationType.goal,
            ];
            _loadRecommendations(types[index]);
          },
          tabs: const [
            Tab(text: 'ワークアウト'),
            Tab(text: '栄養'),
            Tab(text: 'ライフスタイル'),
            Tab(text: '目標'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRecommendationList(state, RecommendationType.workout),
          _buildRecommendationList(state, RecommendationType.nutrition),
          _buildRecommendationList(state, RecommendationType.lifestyle),
          _buildRecommendationList(state, RecommendationType.goal),
        ],
      ),
    );
  }

  Widget _buildRecommendationList(RecommendationState state, RecommendationType type) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('エラー: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadRecommendations(type),
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    final recommendations = state.recommendations
        .where((rec) => rec.type == type)
        .toList();

    if (recommendations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/empty_recommendations.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 16),
            const Text(
              'おすすめが見つかりません',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'あなたに合ったおすすめを生成します',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('おすすめを生成'),
              onPressed: () => _loadRecommendations(type),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadRecommendations(type),
      child: ListView.builder(
        itemCount: recommendations.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final recommendation = recommendations[index];
          return _buildRecommendationCard(recommendation);
        },
      ),
    );
  }

  Widget _buildRecommendationCard(UserRecommendation recommendation) {
    final confidencePercentage = (recommendation.confidenceScore * 100).toInt();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー部分
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getIconForType(recommendation.type),
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendation.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '適合度 $confidencePercentage%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 内容部分
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.description,
                  style: const TextStyle(fontSize: 16),
                ),
                if (recommendation.tags != null && recommendation.tags!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: recommendation.tags!.map((tag) {
                        return Chip(
                          label: Text(tag),
                          backgroundColor: Colors.grey[200],
                          labelStyle: const TextStyle(fontSize: 12),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),

          // アクションボタン部分
          if (recommendation.actions != null && recommendation.actions!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: recommendation.actions!.map((action) {
                  return TextButton(
                    onPressed: () => _handleActionPressed(action, recommendation),
                    child: Text(action.title),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIconForType(RecommendationType type) {
    switch (type) {
      case RecommendationType.workout:
        return Icons.fitness_center;
      case RecommendationType.nutrition:
        return Icons.restaurant;
      case RecommendationType.lifestyle:
        return Icons.nightlife;
      case RecommendationType.goal:
        return Icons.flag;
    }
  }

  void _handleActionPressed(RecommendationAction action, UserRecommendation recommendation) {
    final controller = ref.read(recommendationControllerProvider.notifier);

    switch (action.actionType) {
      case 'open_details':
        // 詳細画面へ遷移する実装
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${recommendation.title}の詳細を表示します')),
        );
        break;
      case 'save':
        // 保存処理の実装
        controller.saveRecommendationFeedback(
          recommendationId: recommendation.id,
          isHelpful: true,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${recommendation.title}を保存しました')),
        );
        break;
      default:
        break;
    }
  }
}