import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/kline_interval.dart';
import '../providers/multi_chart_provider.dart';
import '../widgets/mini_kline_chart.dart';
import 'market_detail_screen.dart';
import '../models/market_filter.dart';

/// 多图表对比页面
class MultiChartScreen extends ConsumerWidget {
  const MultiChartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(multiChartProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.multiChartComparison),
        actions: [
          // 布局切换按钮
          PopupMenuButton<ChartLayoutType>(
            icon: const Icon(Icons.grid_view),
            tooltip: l10n.switchLayout,
            onSelected: (layout) {
              ref.read(multiChartProvider.notifier).setLayout(layout);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ChartLayoutType.single,
                child: Row(
                  children: [
                    const Icon(Icons.crop_square, size: 20),
                    const SizedBox(width: 8),
                    Text(l10n.singleChart),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ChartLayoutType.vertical2,
                child: Row(
                  children: [
                    const Icon(Icons.view_agenda, size: 20),
                    const SizedBox(width: 8),
                    Text(l10n.vertical2Split),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ChartLayoutType.horizontal2,
                child: Row(
                  children: [
                    const Icon(Icons.view_day, size: 20),
                    const SizedBox(width: 8),
                    Text(l10n.horizontal2Split),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ChartLayoutType.grid4,
                child: Row(
                  children: [
                    const Icon(Icons.grid_on, size: 20),
                    const SizedBox(width: 8),
                    Text(l10n.grid2x2),
                  ],
                ),
              ),
            ],
          ),
          
          // 同步设置按钮
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.syncSettings,
            onPressed: () {
              _showSyncSettings(context, ref);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 同步状态指示
          if (state.syncInterval || state.syncZoom)
            _buildSyncIndicator(l10n, state),
          
          // 图表区域
          Expanded(
            child: _buildChartLayout(context, ref, state),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncIndicator(AppLocalizations l10n, MultiChartState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.blue[50],
      child: Row(
        children: [
          const Icon(Icons.sync, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${l10n.syncEnabled}: ${state.syncInterval ? l10n.intervalSync : ""}${state.syncInterval && state.syncZoom ? "、" : ""}${state.syncZoom ? l10n.zoomSync : ""}',
              style: const TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLayout(BuildContext context, WidgetRef ref, MultiChartState state) {
    switch (state.layoutType) {
      case ChartLayoutType.single:
        return _buildSingleLayout(context, ref, state);
      case ChartLayoutType.vertical2:
        return _buildVertical2Layout(context, ref, state);
      case ChartLayoutType.horizontal2:
        return _buildHorizontal2Layout(context, ref, state);
      case ChartLayoutType.grid4:
        return _buildGrid4Layout(context, ref, state);
    }
  }

  Widget _buildSingleLayout(BuildContext context, WidgetRef ref, MultiChartState state) {
    if (state.charts.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.all(8),
      child: _buildChartItem(context, ref, 0, state.charts[0]),
    );
  }

  Widget _buildVertical2Layout(BuildContext context, WidgetRef ref, MultiChartState state) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            child: _buildChartItem(context, ref, 0, state.charts[0]),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _buildChartItem(context, ref, 1, state.charts[1]),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontal2Layout(BuildContext context, WidgetRef ref, MultiChartState state) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: _buildChartItem(context, ref, 0, state.charts[0]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildChartItem(context, ref, 1, state.charts[1]),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid4Layout(BuildContext context, WidgetRef ref, MultiChartState state) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildChartItem(context, ref, 0, state.charts[0]),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildChartItem(context, ref, 1, state.charts[1]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildChartItem(context, ref, 2, state.charts[2]),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildChartItem(context, ref, 3, state.charts[3]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartItem(BuildContext context, WidgetRef ref, int index, ChartConfig config) {
    final l10n = AppLocalizations.of(context)!;
    return Stack(
      children: [
        MiniKlineChart(
          symbol: config.symbol,
          interval: config.interval,
          onTap: () {
            // 点击跳转到详情页
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MarketDetailScreen(
                  symbol: config.symbol,
                  marketType: MarketType.spot,
                ),
              ),
            );
          },
        ),
        
        // 右上角菜单按钮
        Positioned(
          top: 4,
          right: 4,
          child: PopupMenuButton(
            icon: Icon(Icons.more_vert, size: 16, color: Colors.grey[600]),
            padding: EdgeInsets.zero,
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Text(l10n.changeSymbol),
                onTap: () {
                  Future.delayed(Duration.zero, () {
                    _showSymbolPicker(context, ref, index);
                  });
                },
              ),
              PopupMenuItem(
                child: Text(l10n.switchInterval),
                onTap: () {
                  Future.delayed(Duration.zero, () {
                    _showIntervalPicker(context, ref, index);
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSyncSettings(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.read(multiChartProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.syncSettings),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text(l10n.intervalSync),
              subtitle: Text(l10n.intervalSyncDesc),
              value: state.syncInterval,
              onChanged: (value) {
                ref.read(multiChartProvider.notifier).toggleSyncInterval();
                Navigator.pop(context);
              },
            ),
            SwitchListTile(
              title: Text(l10n.zoomSync),
              subtitle: Text(l10n.zoomSyncDesc),
              value: state.syncZoom,
              onChanged: (value) {
                ref.read(multiChartProvider.notifier).toggleSyncZoom();
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _showSymbolPicker(BuildContext context, WidgetRef ref, int index) {
    final l10n = AppLocalizations.of(context)!;
    // 简化版：显示常用交易对
    final symbols = [
      'BTCUSDT', 'ETHUSDT', 'BNBUSDT', 'SOLUSDT',
      'ADAUSDT', 'XRPUSDT', 'DOGEUSDT', 'DOTUSDT',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectSymbol),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: symbols.length,
            itemBuilder: (context, i) {
              return ListTile(
                title: Text(symbols[i]),
                onTap: () {
                  ref.read(multiChartProvider.notifier).updateChartSymbol(index, symbols[i]);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showIntervalPicker(BuildContext context, WidgetRef ref, int index) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectInterval),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: KlineInterval.commonIntervals.length,
            itemBuilder: (context, i) {
              final interval = KlineInterval.commonIntervals[i];
              return ListTile(
                title: Text(interval.label),
                onTap: () {
                  ref.read(multiChartProvider.notifier).updateChartInterval(index, interval);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

