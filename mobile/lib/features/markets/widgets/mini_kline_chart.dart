import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:candlesticks/candlesticks.dart';
import '../models/kline_interval.dart';
import '../models/market_ticker.dart';
import '../providers/market_detail_provider.dart';
import '../providers/markets_provider.dart';

/// 迷你K线图组件（用于多图表对比）
class MiniKlineChart extends ConsumerWidget {
  final String symbol;
  final KlineInterval interval;
  final VoidCallback? onTap;
  final bool showHeader;

  const MiniKlineChart({
    super.key,
    required this.symbol,
    required this.interval,
    this.onTap,
    this.showHeader = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final klineDataState = ref.watch(klineDataProvider((symbol, interval)));
    final tickersAsync = ref.watch(rawTickersProvider);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // 头部信息
            if (showHeader) _buildHeader(context, tickersAsync),
            
            // K线图
            Expanded(
              child: _buildChart(klineDataState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AsyncValue<List<dynamic>> tickersAsync) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: tickersAsync.when(
        data: (tickers) {
          if (tickers.isEmpty) {
            return Text(
              symbol,
              style: const TextStyle(fontSize: 12),
            );
          }

          // 查找匹配的ticker
          MarketTicker? ticker;
          try {
            final tickerData = tickers.firstWhere(
              (t) => t.symbol == symbol,
              orElse: () => tickers.first,
            );
            ticker = tickerData as MarketTicker;
          } catch (e) {
            // 如果转换失败，返回简单显示
            return Text(
              symbol,
              style: const TextStyle(fontSize: 12),
            );
          }

          final isPositive = ticker.isPositive;
          final changeColor = isPositive ? Colors.green : Colors.red;

          return Row(
            children: [
              // 交易对名称
              Expanded(
                child: Text(
                  symbol,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // 价格
              Text(
                ticker.formatPrice(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: changeColor,
                ),
              ),
              
              const SizedBox(width: 4),
              
              // 涨跌幅
              Text(
                ticker.formattedChange,
                style: TextStyle(
                  fontSize: 10,
                  color: changeColor,
                ),
              ),
            ],
          );
        },
        loading: () => const SizedBox(
          height: 20,
          child: Center(
            child: SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (_, __) => Text(
          symbol,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildChart(KlineDataState state) {
    if (state.isLoading && state.data.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state.data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 32, color: Colors.grey[400]),
            const SizedBox(height: 4),
            Text(
              '暂无数据',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // 转换为 candlesticks 库需要的格式
    final candles = state.data.map((data) {
      return Candle(
        date: data.timestamp,
        high: data.high,
        low: data.low,
        open: data.open,
        close: data.close,
        volume: data.volume,
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Candlesticks(
        candles: candles,
        actions: const [], // 移除所有工具栏
      ),
    );
  }
}

