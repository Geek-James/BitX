/// 订单薄条目模型
class OrderBookEntry {
  final double price;
  final double amount;
  final double total;

  OrderBookEntry({
    required this.price,
    required this.amount,
    required this.total,
  });

  factory OrderBookEntry.fromJson(Map<String, dynamic> json) {
    return OrderBookEntry(
      price: double.parse(json['price'].toString()),
      amount: double.parse(json['amount'].toString()),
      total: double.parse(json['total'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'price': price,
      'amount': amount,
      'total': total,
    };
  }

  OrderBookEntry copyWith({
    double? price,
    double? amount,
    double? total,
  }) {
    return OrderBookEntry(
      price: price ?? this.price,
      amount: amount ?? this.amount,
      total: total ?? this.total,
    );
  }
}

