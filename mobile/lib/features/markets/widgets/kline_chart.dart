import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:candlesticks/candlesticks.dart';
import '../models/chart_theme.dart';
import '../providers/market_detail_provider.dart';
import '../providers/chart_theme_provider.dart';

/// K线图表组件
/// 
/// 支持的手势操作:
/// - 双指缩放: 放大/缩小图表
/// - 单指拖动: 左右滑动查看历史数据
/// - 长按: 显示十字线和详细数据
class KlineChart extends ConsumerWidget {
  final String symbol;

  const KlineChart({
    super.key,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedInterval = ref.watch(selectedIntervalProvider);
    final klineDataState = ref.watch(klineDataProvider((symbol, selectedInterval)));
    final theme = ref.watch(chartThemeProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: _buildContent(klineDataState, theme),
    );
  }
  
  Widget _buildContent(KlineDataState state, ChartTheme theme) {
    if (state.isLoading && state.data.isEmpty) {
      return _buildLoading();
    }
    
    if (state.error != null && state.data.isEmpty) {
      return _buildError(state.error!);
    }
    
    if (state.data.isEmpty) {
      return _buildEmpty();
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

    return Candlesticks(
      candles: candles,
      // 加载更多历史数据回调
      onLoadMoreCandles: () async {
        // TODO: 实现加载更多历史数据
        return Future.value();
      },
      // 移除所有工具栏操作按钮
      actions: const [],
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '暂无K线数据',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            '加载失败: $error',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

