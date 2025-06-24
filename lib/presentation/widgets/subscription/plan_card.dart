import 'package:flutter/material.dart';
import '../../../domain/entities/subscription.dart';

/// サブスクリプションプランを表示するカードウィジェット
class PlanCard extends StatefulWidget {
  final SubscriptionPackage package;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isLoading;

  const PlanCard({
    super.key,
    required this.package,
    required this.onTap,
    this.isSelected = false,
    this.isLoading = false,
  });

  @override
  State<PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<PlanCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = widget.isSelected;
    final isLoading = widget.isLoading;

    return Semantics(
      label: _getSemanticLabel(),
      button: true,
      selected: isSelected,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) => _animationController.forward(),
          onTapUp: (_) => _animationController.reverse(),
          onTapCancel: () => _animationController.reverse(),
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Card(
              elevation: _getElevation(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: _getBorderColor(theme),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.primaryColor.withOpacity(0.1),
                            theme.primaryColor.withOpacity(0.05),
                          ],
                        )
                      : null,
                ),
                child: InkWell(
                  onTap: isLoading ? null : widget.onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: isLoading
                        ? _buildLoadingContent()
                        : _buildContent(theme),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ヘッダー部分（タイトル・おすすめバッジ・選択アイコン）
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getPeriodText(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getBillingText(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.package.isRecommended) ...[
              Badge(
                label: Text(
                  'おすすめ',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: theme.primaryColor,
                child: const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              widget.isSelected
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: widget.isSelected
                  ? theme.primaryColor
                  : theme.colorScheme.onSurface.withOpacity(0.6),
              size: 24,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 価格表示
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              widget.package.product.priceString,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 8),
            if (_shouldShowMonthlyEquivalent()) ...[
              Text(
                '月換算 \$${widget.package.monthlyEquivalentPrice.toStringAsFixed(2)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 8),

        // 製品タイトル
        Text(
          widget.package.product.title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),

        // 無料トライアル情報
        if (widget.package.product.hasFreeTrial) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star,
                  size: 16,
                  color: Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.package.product.freeTrialDays}日間無料',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],

        // 割引情報
        if (widget.package.discountPercentage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${widget.package.discountPercentage!.toStringAsFixed(0)}% お得',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '処理中...',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  String _getPeriodText() {
    switch (widget.package.period) {
      case SubscriptionPeriod.monthly:
        return '月額';
      case SubscriptionPeriod.yearly:
        return '年額';
      case SubscriptionPeriod.quarterly:
        return '四半期';
      case SubscriptionPeriod.weekly:
        return '週額';
      case SubscriptionPeriod.lifetime:
        return '買い切り';
      default:
        return '不明';
    }
  }

  String _getBillingText() {
    switch (widget.package.period) {
      case SubscriptionPeriod.monthly:
        return '毎月請求';
      case SubscriptionPeriod.yearly:
        return '年に1度請求';
      case SubscriptionPeriod.quarterly:
        return '3ヶ月ごと請求';
      case SubscriptionPeriod.weekly:
        return '毎週請求';
      case SubscriptionPeriod.lifetime:
        return '一度のお支払い';
      default:
        return '';
    }
  }

  bool _shouldShowMonthlyEquivalent() {
    return widget.package.period == SubscriptionPeriod.yearly ||
           widget.package.period == SubscriptionPeriod.quarterly;
  }

  double _getElevation() {
    if (widget.isLoading) return 2;
    if (widget.isSelected) return 8;
    if (_isHovered) return 6;
    return 2;
  }

  Color _getBorderColor(ThemeData theme) {
    if (widget.isSelected) return theme.primaryColor;
    if (_isHovered) return theme.primaryColor.withOpacity(0.5);
    return theme.colorScheme.outline.withOpacity(0.3);
  }

  String _getSemanticLabel() {
    final period = _getPeriodText();
    final price = widget.package.product.priceString;
    final recommended = widget.package.isRecommended ? 'おすすめプラン' : '';
    final selected = widget.isSelected ? '選択済み' : '';
    final loading = widget.isLoading ? '処理中' : '';

    if (widget.isLoading) {
      return '処理中';
    }

    if (widget.package.isRecommended) {
      return 'おすすめプラン';
    }

    final parts = [
      if (selected.isNotEmpty) selected,
      '$period $price',
      if (recommended.isNotEmpty) recommended,
    ].where((part) => part.isNotEmpty).join(' ');

    return parts.isNotEmpty ? parts : 'プランを選択';
  }
}