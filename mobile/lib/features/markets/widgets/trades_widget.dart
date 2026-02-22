import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/trade.dart';
import '../providers/trades_provider.dart';

/// 最新成交组件
class TradesWidget extends ConsumerWidget {
  final String symbol;

  const TradesWidget({
    super.key,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tradesState = ref.watch(tradesProvider(symbol));

    if (tradesState.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 8),
            Text(l10n.loading),
          ],
        ),
      );
    }

    if (tradesState.error != null) {
      return Center(
        child: Text(
          '${l10n.loadingFailed}: ${tradesState.error}',
          style: TextStyle(color: Colors.red[300]),
        ),
      );
    }

    final trades = tradesState.trades;
    if (trades.isEmpty) {
      return Center(
        child: Text(l10n.noTradesData),
      );
    }

    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: ListView.builder(
            itemCount: trades.length,
            itemBuilder: (context, index) {
              return _buildTradeRow(context, trades[index]);
            },
          ),
        ),
      ],
    );
  }

  /// 构建表头
  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              l10n.timeLabel,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              l10n.directionLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              l10n.priceLabel,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              l10n.amountLabel,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建交易行
  Widget _buildTradeRow(BuildContext context, Trade trade) {
    final l10n = AppLocalizations.of(context)!;
    final timeFormat = DateFormat('HH:mm:ss');
    final color = trade.isBuy ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[100]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              timeFormat.format(trade.timestamp),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  trade.isBuy ? l10n.buy : l10n.sell,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              trade.price.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              trade.amount.toStringAsFixed(4),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

