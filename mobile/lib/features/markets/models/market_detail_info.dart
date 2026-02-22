/// 市场详情信息模型
class MarketDetailInfo {
  final String symbol;
  final String baseCurrency;
  final String quoteCurrency;
  final double minOrderSize;
  final int priceScale;
  final int quantityScale;
  final String? description;
  final String? website;
  final String? whitepaper;
  final String? blockExplorer;

  MarketDetailInfo({
    required this.symbol,
    required this.baseCurrency,
    required this.quoteCurrency,
    required this.minOrderSize,
    required this.priceScale,
    required this.quantityScale,
    this.description,
    this.website,
    this.whitepaper,
    this.blockExplorer,
  });

  /// 从 JSON 解析
  factory MarketDetailInfo.fromJson(Map<String, dynamic> json) {
    return MarketDetailInfo(
      symbol: json['symbol'] as String,
      baseCurrency: json['baseCurrency'] as String,
      quoteCurrency: json['quoteCurrency'] as String,
      minOrderSize: double.parse(json['minOrderSize'].toString()),
      priceScale: json['priceScale'] as int,
      quantityScale: json['quantityScale'] as int,
      description: json['description'] as String?,
      website: json['website'] as String?,
      whitepaper: json['whitepaper'] as String?,
      blockExplorer: json['blockExplorer'] as String?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'baseCurrency': baseCurrency,
      'quoteCurrency': quoteCurrency,
      'minOrderSize': minOrderSize.toString(),
      'priceScale': priceScale,
      'quantityScale': quantityScale,
      if (description != null) 'description': description,
      if (website != null) 'website': website,
      if (whitepaper != null) 'whitepaper': whitepaper,
      if (blockExplorer != null) 'blockExplorer': blockExplorer,
    };
  }
}

