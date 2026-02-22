import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/realtime_price_provider.dart';

/// 市场价格统计卡片
class MarketStatsCard extends ConsumerWidget {
  final String symbol;

  const MarketStatsCard({
    super.key,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // 使用实时价格Provider
    final realtimePrice = ref.watch(realtimePriceProvider(symbol));

    if (realtimePrice == null) {
      return _buildLoading();
    }

    return _buildContent(context, l10n, theme, realtimePrice);
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    RealtimePrice price,
  ) {
    final isPositive = price.isPositive;
    final changeColor = isPositive ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧: 价格信息
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 最新价格标签
                Text(
                  l10n.latestPriceLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                // 最新价格 (根据涨跌显示颜色)
                Text(
                  price.formatPrice(),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: changeColor, // 涨绿跌红
                  ),
                ),
                const SizedBox(height: 2),
                // 美元价格 + 涨跌幅
                Row(
                  children: [
                    Text(
                      '≈\$${price.formatPrice()}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      price.formattedChange,
                      style: TextStyle(
                        color: changeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // 标记价格
                Row(
                  children: [
                    Text(
                      l10n.markPrice,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      price.formatPrice(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // 右侧: 24小时统计 (2列,居右对齐)
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 第一行: 最高价和成交量
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: _buildStatItem(
                        label: l10n.high24hPrice,
                        value: price.high24h.toStringAsFixed(2),
                        alignment: CrossAxisAlignment.end,
                        fontSize: 11,
                        valueFontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: _buildStatItem(
                        label: '${l10n.volume24hAmount})',
                        value: price.formatVolume(),
                        alignment: CrossAxisAlignment.end,
                        fontSize: 11,
                        valueFontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 第二行: 最低价和成交额
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: _buildStatItem(
                        label: l10n.low24hPrice,
                        value: price.low24h.toStringAsFixed(2),
                        alignment: CrossAxisAlignment.end,
                        fontSize: 11,
                        valueFontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: _buildStatItem(
                        label: l10n.amount24h,
                        value: _formatAmount(price.volume24h * price.price),
                        alignment: CrossAxisAlignment.end,
                        fontSize: 11,
                        valueFontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    CrossAxisAlignment alignment = CrossAxisAlignment.start,
    double fontSize = 12,
    double valueFontSize = 16,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            color: Colors.grey[600],
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: valueFontSize,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildShimmer(width: 200, height: 32),
          const SizedBox(height: 8),
          _buildShimmer(width: 150, height: 16),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildShimmer(width: double.infinity, height: 40)),
              const SizedBox(width: 16),
              Expanded(child: _buildShimmer(width: double.infinity, height: 40)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError(AppLocalizations l10n, Object error) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          '${l10n.loading}: $error',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildShimmer({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  /// 获取基础货币
  String _getBaseCurrency(String symbol) {
    if (symbol.contains('/')) {
      return symbol.split('/')[0];
    } else {
      return symbol.replaceAll('USDT', '');
    }
  }

  /// 格式化金额
  String _formatAmount(double amount) {
    if (amount >= 1e9) {
      return '${(amount / 1e9).toStringAsFixed(2)}B';
    } else if (amount >= 1e6) {
      return '${(amount / 1e6).toStringAsFixed(2)}M';
    } else if (amount >= 1e3) {
      return '${(amount / 1e3).toStringAsFixed(2)}K';
    }
    return amount.toStringAsFixed(2);
  }
}

