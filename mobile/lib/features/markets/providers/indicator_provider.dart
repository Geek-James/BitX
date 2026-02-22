import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/indicator_config.dart';
import '../models/kline_interval.dart';
import '../utils/indicator_calculator.dart';
import 'market_detail_provider.dart';

/// 主图指标配置列表 (MA, EMA, BOLL)
final mainIndicatorsProvider = StateProvider<List<IndicatorConfig>>((ref) {
  return [
    MAPresets.ma5,
    MAPresets.ma10,
    MAPresets.ma20,
    MAPresets.ma30,
  ];
});

/// 副图指标类型 (MACD, RSI, KDJ)
final subIndicatorTypeProvider = StateProvider<IndicatorType>((ref) {
  return IndicatorType.macd;
});

/// 副图指标配置
final subIndicatorConfigProvider = Provider<IndicatorConfig>((ref) {
  final type = ref.watch(subIndicatorTypeProvider);
  
  switch (type) {
    case IndicatorType.macd:
      return const MACDConfig();
    case IndicatorType.rsi:
      return const RSIConfig();
    case IndicatorType.kdj:
      return const KDJConfig();
    default:
      return const MACDConfig();
  }
});

/// 计算主图指标数据
final mainIndicatorDataProvider = Provider.family<Map<String, IndicatorData>, (String, KlineInterval)>(
  (ref, params) {
    final (symbol, interval) = params;
    final klineData = ref.watch(klineDataListProvider((symbol, interval)));
    final indicators = ref.watch(mainIndicatorsProvider);
    
    final result = <String, IndicatorData>{};
    
    for (final indicator in indicators) {
      if (!indicator.enabled) continue;
      
      if (indicator is MAConfig) {
        final values = IndicatorCalculator.calculateMA(
          klineData,
          indicator.period,
        );
        result['MA${indicator.period}'] = IndicatorData(
          type: IndicatorType.ma,
          values: {'ma': values},
        );
      } else if (indicator is EMAConfig) {
        final values = IndicatorCalculator.calculateEMA(
          klineData,
          indicator.period,
        );
        result['EMA${indicator.period}'] = IndicatorData(
          type: IndicatorType.ema,
          values: {'ema': values},
        );
      } else if (indicator is BOLLConfig) {
        final values = IndicatorCalculator.calculateBOLL(
          klineData,
          period: indicator.period,
          stdDev: indicator.stdDev,
        );
        result['BOLL'] = IndicatorData(
          type: IndicatorType.boll,
          values: values,
        );
      }
    }
    
    return result;
  },
);

/// 计算副图指标数据
final subIndicatorDataProvider = Provider.family<IndicatorData?, (String, KlineInterval)>(
  (ref, params) {
    final (symbol, interval) = params;
    final klineData = ref.watch(klineDataListProvider((symbol, interval)));
    final config = ref.watch(subIndicatorConfigProvider);
    
    if (!config.enabled) return null;
    
    if (config is MACDConfig) {
      final values = IndicatorCalculator.calculateMACD(
        klineData,
        fastPeriod: config.fastPeriod,
        slowPeriod: config.slowPeriod,
        signalPeriod: config.signalPeriod,
      );
      return IndicatorData(
        type: IndicatorType.macd,
        values: values,
      );
    } else if (config is RSIConfig) {
      final values = IndicatorCalculator.calculateRSI(
        klineData,
        period: config.period,
      );
      return IndicatorData(
        type: IndicatorType.rsi,
        values: {'rsi': values},
      );
    } else if (config is KDJConfig) {
      final values = IndicatorCalculator.calculateKDJ(
        klineData,
        period: config.period,
      );
      return IndicatorData(
        type: IndicatorType.kdj,
        values: values,
      );
    }
    
    return null;
  },
);

/// 切换主图指标的启用状态
void toggleMainIndicator(WidgetRef ref, int index) {
  final indicators = ref.read(mainIndicatorsProvider);
  if (index < 0 || index >= indicators.length) return;
  
  final updatedIndicators = List<IndicatorConfig>.from(indicators);
  final indicator = indicators[index];
  
  if (indicator is MAConfig) {
    updatedIndicators[index] = indicator.copyWith(enabled: !indicator.enabled);
  } else if (indicator is EMAConfig) {
    updatedIndicators[index] = indicator.copyWith(enabled: !indicator.enabled);
  } else if (indicator is BOLLConfig) {
    updatedIndicators[index] = indicator.copyWith(enabled: !indicator.enabled);
  }
  
  ref.read(mainIndicatorsProvider.notifier).state = updatedIndicators;
}

/// 切换副图指标类型
void switchSubIndicator(WidgetRef ref, IndicatorType type) {
  ref.read(subIndicatorTypeProvider.notifier).state = type;
}

