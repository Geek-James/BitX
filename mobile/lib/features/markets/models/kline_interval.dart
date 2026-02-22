/// K线时间周期枚举
enum KlineInterval {
  timeline('timeline', '分时'),
  min1('1m', '1分'),
  min5('5m', '5分'),
  min15('15m', '15分'),
  min30('30m', '30分'),
  hour1('1h', '1时'),
  hour4('4h', '4时'),
  day1('1d', '1天'),
  week1('1w', '1周');

  final String value;
  final String label;

  const KlineInterval(this.value, this.label);

  /// 从字符串值获取枚举
  static KlineInterval fromValue(String value) {
    return KlineInterval.values.firstWhere(
      (interval) => interval.value == value,
      orElse: () => KlineInterval.min15,
    );
  }

  /// 获取所有可选项
  static List<KlineInterval> get all => KlineInterval.values;

  /// 获取常用选项
  static List<KlineInterval> get common => [
        KlineInterval.timeline,
        KlineInterval.min1,
        KlineInterval.min5,
        KlineInterval.min15,
        KlineInterval.min30,
        KlineInterval.hour1,
        KlineInterval.hour4,
        KlineInterval.day1,
      ];

  /// 获取常用选项 (别名)
  static List<KlineInterval> get commonIntervals => common;
}

/// K线参数
class KlineParams {
  final String symbol;
  final KlineInterval interval;

  const KlineParams({
    required this.symbol,
    required this.interval,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KlineParams &&
          runtimeType == other.runtimeType &&
          symbol == other.symbol &&
          interval == other.interval;

  @override
  int get hashCode => symbol.hashCode ^ interval.hashCode;
}

