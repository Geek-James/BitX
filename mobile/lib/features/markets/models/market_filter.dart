import 'market_ticker.dart';

/// 排序类型枚举
enum SortType {
  default_,
  topGainers,
  topLosers,
  volume,
}

/// 市场类型枚举
enum MarketType {
  futures,
  spot,
}

/// 行情筛选条件模型
class MarketFilter {
  final String searchQuery;
  final SortType sortBy;
  final MarketType marketType;

  MarketFilter({
    this.searchQuery = '',
    this.sortBy = SortType.default_,
    this.marketType = MarketType.futures,
  });

  MarketFilter copyWith({
    String? searchQuery,
    SortType? sortBy,
    MarketType? marketType,
  }) {
    return MarketFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      marketType: marketType ?? this.marketType,
    );
  }

  /// 判断是否有搜索条件
  bool get hasSearch => searchQuery.isNotEmpty;

  /// 应用筛选和排序
  List<MarketTicker> apply(List<MarketTicker> tickers) {
    var result = tickers;

    // 应用搜索
    if (hasSearch) {
      result = result.where((ticker) {
        return ticker.symbol.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    // 应用排序
    switch (sortBy) {
      case SortType.topGainers:
        result.sort((a, b) => b.change24h.compareTo(a.change24h));
        break;
      case SortType.topLosers:
        result.sort((a, b) => a.change24h.compareTo(b.change24h));
        break;
      case SortType.volume:
        result.sort((a, b) => b.volume24h.compareTo(a.volume24h));
        break;
      case SortType.default_:
        result.sort((a, b) => a.symbol.compareTo(b.symbol));
        break;
    }

    return result;
  }
}

