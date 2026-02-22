import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/network/websocket_service.dart';
import '../models/market_ticker.dart';
import '../models/market_filter.dart';
import '../models/websocket_connection_state.dart';

/// WebSocket 服务提供者
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// WebSocket 连接状态提供者
final connectionStateProvider =
    StreamProvider<WebSocketConnectionState>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.connectionStateStream;
});

/// 原始行情数据流提供者
final rawTickersProvider = StreamProvider<List<MarketTicker>>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.tickersStream;
});

/// 市场筛选条件提供者
final marketFilterProvider =
    StateNotifierProvider<MarketFilterNotifier, MarketFilter>((ref) {
  return MarketFilterNotifier();
});

/// 市场筛选条件状态管理
class MarketFilterNotifier extends StateNotifier<MarketFilter> {
  MarketFilterNotifier() : super(MarketFilter());

  /// 更新搜索关键词
  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// 更新排序方式
  void updateSortBy(SortType sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  /// 更新市场类型
  void updateMarketType(MarketType marketType) {
    state = state.copyWith(marketType: marketType);
  }

  /// 清空搜索
  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }

  /// 重置筛选条件
  void reset() {
    state = MarketFilter();
  }
}

/// 过滤后的行情数据提供者
final filteredTickersProvider = Provider<AsyncValue<List<MarketTicker>>>((ref) {
  final rawTickers = ref.watch(rawTickersProvider);
  final filter = ref.watch(marketFilterProvider);

  return rawTickers.when(
    data: (tickers) {
      // 根据市场类型过滤
      // 永续合约: 以 USDT 结尾 (例如: BTCUSDT)
      // 现货: 包含 / 符号 (例如: BTC/USDT)
      final filteredByType = tickers.where((ticker) {
        if (filter.marketType == MarketType.futures) {
          return ticker.symbol.endsWith('USDT') && !ticker.symbol.contains('/');
        } else {
          return ticker.symbol.contains('/');
        }
      }).toList();

      // 应用搜索和排序
      final result = filter.apply(filteredByType);
      return AsyncValue.data(result);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

