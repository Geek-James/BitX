import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/markets_provider.dart';

/// 市场信息Tab
class MarketInfoTab extends ConsumerWidget {
  final String symbol;

  const MarketInfoTab({
    super.key,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tickersAsync = ref.watch(rawTickersProvider);

    return tickersAsync.when(
      data: (tickers) {
        final ticker = tickers.firstWhere(
          (t) => t.symbol == symbol,
          orElse: () => tickers.first,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 交易对信息
              _buildSection(
                l10n,
                title: l10n.tradingPairInfo,
                children: [
                  _buildInfoRow(l10n, l10n.tradingPair, ticker.symbol),
                  _buildInfoRow(l10n, l10n.baseCurrency, _getBaseCurrency(ticker.symbol)),
                  _buildInfoRow(l10n, l10n.quoteCurrency, 'USDT'),
                  _buildInfoRow(l10n, l10n.tradingStatus, l10n.trading, valueColor: Colors.green),
                ],
              ),

              const SizedBox(height: 24),

              // 市场统计
              _buildSection(
                l10n,
                title: l10n.marketStats,
                children: [
                  _buildInfoRow(l10n, l10n.high24hPrice, ticker.high24h.toStringAsFixed(2)),
                  _buildInfoRow(l10n, l10n.low24hPrice, ticker.low24h.toStringAsFixed(2)),
                  _buildInfoRow(l10n, l10n.volume24h, ticker.formatVolume()),
                  _buildInfoRow(l10n, l10n.amount24h, _formatAmount(ticker.volume24h * ticker.price)),
                  _buildInfoRow(l10n, l10n.change24h, ticker.formattedChange, 
                    valueColor: ticker.isPositive ? Colors.green : Colors.red),
                ],
              ),

              const SizedBox(height: 24),

              // 交易规则
              _buildSection(
                l10n,
                title: l10n.tradingRules,
                children: [
                  _buildInfoRow(l10n, l10n.minOrderSize, '0.001 ${_getBaseCurrency(ticker.symbol)}'),
                  _buildInfoRow(l10n, l10n.maxOrderSize, '1000 ${_getBaseCurrency(ticker.symbol)}'),
                  _buildInfoRow(l10n, l10n.priceScale, '2${l10n.decimalPlaces}'),
                  _buildInfoRow(l10n, l10n.quantityScale, '3${l10n.decimalPlaces}'),
                ],
              ),

              const SizedBox(height: 24),

              // 费率信息
              _buildSection(
                l10n,
                title: l10n.feeInfo,
                children: [
                  _buildInfoRow(l10n, l10n.makerFee, '0.10%'),
                  _buildInfoRow(l10n, l10n.takerFee, '0.10%'),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('${l10n.loadingFailed}: $error', style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildSection(
    AppLocalizations l10n, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    AppLocalizations l10n,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  String _getBaseCurrency(String symbol) {
    if (symbol.contains('/')) {
      return symbol.split('/')[0];
    } else {
      return symbol.replaceAll('USDT', '');
    }
  }

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

