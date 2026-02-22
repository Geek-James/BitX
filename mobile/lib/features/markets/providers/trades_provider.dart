import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/trade.dart';
import '../../../shared/network/websocket_service.dart';
import 'market_detail_provider.dart';

/// 交易记录数据状态
class TradesState {
  final List<Trade> trades;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdate;

  const TradesState({
    required this.trades,
    this.isLoading = false,
    this.error,
    this.lastUpdate,
  });

  TradesState copyWith({
    List<Trade>? trades,
    bool? isLoading,
    String? error,
    DateTime? lastUpdate,
  }) {
    return TradesState(
      trades: trades ?? this.trades,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

/// 交易记录管理器
class TradesNotifier extends StateNotifier<TradesState> {
  final String symbol;
  final WebSocketService wsService;
  StreamSubscription? _subscription;
  Timer? _debounceTimer;
  static const int maxTrades = 100; // 最多保留100条记录

  TradesNotifier({
    required this.symbol,
    required this.wsService,
  }) : super(const TradesState(trades: [], isLoading: true)) {
    _initialize();
  }

  /// 初始化
  Future<void> _initialize() async {
    // 1. 加载历史交易记录
    await _loadHistoricalTrades();

    // 2. 订阅实时更新
    _subscribeToRealtime();
  }

  /// 加载历史交易记录
  Future<void> _loadHistoricalTrades() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // 模拟网络延迟
      await Future.delayed(const Duration(milliseconds: 300));

      // 使用协调器生成关联的历史交易记录
      final trades = <Trade>[];
      final now = DateTime.now();
      
      // 生成50条历史交易
      for (int i = 0; i < 50; i++) {
        final trade = wsService.coordinator.generateTrade(symbol);
        // 调整时间戳为历史时间
        final historicalTrade = trade.copyWith(
          timestamp: now.subtract(Duration(seconds: i * 2)),
        );
        trades.add(historicalTrade);
      }

      state = TradesState(
        trades: trades,
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
    // 订阅WebSocket交易数据流
    _subscription = wsService.tradesStream.listen((data) {
      final channel = data['channel'] as String?;
      final expectedChannel = 'trades.$symbol';

      if (channel == expectedChannel) {
        _handleRealtimeUpdate(data);
      }
    });

    // 订阅WebSocket频道
    wsService.subscribeTrades(symbol);
  }

  /// 处理实时更新（带防抖）
  void _handleRealtimeUpdate(Map<String, dynamic> data) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 50), () {
      _addNewTrade(data);
    });
  }

  /// 添加新交易记录
  void _addNewTrade(Map<String, dynamic> data) {
    try {
      final tradeData = data['data'] as Map<String, dynamic>;
      final newTrade = Trade.fromJson(tradeData);

      final currentTrades = List<Trade>.from(state.trades);
      
      // 添加到列表开头（最新的在前面）
      currentTrades.insert(0, newTrade);

      // 保持列表长度在限制内
      if (currentTrades.length > maxTrades) {
        currentTrades.removeRange(maxTrades, currentTrades.length);
      }

      state = TradesState(
        trades: currentTrades,
        isLoading: false,
        lastUpdate: DateTime.now(),
      );
    } catch (e) {
      // Failed to add new trade
    }
  }



  @override
  void dispose() {
    _debounceTimer?.cancel();
    _subscription?.cancel();
    wsService.unsubscribeTrades(symbol);
    super.dispose();
  }
}

/// 交易记录Provider
final tradesProvider = StateNotifierProvider.family<TradesNotifier, TradesState, String>(
  (ref, symbol) {
    final wsService = ref.watch(webSocketServiceProvider);
    return TradesNotifier(
      symbol: symbol,
      wsService: wsService,
    );
  },
);

/// 便捷访问交易记录列表
final tradesListProvider = Provider.family<List<Trade>, String>(
  (ref, symbol) {
    final state = ref.watch(tradesProvider(symbol));
    return state.trades;
  },
);

