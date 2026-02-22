/// 行情数据模型
class MarketTicker {
  final String symbol;
  final double price;
  final double change24h;
  final double volume24h;
  final double high24h;
  final double low24h;
  final DateTime timestamp;

  MarketTicker({
    required this.symbol,
    required this.price,
    required this.change24h,
    required this.volume24h,
    required this.high24h,
    required this.low24h,
    required this.timestamp,
  });

  /// 从 JSON 解析
  factory MarketTicker.fromJson(Map<String, dynamic> json) {
    return MarketTicker(
      symbol: json['symbol'] as String,
      price: double.parse(json['price'].toString()),
      change24h: double.parse(json['change24h'].toString()),
      volume24h: double.parse(json['volume24h'].toString()),
      high24h: double.parse(json['high24h'].toString()),
      low24h: double.parse(json['low24h'].toString()),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        json['timestamp'] as int,
      ),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'price': price.toString(),
      'change24h': change24h.toString(),
      'volume24h': volume24h.toString(),
      'high24h': high24h.toString(),
      'low24h': low24h.toString(),
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  /// 判断是否上涨
  bool get isPositive => change24h >= 0;

  /// 格式化涨跌幅
  String get formattedChange =>
      '${isPositive ? '+' : ''}${change24h.toStringAsFixed(2)}%';

  /// 格式化价格
  String formatPrice([int decimals = 2]) {
    return price.toStringAsFixed(decimals);
  }

  /// 格式化成交量
  String formatVolume() {
    if (volume24h >= 1e9) {
      return '${(volume24h / 1e9).toStringAsFixed(2)}B';
    } else if (volume24h >= 1e6) {
      return '${(volume24h / 1e6).toStringAsFixed(2)}M';
    } else if (volume24h >= 1e3) {
      return '${(volume24h / 1e3).toStringAsFixed(2)}K';
    }
    return volume24h.toStringAsFixed(2);
  }
}

