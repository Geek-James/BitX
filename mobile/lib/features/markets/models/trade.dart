/// 交易记录模型
class Trade {
  final String id;
  final String symbol;
  final double price;
  final double amount;
  final DateTime timestamp;
  final bool isBuy; // true=买入(主动买), false=卖出(主动卖)

  Trade({
    required this.id,
    required this.symbol,
    required this.price,
    required this.amount,
    required this.timestamp,
    required this.isBuy,
  });

  factory Trade.fromJson(Map<String, dynamic> json) {
    return Trade(
      id: json['id'].toString(),
      symbol: json['symbol'] as String,
      price: double.parse(json['price'].toString()),
      amount: double.parse(json['amount'].toString()),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isBuy: json['isBuy'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'price': price,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'isBuy': isBuy,
    };
  }

  Trade copyWith({
    String? id,
    String? symbol,
    double? price,
    double? amount,
    DateTime? timestamp,
    bool? isBuy,
  }) {
    return Trade(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      price: price ?? this.price,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      isBuy: isBuy ?? this.isBuy,
    );
  }

  /// 获取成交额
  double get total => price * amount;
}

