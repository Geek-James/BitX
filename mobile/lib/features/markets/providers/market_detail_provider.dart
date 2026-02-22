import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/kline_interval.dart';
import '../models/kline_data.dart';
import '../../../shared/network/websocket_service.dart';

/// WebSocket 服务实例
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// 当前选中的交易对
final selectedSymbolProvider = StateProvider<String?>((ref) => null);

/// 当前选中的时间周期
final selectedIntervalProvider = StateProvider<KlineInterval>(
  (ref) => KlineInterval.min15,
);

/// K线订阅管理器
class KlineSubscriptionManager extends StateNotifier<Map<String, StreamSubscription>> {
  final WebSocketService _wsService;
  
  KlineSubscriptionManager(this._wsService) : super({});
  
  /// 订阅K线数据
  void subscribe(String symbol, KlineInterval interval) {
    final key = '${symbol}_${interval.value}';
    
    // 如果已经订阅，先取消
    if (state.containsKey(key)) {
      unsubscribe(symbol, interval);
    }
    
    // 订阅WebSocket频道
    _wsService.subscribeKline(symbol, interval.value);
  }
  
  /// 取消订阅
  void unsubscribe(String symbol, KlineInterval interval) {
    final key = '${symbol}_${interval.value}';
    
    // 取消WebSocket订阅
    _wsService.unsubscribeKline(symbol, interval.value);
    
    // 取消流订阅
    state[key]?.cancel();
    state = Map.from(state)..remove(key);
  }
  
  /// 取消所有订阅
  void unsubscribeAll() {
    for (final subscription in state.values) {
      subscription.cancel();
    }
    state = {};
  }
  
  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }
}

/// K线订阅管理器Provider
final klineSubscriptionManagerProvider = 
    StateNotifierProvider<KlineSubscriptionManager, Map<String, StreamSubscription>>((ref) {
  final wsService = ref.watch(webSocketServiceProvider);
  return KlineSubscriptionManager(wsService);
});

/// K线数据状态
class KlineDataState {
  final List<KlineData> data;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdate;
  
  const KlineDataState({
    required this.data,
    this.isLoading = false,
    this.error,
    this.lastUpdate,
  });
  
  KlineDataState copyWith({
    List<KlineData>? data,
    bool? isLoading,
    String? error,
    DateTime? lastUpdate,
  }) {
    return KlineDataState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

/// K线数据管理器
class KlineDataNotifier extends StateNotifier<KlineDataState> {
  final String symbol;
  final KlineInterval interval;
  final WebSocketService wsService;
  StreamSubscription? _klineSubscription;
  Timer? _debounceTimer;
  
  KlineDataNotifier({
    required this.symbol,
    required this.interval,
    required this.wsService,
  }) : super(const KlineDataState(data: [], isLoading: true)) {
    _initialize();
  }
  
  /// 初始化
  Future<void> _initialize() async {
    // 1. 加载历史数据
    await _loadHistoricalData();
    
    // 2. 订阅实时更新
    _subscribeToRealtime();
  }
  
  /// 加载历史数据
  Future<void> _loadHistoricalData() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // 模拟网络延迟
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 使用协调器生成关联的历史K线数据
      final data = wsService.coordinator.generateHistoricalKlines(
        symbol, 
        interval,
        count: 200,
      );
      
      state = KlineDataState(
        data: data,
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
    // 订阅WebSocket K线数据流
    _klineSubscription = wsService.klineStream.listen((data) {
      final channel = data['channel'] as String?;
      final expectedChannel = 'kline.$symbol.${interval.value}';
      
      if (channel == expectedChannel) {
        _handleRealtimeUpdate(data);
      }
    });
    
    // 订阅WebSocket频道
    wsService.subscribeKline(symbol, interval.value);
  }
  
  /// 处理实时更新（带防抖）
  void _handleRealtimeUpdate(Map<String, dynamic> data) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      _updateKlineData(data);
    });
  }
  
  /// 更新K线数据
  void _updateKlineData(Map<String, dynamic> data) {
    try {
      final klineData = data['data'] as Map<String, dynamic>;
      final newKline = KlineData(
        timestamp: DateTime.parse(klineData['timestamp'] as String),
        open: (klineData['open'] as num).toDouble(),
        high: (klineData['high'] as num).toDouble(),
        low: (klineData['low'] as num).toDouble(),
        close: (klineData['close'] as num).toDouble(),
        volume: (klineData['volume'] as num).toDouble(),
      );
      
      final currentData = List<KlineData>.from(state.data);
      
      if (currentData.isEmpty) {
        currentData.add(newKline);
      } else {
        final lastKline = currentData.last;
        
        // 判断是更新最后一根K线还是添加新K线
        if (_isSameCandle(lastKline.timestamp, newKline.timestamp)) {
          // 更新最后一根K线
          currentData[currentData.length - 1] = newKline;
        } else {
          // 添加新K线
          currentData.add(newKline);
          
          // 保持数据量在合理范围内
          if (currentData.length > 300) {
            currentData.removeAt(0);
          }
        }
      }
      
      state = KlineDataState(
        data: currentData,
        isLoading: false,
        lastUpdate: DateTime.now(),
      );
    } catch (e) {
      // Error updating K-line data
    }
  }
  
  /// 判断两个时间戳是否属于同一根K线
  bool _isSameCandle(DateTime time1, DateTime time2) {
    final intervalMinutes = _getIntervalMinutes(interval);
    final candle1 = time1.millisecondsSinceEpoch ~/ (intervalMinutes * 60 * 1000);
    final candle2 = time2.millisecondsSinceEpoch ~/ (intervalMinutes * 60 * 1000);
    return candle1 == candle2;
  }
  
  /// 获取时间周期对应的分钟数
  int _getIntervalMinutes(KlineInterval interval) {
    switch (interval) {
      case KlineInterval.timeline:
        return 1; // 分时图使用1分钟间隔
      case KlineInterval.min1:
        return 1;
      case KlineInterval.min5:
        return 5;
      case KlineInterval.min15:
        return 15;
      case KlineInterval.min30:
        return 30;
      case KlineInterval.hour1:
        return 60;
      case KlineInterval.hour4:
        return 240;
      case KlineInterval.day1:
        return 1440;
      case KlineInterval.week1:
        return 10080;
    }
  }
  

  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    _klineSubscription?.cancel();
    wsService.unsubscribeKline(symbol, interval.value);
    super.dispose();
  }
}

/// K线数据Provider（支持实时更新）
final klineDataProvider = StateNotifierProvider.family<KlineDataNotifier, KlineDataState, (String, KlineInterval)>(
  (ref, params) {
    final (symbol, interval) = params;
    final wsService = ref.watch(webSocketServiceProvider);
    
    return KlineDataNotifier(
      symbol: symbol,
      interval: interval,
      wsService: wsService,
    );
  },
);

/// 便捷访问K线数据列表
final klineDataListProvider = Provider.family<List<KlineData>, (String, KlineInterval)>(
  (ref, params) {
    final state = ref.watch(klineDataProvider(params));
    return state.data;
  },
);
