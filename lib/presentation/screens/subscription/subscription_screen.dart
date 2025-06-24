import 'package:flutter/material.dart';
import '../../../domain/repositories/subscription_repository.dart';
import '../../../domain/entities/subscription.dart';
import '../../widgets/subscription/plan_card.dart';

/// サブスクリプション管理画面
class SubscriptionScreen extends StatefulWidget {
  final SubscriptionRepository repository;

  const SubscriptionScreen({
    super.key,
    required this.repository,
  });

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with TickerProviderStateMixin {

  // State management
  bool _isLoading = true;
  bool _isPurchasing = false;
  bool _isRestoring = false;
  String? _selectedPackageId;
  List<SubscriptionOffering> _offerings = [];
  String? _errorMessage;

  // Animation controllers
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadOfferings();
  }

  void _initializeAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
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

  Future<void> _loadOfferings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await widget.repository.getOfferings();

    if (mounted) {
      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.message;
          });
        },
        (offerings) {
          setState(() {
            _isLoading = false;
            _offerings = offerings;
          });

          // 最初のパッケージを自動選択
          if (offerings.isNotEmpty && offerings.first.packages.isNotEmpty) {
            // おすすめパッケージがあればそれを選択、なければ最初のパッケージ
            final recommendedPackage = offerings.first.packages
                .where((p) => p.isRecommended)
                .firstOrNull;
            _selectedPackageId = recommendedPackage?.id ??
                                offerings.first.packages.first.id;
          }

          _fadeAnimationController.forward();
          _slideAnimationController.forward();
        },
      );
    }
  }

  Future<void> _purchasePackage(String packageId) async {
    if (_isPurchasing) return;

    setState(() {
      _isPurchasing = true;
    });

    final result = await widget.repository.purchasePackage(packageId);

    if (mounted) {
      result.fold(
        (failure) {
          setState(() => _isPurchasing = false);
          _showErrorDialog('購入エラー', failure.message);
        },
        (purchaseResult) {
          setState(() => _isPurchasing = false);

          if (purchaseResult.isSuccess) {
            _showSuccessDialog();
          } else if (!purchaseResult.userCancelled) {
            _showErrorDialog('購入エラー',
                purchaseResult.errorMessage ?? '購入に失敗しました');
          }
          // ユーザーキャンセルの場合は何もしない
        },
      );
    }
  }

  Future<void> _restorePurchases() async {
    if (_isRestoring) return;

    setState(() {
      _isRestoring = true;
    });

    final result = await widget.repository.restorePurchases();

    if (mounted) {
      result.fold(
        (failure) {
          setState(() => _isRestoring = false);
          _showErrorDialog('復元エラー', failure.message);
        },
        (restoreResult) {
          setState(() => _isRestoring = false);

          if (restoreResult.isSuccess) {
            _showRestoreSuccessDialog(restoreResult.restoredProducts.length);
          } else {
            _showErrorDialog('復元エラー',
                restoreResult.errorMessage ?? '復元に失敗しました');
          }
        },
      );
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('購入が完了しました！'),
        content: const Text('FatGram Premiumをお楽しみください'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // ダイアログを閉じる
              Navigator.of(context).pop(); // 画面を閉じる
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRestoreSuccessDialog(int restoredCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('復元完了'),
                 content: Text('${restoredCount}つの購入を復元しました'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FatGram Premium'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState(theme);
    }

    if (_offerings.isEmpty) {
      return _buildEmptyState(theme);
    }

    return _buildOfferingsContent(theme);
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'プランを読み込み中...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'エラーが発生しました',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadOfferings,
              child: const Text('再試行'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.refresh,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '現在利用可能なプランはありません',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '後でもう一度お試しください',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadOfferings,
              icon: const Icon(Icons.refresh),
              label: const Text('更新'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferingsContent(ThemeData theme) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ヘッダー説明
                    _buildHeader(theme),
                    const SizedBox(height: 24),

                    // プランカード一覧
                    ..._buildPlanCards(),

                    const SizedBox(height: 32),

                    // 機能一覧
                    _buildFeaturesList(theme),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // 下部ボタン
            _buildBottomActions(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FatGram Premium',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'すべての機能にアクセスして、より効果的なフィットネス体験を',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPlanCards() {
    final cards = <Widget>[];

    for (final offering in _offerings) {
      for (final package in offering.packages) {
        cards.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Semantics(
              label: '${package.period == SubscriptionPeriod.monthly ? '月額' : '年額'}プラン ${package.product.priceString}',
              button: true,
              child: PlanCard(
                package: package,
                isSelected: _selectedPackageId == package.id,
                isLoading: _isPurchasing && _selectedPackageId == package.id,
                onTap: () {
                  setState(() {
                    _selectedPackageId = package.id;
                  });
                },
              ),
            ),
          ),
        );
      }
    }

    return cards;
  }

  Widget _buildFeaturesList(ThemeData theme) {
    final features = [
      'すべてのワークアウトプランにアクセス',
      'パーソナライズされた栄養アドバイス',
      'リアルタイムヘルス分析',
      'AI による進捗追跡',
      '無制限のデータ同期',
      '優先サポート',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Premiumの特典',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...features.map((feature) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: theme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  feature,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildBottomActions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 購入ボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedPackageId != null && !_isPurchasing && !_isRestoring
                    ? () => _purchasePackage(_selectedPackageId!)
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isPurchasing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Semantics(
                        label: 'プランを購入',
                        child: const Text(
                          '購入する',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            // 復元ボタン
            TextButton(
              onPressed: !_isRestoring && !_isPurchasing ? _restorePurchases : null,
              child: _isRestoring
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('購入を復元'),
            ),
          ],
        ),
      ),
    );
  }
}