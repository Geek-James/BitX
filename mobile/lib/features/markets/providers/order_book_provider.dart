import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/order_book.dart';
import '../../../shared/network/websocket_service.dart';
import 'market_detail_provider.dart';

/// 订单薄数据状态
class OrderBookState {
  final OrderBook? orderBook;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdate;

  const OrderBookState({
    this.orderBook,
    this.isLoading = false,
    this.error,
    this.lastUpdate,
  });

  OrderBookState copyWith({
    OrderBook? orderBook,
    bool? isLoading,
    String? error,
    DateTime? lastUpdate,
  }) {
    return OrderBookState(
      orderBook: orderBook ?? this.orderBook,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

/// 订单薄数据管理器
class OrderBookNotifier extends StateNotifier<OrderBookState> {
  final String symbol;
  final WebSocketService wsService;
  StreamSubscription? _subscription;
  Timer? _debounceTimer;

  OrderBookNotifier({
    required this.symbol,
    required this.wsService,
  }) : super(const OrderBookState(isLoading: true)) {
    _initialize();
  }

  /// 初始化
  Future<void> _initialize() async {
    // 1. 加载初始数据
    await _loadInitialData();

    // 2. 订阅实时更新
    _subscribeToRealtime();
  }

  /// 加载初始数据
  Future<void> _loadInitialData() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // 模拟网络延迟
      await Future.delayed(const Duration(milliseconds: 300));

      // 使用协调器生成关联的订单薄数据
      final orderBook = wsService.coordinator.generateOrderBook(symbol);

      state = OrderBookState(
        orderBook: orderBook,
        isLoading: false,
        lastUpdate: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 订阅实时更新
  void _subscribeToRealtime() {
    // 订阅WebSocket订单薄数据流
    _subscription = wsService.orderBookStream.listen((data) {
      final channel = data['channel'] as String?;
      final expectedChannel = 'orderbook.$symbol';

      if (channel == expectedChannel) {
        _handleRealtimeUpdate(data);
      }
    });

    // 订阅WebSocket频道
    wsService.subscribeOrderBook(symbol);
  }

  /// 处理实时更新（带防抖）
  void _handleRealtimeUpdate(Map<String, dynamic> data) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 50), () {
      _updateOrderBook(data);
    });
  }

  /// 更新订单薄数据
  void _updateOrderBook(Map<String, dynamic> data) {
    try {
      final orderBookData = data['data'] as Map<String, dynamic>;
      final newOrderBook = OrderBook.fromJson(orderBookData);

      state = OrderBookState(
        orderBook: newOrderBook,
        isLoading: false,
        lastUpdate: DateTime.now(),
      );
    } catch (e) {
      // Failed to update order book
    }
  }



  @override
  void dispose() {
    _debounceTimer?.cancel();
    _subscription?.cancel();
    wsService.unsubscribeOrderBook(symbol);
    super.dispose();
  }
}

/// 订单薄数据Provider
final orderBookProvider = StateNotifierProvider.family<OrderBookNotifier, OrderBookState, String>(
  (ref, symbol) {
    final wsService = ref.watch(webSocketServiceProvider);
    return OrderBookNotifier(
      symbol: symbol,
      wsService: wsService,
    );
  },
);

/// 便捷访问订单薄
final orderBookDataProvider = Provider.family<OrderBook?, String>(
  (ref, symbol) {
    final state = ref.watch(orderBookProvider(symbol));
    return state.orderBook;
  },
);

