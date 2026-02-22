/// K线数据模型
class KlineData {
  final DateTime openTime;
  final DateTime closeTime;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  KlineData({
    DateTime? timestamp,
    DateTime? openTime,
    DateTime? closeTime,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  })  : openTime = openTime ?? timestamp ?? DateTime.now(),
        closeTime = closeTime ?? timestamp ?? DateTime.now();

  /// 便捷访问器
  DateTime get timestamp => openTime;

  /// 从 JSON 解析
  factory KlineData.fromJson(Map<String, dynamic> json) {
    return KlineData(
      openTime: DateTime.fromMillisecondsSinceEpoch(
        json['openTime'] as int,
      ),
      closeTime: DateTime.fromMillisecondsSinceEpoch(
        json['closeTime'] as int,
      ),
      open: double.parse(json['open'].toString()),
      high: double.parse(json['high'].toString()),
      low: double.parse(json['low'].toString()),
      close: double.parse(json['close'].toString()),
      volume: double.parse(json['volume'].toString()),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'openTime': openTime.millisecondsSinceEpoch,
      'closeTime': closeTime.millisecondsSinceEpoch,
      'open': open.toString(),
      'high': high.toString(),
      'low': low.toString(),
      'close': close.toString(),
      'volume': volume.toString(),
    };
  }

  /// 判断是否上涨
  bool get isPositive => close >= open;

  /// 涨跌幅
  double get changePercent => ((close - open) / open) * 100;

  /// 格式化涨跌幅
  String get formattedChange =>
      '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(2)}%';
}

