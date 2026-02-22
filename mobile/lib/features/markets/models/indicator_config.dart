import 'package:flutter/material.dart';

/// 指标类型枚举
enum IndicatorType {
  ma,    // 移动平均线
  ema,   // 指数移动平均线
  boll,  // 布林带
  macd,  // MACD
  rsi,   // 相对强弱指标
  kdj,   // KDJ随机指标
}

/// 指标配置基类
abstract class IndicatorConfig {
  final IndicatorType type;
  final bool enabled;

  const IndicatorConfig({
    required this.type,
    required this.enabled,
  });

  /// 获取指标显示名称
  String get displayName;
}

/// MA均线配置
class MAConfig extends IndicatorConfig {
  final int period;
  final Color color;

  const MAConfig({
    required this.period,
    required this.color,
    bool enabled = true,
  }) : super(
          type: IndicatorType.ma,
          enabled: enabled,
        );

  @override
  String get displayName => 'MA$period';

  MAConfig copyWith({
    int? period,
    Color? color,
    bool? enabled,
  }) {
    return MAConfig(
      period: period ?? this.period,
      color: color ?? this.color,
      enabled: enabled ?? this.enabled,
    );
  }
}

/// EMA指数移动平均线配置
class EMAConfig extends IndicatorConfig {
  final int period;
  final Color color;

  const EMAConfig({
    required this.period,
    required this.color,
    bool enabled = true,
  }) : super(
          type: IndicatorType.ema,
          enabled: enabled,
        );

  @override
  String get displayName => 'EMA$period';

  EMAConfig copyWith({
    int? period,
    Color? color,
    bool? enabled,
  }) {
    return EMAConfig(
      period: period ?? this.period,
      color: color ?? this.color,
      enabled: enabled ?? this.enabled,
    );
  }
}

/// BOLL布林带配置
class BOLLConfig extends IndicatorConfig {
  final int period;
  final double stdDev;
  final Color upperColor;
  final Color middleColor;
  final Color lowerColor;

  const BOLLConfig({
    this.period = 20,
    this.stdDev = 2.0,
    this.upperColor = Colors.purple,
    this.middleColor = Colors.orange,
    this.lowerColor = Colors.purple,
    bool enabled = false,
  }) : super(
          type: IndicatorType.boll,
          enabled: enabled,
        );

  @override
  String get displayName => 'BOLL($period,$stdDev)';

  BOLLConfig copyWith({
    int? period,
    double? stdDev,
    Color? upperColor,
    Color? middleColor,
    Color? lowerColor,
    bool? enabled,
  }) {
    return BOLLConfig(
      period: period ?? this.period,
      stdDev: stdDev ?? this.stdDev,
      upperColor: upperColor ?? this.upperColor,
      middleColor: middleColor ?? this.middleColor,
      lowerColor: lowerColor ?? this.lowerColor,
      enabled: enabled ?? this.enabled,
    );
  }
}

/// MACD配置
class MACDConfig extends IndicatorConfig {
  final int fastPeriod;
  final int slowPeriod;
  final int signalPeriod;
  final Color difColor;
  final Color deaColor;
  final Color macdColor;

  const MACDConfig({
    this.fastPeriod = 12,
    this.slowPeriod = 26,
    this.signalPeriod = 9,
    this.difColor = Colors.blue,
    this.deaColor = Colors.orange,
    this.macdColor = Colors.red,
    bool enabled = true,
  }) : super(
          type: IndicatorType.macd,
          enabled: enabled,
        );

  @override
  String get displayName => 'MACD($fastPeriod,$slowPeriod,$signalPeriod)';

  MACDConfig copyWith({
    int? fastPeriod,
    int? slowPeriod,
    int? signalPeriod,
    Color? difColor,
    Color? deaColor,
    Color? macdColor,
    bool? enabled,
  }) {
    return MACDConfig(
      fastPeriod: fastPeriod ?? this.fastPeriod,
      slowPeriod: slowPeriod ?? this.slowPeriod,
      signalPeriod: signalPeriod ?? this.signalPeriod,
      difColor: difColor ?? this.difColor,
      deaColor: deaColor ?? this.deaColor,
      macdColor: macdColor ?? this.macdColor,
      enabled: enabled ?? this.enabled,
    );
  }
}

/// RSI配置
class RSIConfig extends IndicatorConfig {
  final int period;
  final Color color;
  final double overbought;
  final double oversold;

  const RSIConfig({
    this.period = 14,
    this.color = Colors.purple,
    this.overbought = 70.0,
    this.oversold = 30.0,
    bool enabled = false,
  }) : super(
          type: IndicatorType.rsi,
          enabled: enabled,
        );

  @override
  String get displayName => 'RSI($period)';

  RSIConfig copyWith({
    int? period,
    Color? color,
    double? overbought,
    double? oversold,
    bool? enabled,
  }) {
    return RSIConfig(
      period: period ?? this.period,
      color: color ?? this.color,
      overbought: overbought ?? this.overbought,
      oversold: oversold ?? this.oversold,
      enabled: enabled ?? this.enabled,
    );
  }
}

/// KDJ配置
class KDJConfig extends IndicatorConfig {
  final int period;
  final Color kColor;
  final Color dColor;
  final Color jColor;

  const KDJConfig({
    this.period = 9,
    this.kColor = Colors.blue,
    this.dColor = Colors.orange,
    this.jColor = Colors.purple,
    bool enabled = false,
  }) : super(
          type: IndicatorType.kdj,
          enabled: enabled,
        );

  @override
  String get displayName => 'KDJ($period)';

  KDJConfig copyWith({
    int? period,
    Color? kColor,
    Color? dColor,
    Color? jColor,
    bool? enabled,
  }) {
    return KDJConfig(
      period: period ?? this.period,
      kColor: kColor ?? this.kColor,
      dColor: dColor ?? this.dColor,
      jColor: jColor ?? this.jColor,
      enabled: enabled ?? this.enabled,
    );
  }
}

/// 指标数据
class IndicatorData {
  final IndicatorType type;
  final Map<String, List<double?>> values;

  const IndicatorData({
    required this.type,
    required this.values,
  });
}

/// 预设的MA配置
class MAPresets {
  static const ma5 = MAConfig(period: 5, color: Color(0xFF1E88E5));
  static const ma10 = MAConfig(period: 10, color: Color(0xFFFFA726));
  static const ma20 = MAConfig(period: 20, color: Color(0xFFAB47BC));
  static const ma30 = MAConfig(period: 30, color: Color(0xFF26A69A));
  static const ma60 = MAConfig(period: 60, color: Color(0xFFEF5350));

  static List<MAConfig> get defaults => [ma5, ma10, ma20, ma30];
}

