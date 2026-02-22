import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kline_interval.dart';

/// 图表布局类型
enum ChartLayoutType {
  single,    // 单图
  vertical2, // 垂直2分屏
  horizontal2, // 水平2分屏
  grid4,     // 2x2网格
}

/// 图表配置
class ChartConfig {
  final String id;
  final String symbol;
  final KlineInterval interval;

  const ChartConfig({
    required this.id,
    required this.symbol,
    required this.interval,
  });

  ChartConfig copyWith({
    String? symbol,
    KlineInterval? interval,
  }) {
    return ChartConfig(
      id: id,
      symbol: symbol ?? this.symbol,
      interval: interval ?? this.interval,
    );
  }
}

/// 多图表状态
class MultiChartState {
  final ChartLayoutType layoutType;
  final List<ChartConfig> charts;
  final bool syncInterval;  // 是否同步时间周期
  final bool syncZoom;      // 是否同步缩放

  const MultiChartState({
    required this.layoutType,
    required this.charts,
    this.syncInterval = false,
    this.syncZoom = false,
  });

  MultiChartState copyWith({
    ChartLayoutType? layoutType,
    List<ChartConfig>? charts,
    bool? syncInterval,
    bool? syncZoom,
  }) {
    return MultiChartState(
      layoutType: layoutType ?? this.layoutType,
      charts: charts ?? this.charts,
      syncInterval: syncInterval ?? this.syncInterval,
      syncZoom: syncZoom ?? this.syncZoom,
    );
  }

  /// 获取图表数量
  int get chartCount {
    switch (layoutType) {
      case ChartLayoutType.single:
        return 1;
      case ChartLayoutType.vertical2:
      case ChartLayoutType.horizontal2:
        return 2;
      case ChartLayoutType.grid4:
        return 4;
    }
  }
}

/// 多图表状态管理器
class MultiChartNotifier extends StateNotifier<MultiChartState> {
  MultiChartNotifier()
      : super(MultiChartState(
          layoutType: ChartLayoutType.single,
          charts: [
            ChartConfig(
              id: 'chart_0',
              symbol: 'BTCUSDT',
              interval: KlineInterval.min15,
            ),
          ],
        ));

  /// 切换布局
  void setLayout(ChartLayoutType layoutType) {
    final currentCharts = List<ChartConfig>.from(state.charts);
    final targetCount = _getChartCount(layoutType);

    // 调整图表数量
    if (currentCharts.length < targetCount) {
      // 添加图表
      for (int i = currentCharts.length; i < targetCount; i++) {
        currentCharts.add(ChartConfig(
          id: 'chart_$i',
          symbol: 'ETHUSDT', // 默认交易对
          interval: state.syncInterval && currentCharts.isNotEmpty
              ? currentCharts.first.interval
              : KlineInterval.min15,
        ));
      }
    } else if (currentCharts.length > targetCount) {
      // 移除多余图表
      currentCharts.removeRange(targetCount, currentCharts.length);
    }

    state = state.copyWith(
      layoutType: layoutType,
      charts: currentCharts,
    );
  }

  /// 更新图表交易对
  void updateChartSymbol(int index, String symbol) {
    if (index < 0 || index >= state.charts.length) return;

    final charts = List<ChartConfig>.from(state.charts);
    charts[index] = charts[index].copyWith(symbol: symbol);
    state = state.copyWith(charts: charts);
  }

  /// 更新图表时间周期
  void updateChartInterval(int index, KlineInterval interval) {
    if (index < 0 || index >= state.charts.length) return;

    if (state.syncInterval) {
      // 同步所有图表的时间周期
      final charts = state.charts
          .map((chart) => chart.copyWith(interval: interval))
          .toList();
      state = state.copyWith(charts: charts);
    } else {
      // 只更新指定图表
      final charts = List<ChartConfig>.from(state.charts);
      charts[index] = charts[index].copyWith(interval: interval);
      state = state.copyWith(charts: charts);
    }
  }

  /// 切换时间周期同步
  void toggleSyncInterval() {
    final newSync = !state.syncInterval;
    
    if (newSync && state.charts.isNotEmpty) {
      // 开启同步：将所有图表的时间周期设置为第一个图表的周期
      final firstInterval = state.charts.first.interval;
      final charts = state.charts
          .map((chart) => chart.copyWith(interval: firstInterval))
          .toList();
      state = state.copyWith(
        syncInterval: newSync,
        charts: charts,
      );
    } else {
      state = state.copyWith(syncInterval: newSync);
    }
  }

  /// 切换缩放同步
  void toggleSyncZoom() {
    state = state.copyWith(syncZoom: !state.syncZoom);
  }

  /// 获取图表数量
  int _getChartCount(ChartLayoutType layoutType) {
    switch (layoutType) {
      case ChartLayoutType.single:
        return 1;
      case ChartLayoutType.vertical2:
      case ChartLayoutType.horizontal2:
        return 2;
      case ChartLayoutType.grid4:
        return 4;
    }
  }
}

/// 多图表Provider
final multiChartProvider = StateNotifierProvider<MultiChartNotifier, MultiChartState>((ref) {
  return MultiChartNotifier();
});

/// 获取指定索引的图表配置
final chartConfigProvider = Provider.family<ChartConfig?, int>((ref, index) {
  final state = ref.watch(multiChartProvider);
  if (index < 0 || index >= state.charts.length) return null;
  return state.charts[index];
});

