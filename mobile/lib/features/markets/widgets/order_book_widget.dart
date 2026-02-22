import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/order_book.dart';
import '../models/order_book_entry.dart';
import '../providers/order_book_provider.dart';

/// 订单薄组件
class OrderBookWidget extends ConsumerWidget {
  final String symbol;
  final int displayDepth; // 显示档位数量

  const OrderBookWidget({
    super.key,
    required this.symbol,
    this.displayDepth = 15,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final orderBookState = ref.watch(orderBookProvider(symbol));

    if (orderBookState.isLoading) {
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

    if (orderBookState.error != null) {
      return Center(
        child: Text(
          '${l10n.loadingFailed}: ${orderBookState.error}',
          style: TextStyle(color: Colors.red[300]),
        ),
      );
    }

    final orderBook = orderBookState.orderBook;
    if (orderBook == null) {
      return Center(
        child: Text(l10n.noData),
      );
    }

    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: ListView(
            children: [
              _buildAsks(context, orderBook),
              _buildSpread(context, orderBook),
              _buildBids(context, orderBook),
            ],
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
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              l10n.priceLabel,
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
          Expanded(
            flex: 3,
            child: Text(
              l10n.totalLabel,
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

  /// 构建卖单列表
  Widget _buildAsks(BuildContext context, OrderBook orderBook) {
    final asks = orderBook.asks.take(displayDepth).toList();
    final maxTotal = asks.isNotEmpty ? asks.last.total : 1.0;

    return Column(
      children: asks.reversed.map((ask) {
        return _buildOrderBookRow(
          context: context,
          entry: ask,
          maxTotal: maxTotal,
          isBid: false,
        );
      }).toList(),
    );
  }

  /// 构建买卖价差
  Widget _buildSpread(BuildContext context, OrderBook orderBook) {
    final l10n = AppLocalizations.of(context)!;
    final spread = orderBook.spread;
    final midPrice = orderBook.midPrice;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.symmetric(
          horizontal: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (spread != null)
            Text(
              '${l10n.spread}: ${spread.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          if (midPrice != null)
            Text(
              '${l10n.midPrice}: ${midPrice.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  /// 构建买单列表
  Widget _buildBids(BuildContext context, OrderBook orderBook) {
    final bids = orderBook.bids.take(displayDepth).toList();
    final maxTotal = bids.isNotEmpty ? bids.last.total : 1.0;

    return Column(
      children: bids.map((bid) {
        return _buildOrderBookRow(
          context: context,
          entry: bid,
          maxTotal: maxTotal,
          isBid: true,
        );
      }).toList(),
    );
  }

  /// 构建订单薄行
  Widget _buildOrderBookRow({
    required BuildContext context,
    required OrderBookEntry entry,
    required double maxTotal,
    required bool isBid,
  }) {
    final percentage = (entry.total / maxTotal).clamp(0.0, 1.0);
    final color = isBid ? Colors.green : Colors.red;

    return Container(
      height: 28,
      child: Stack(
        children: [
          // 背景进度条
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: MediaQuery.of(context).size.width * percentage,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [
                    color.withOpacity(0.15),
                    color.withOpacity(0.05),
                  ],
                ),
              ),
            ),
          ),
          // 数据行
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    entry.price.toStringAsFixed(2),
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
                    entry.amount.toStringAsFixed(4),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    entry.total.toStringAsFixed(4),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

