import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../shared/network/websocket_service.dart';
import 'markets_provider.dart';

/// 实时价格状态
class RealtimePrice {
  final String symbol;
  final double price;
  final double change24h;
  final double high24h;
  final double low24h;
  final double volume24h;
  final DateTime timestamp;

  const RealtimePrice({
    required this.symbol,
    required this.price,
    required this.change24h,
    required this.high24h,
    required this.low24h,
    required this.volume24h,
    required this.timestamp,
  });

  RealtimePrice copyWith({
    String? symbol,
    double? price,
    double? change24h,
    double? high24h,
    double? low24h,
    double? volume24h,
    DateTime? timestamp,
  }) {
    return RealtimePrice(
      symbol: symbol ?? this.symbol,
      price: price ?? this.price,
      change24h: change24h ?? this.change24h,
      high24h: high24h ?? this.high24h,
      low24h: low24h ?? this.low24h,
      volume24h: volume24h ?? this.volume24h,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  bool get isPositive => change24h >= 0;

  String get formattedChange {
    final sign = isPositive ? '+' : '';
    return '$sign${change24h.toStringAsFixed(2)}%';
  }

  String formatPrice() {
    if (price >= 1000) {
      return price.toStringAsFixed(2);
    } else if (price >= 1) {
      return price.toStringAsFixed(4);
    } else {
      return price.toStringAsFixed(6);
    }
  }

  String formatVolume() {
    if (volume24h >= 1000000000) {
      return '${(volume24h / 1000000000).toStringAsFixed(2)}B';
    } else if (volume24h >= 1000000) {
      return '${(volume24h / 1000000).toStringAsFixed(2)}M';
    } else if (volume24h >= 1000) {
      return '${(volume24h / 1000).toStringAsFixed(2)}K';
    } else {
      return volume24h.toStringAsFixed(2);
    }
  }
}

/// 实时价格管理器
class RealtimePriceNotifier extends StateNotifier<RealtimePrice?> {
  final String symbol;
  final WebSocketService wsService;
  Timer? _updateTimer;
  StreamSubscription? _tradesSubscription;

  RealtimePriceNotifier({
    required this.symbol,
    required this.wsService,
  }) : super(null) {
    _initialize();
  }

  /// 初始化
  void _initialize() {
    // 1. 从协调器获取初始价格
    _updateFromCoordinator();

    // 2. 订阅成交流，实时更新价格
    _subscribeToTrades();

    // 3. 定时从协调器同步价格（每500ms）
    _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _updateFromCoordinator();
    });
  }

  /// 从协调器更新价格
  void _updateFromCoordinator() {
    try {
      final coordinator = wsService.coordinator;
      final ticker = coordinator.generateTicker(symbol);

      state = RealtimePrice(
        symbol: symbol,
        price: ticker.price,
        change24h: ticker.change24h,
        high24h: ticker.high24h,
        low24h: ticker.low24h,
        volume24h: ticker.volume24h,
        timestamp: ticker.timestamp,
      );
    } catch (e) {
      // Error updating price from coordinator
    }
  }

  /// 订阅成交流
  void _subscribeToTrades() {
    try {
      _tradesSubscription = wsService.tradesStream.listen((data) {
        try {
          final channel = data['channel'] as String?;
          final expectedChannel = 'trades.$symbol';

          if (channel == expectedChannel) {
            final tradeData = data['data'] as Map<String, dynamic>;
            final price = (tradeData['price'] as num).toDouble();

            // 立即更新价格
            if (state != null) {
              state = state!.copyWith(
                price: price,
                timestamp: DateTime.now(),
              );
            }
          }
        } catch (e) {
          // Error processing trade for price update
        }
      });

      // 订阅成交频道
      wsService.subscribeTrades(symbol);
    } catch (e) {
      // Error subscribing to trades for price
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _tradesSubscription?.cancel();
    wsService.unsubscribeTrades(symbol);
    super.dispose();
  }
}

/// 实时价格Provider
final realtimePriceProvider = StateNotifierProvider.family<
    RealtimePriceNotifier, RealtimePrice?, String>((ref, symbol) {
  final wsService = ref.watch(webSocketServiceProvider);
  return RealtimePriceNotifier(
    symbol: symbol,
    wsService: wsService,
  );
});

