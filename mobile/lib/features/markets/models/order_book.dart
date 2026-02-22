import 'order_book_entry.dart';

/// 订单薄模型
class OrderBook {
  final String symbol;
  final List<OrderBookEntry> bids; // 买单
  final List<OrderBookEntry> asks; // 卖单
  final DateTime timestamp;

  OrderBook({
    required this.symbol,
    required this.bids,
    required this.asks,
    required this.timestamp,
  });

  factory OrderBook.fromJson(Map<String, dynamic> json) {
    return OrderBook(
      symbol: json['symbol'] as String,
      bids: (json['bids'] as List)
          .map((e) => OrderBookEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      asks: (json['asks'] as List)
          .map((e) => OrderBookEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'bids': bids.map((e) => e.toJson()).toList(),
      'asks': asks.map((e) => e.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  OrderBook copyWith({
    String? symbol,
    List<OrderBookEntry>? bids,
    List<OrderBookEntry>? asks,
    DateTime? timestamp,
  }) {
    return OrderBook(
      symbol: symbol ?? this.symbol,
      bids: bids ?? this.bids,
      asks: asks ?? this.asks,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// 获取最优买价
  double? get bestBid => bids.isNotEmpty ? bids.first.price : null;

  /// 获取最优卖价
  double? get bestAsk => asks.isNotEmpty ? asks.first.price : null;

  /// 获取买卖价差
  double? get spread {
    if (bestBid != null && bestAsk != null) {
      return bestAsk! - bestBid!;
    }
    return null;
  }

  /// 获取中间价
  double? get midPrice {
    if (bestBid != null && bestAsk != null) {
      return (bestBid! + bestAsk!) / 2;
    }
    return null;
  }
}

