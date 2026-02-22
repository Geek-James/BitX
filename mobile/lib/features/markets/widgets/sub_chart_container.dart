import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/indicator_config.dart';
import '../providers/indicator_provider.dart';
import 'macd_chart.dart';
import 'rsi_chart.dart';
import 'kdj_chart.dart';

/// 副图容器组件
/// 根据选择的指标类型显示对应的副图
class SubChartContainer extends ConsumerWidget {
  final String symbol;

  const SubChartContainer({
    super.key,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subIndicatorType = ref.watch(subIndicatorTypeProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: _buildSubChart(subIndicatorType),
    );
  }

  Widget _buildSubChart(IndicatorType type) {
    switch (type) {
      case IndicatorType.macd:
        return MACDChart(symbol: symbol);
      case IndicatorType.rsi:
        return RSIChart(symbol: symbol);
      case IndicatorType.kdj:
        return KDJChart(symbol: symbol);
      default:
        return MACDChart(symbol: symbol);
    }
  }
}

