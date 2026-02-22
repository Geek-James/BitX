import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../features/markets/models/market_ticker.dart';
import '../../features/markets/models/websocket_connection_state.dart';
import '../../features/markets/models/kline_interval.dart';
import '../../features/markets/services/market_data_coordinator.dart';
import 'config.dart';

/// WebSocket 服务
class WebSocketService {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  Timer? _mockDataTimer;
  Timer? _tickersTimer;  // 行情列表定时器
  final _connectionStateController =
      StreamController<WebSocketConnectionState>.broadcast();
  final _tickersController = StreamController<List<MarketTicker>>.broadcast();
  final _klineController = StreamController<Map<String, dynamic>>.broadcast();
  final _orderBookController = StreamController<Map<String, dynamic>>.broadcast();
  final _tradesController = StreamController<Map<String, dynamic>>.broadcast();

  WebSocketConnectionState _connectionState = WebSocketConnectionState(
    status: ConnectionStatus.disconnected,
  );
  
  // 当前订阅的频道
  final Set<String> _subscribedChannels = {};
  
  // 市场数据协调器（确保所有数据关联一致）
  final MarketDataCoordinator _coordinator = MarketDataCoordinator();

  /// 连接状态流
  Stream<WebSocketConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  /// 行情数据流
  Stream<List<MarketTicker>> get tickersStream => _tickersController.stream;
  
  /// K线数据流
  Stream<Map<String, dynamic>> get klineStream => _klineController.stream;
  
  /// 订单薄数据流
  Stream<Map<String, dynamic>> get orderBookStream => _orderBookController.stream;
  
  /// 交易记录数据流
  Stream<Map<String, dynamic>> get tradesStream => _tradesController.stream;

  /// 当前连接状态
  WebSocketConnectionState get connectionState => _connectionState;

  /// WebSocket 端点
  final String wsUrl;

  WebSocketService({
    String? wsUrl,
  }) : wsUrl = wsUrl ?? NetworkConfig.wsUrl;

  /// 连接 WebSocket
  Future<void> connect() async {
    if (_connectionState.status == ConnectionStatus.connecting ||
        _connectionState.status == ConnectionStatus.connected) {
      return;
    }

    _updateConnectionState(
      _connectionState.copyWith(status: ConnectionStatus.connecting),
    );

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // 监听消息
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      // 订阅行情数据
      _subscribe();

      // 启动心跳
      _startHeartbeat();

      _updateConnectionState(
        WebSocketConnectionState(
          status: ConnectionStatus.connected,
          retryCount: 0,
          connectedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      _updateConnectionState(
        _connectionState.copyWith(
          status: ConnectionStatus.error,
          lastError: e.toString(),
        ),
      );
      _scheduleReconnect();
    }
  }

  /// 断开连接
  void disconnect() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _mockDataTimer?.cancel();
    _tickersTimer?.cancel();
    _channel?.sink.close();
    _channel = null;

    _updateConnectionState(
      WebSocketConnectionState(status: ConnectionStatus.disconnected),
    );
  }

  /// 订阅行情数据
  void _subscribe() {
    final message = jsonEncode({
      'action': 'subscribe',
      'channel': 'market.all',
    });
    _channel?.sink.add(message);
    _subscribedChannels.add('market.all');
    // print('📤 Sent subscribe message: $message');
    
    // 启动行情数据模拟生成
    _startMarketTickersGeneration();
  }
  
  /// 订阅K线数据
  void subscribeKline(String symbol, String interval) {
    if (_connectionState.status != ConnectionStatus.connected) {
      return;
    }
    
    final channel = 'kline.$symbol.$interval';
    if (_subscribedChannels.contains(channel)) {
      return;
    }
    
    final message = jsonEncode({
      'action': 'subscribe',
      'channel': channel,
    });
    _channel?.sink.add(message);
    _subscribedChannels.add(channel);
  }
  
  /// 取消订阅K线数据
  void unsubscribeKline(String symbol, String interval) {
    if (_connectionState.status != ConnectionStatus.connected) {
      return;
    }
    
    final channel = 'kline.$symbol.$interval';
    if (!_subscribedChannels.contains(channel)) {
      return;
    }
    
    final message = jsonEncode({
      'action': 'unsubscribe',
      'channel': channel,
    });
    _channel?.sink.add(message);
    _subscribedChannels.remove(channel);
  }
  
  /// 订阅订单薄数据
  void subscribeOrderBook(String symbol) {
    final channel = 'orderbook.$symbol';
    
    // 如果已经订阅，跳过
    if (_subscribedChannels.contains(channel)) {
      return;
    }
    
    _subscribedChannels.add(channel);
    
    // 如果未连接，先连接
    if (_connectionState.status != ConnectionStatus.connected) {
      connect().then((_) {
        _startMockDataGeneration();
      });
      return;
    }
    
    // 启动模拟数据生成
    _startMockDataGeneration();
  }
  
  /// 取消订阅订单薄数据
  void unsubscribeOrderBook(String symbol) {
    if (_connectionState.status != ConnectionStatus.connected) {
      return;
    }
    
    final channel = 'orderbook.$symbol';
    if (!_subscribedChannels.contains(channel)) {
      return;
    }
    
    final message = jsonEncode({
      'action': 'unsubscribe',
      'channel': channel,
    });
    _channel?.sink.add(message);
    _subscribedChannels.remove(channel);
  }
  
  /// 订阅交易记录数据
  void subscribeTrades(String symbol) {
    final channel = 'trades.$symbol';
    
    // 如果已经订阅，跳过
    if (_subscribedChannels.contains(channel)) {
      return;
    }
    
    _subscribedChannels.add(channel);
    
    // 如果未连接，先连接
    if (_connectionState.status != ConnectionStatus.connected) {
      connect().then((_) {
        _startMockDataGeneration();
      });
      return;
    }
    
    // 启动模拟数据生成
    _startMockDataGeneration();
  }
  
  /// 取消订阅交易记录数据
  void unsubscribeTrades(String symbol) {
    if (_connectionState.status != ConnectionStatus.connected) {
      return;
    }
    
    final channel = 'trades.$symbol';
    if (!_subscribedChannels.contains(channel)) {
      return;
    }
    
    final message = jsonEncode({
      'action': 'unsubscribe',
      'channel': channel,
    });
    _channel?.sink.add(message);
    _subscribedChannels.remove(channel);
  }

  /// 启动心跳
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_connectionState.isConnected) {
        final message = jsonEncode({'action': 'ping'});
        _channel?.sink.add(message);
      }
    });
  }

  /// 处理接收到的消息
  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String?;
      final channel = data['channel'] as String?;

      if (type == 'data') {
        if (channel == 'market.all') {
          // 行情数据
          final tickersData = data['data'] as List<dynamic>;
          final tickers = tickersData
              .map((json) => MarketTicker.fromJson(json as Map<String, dynamic>))
              .toList();
          _tickersController.add(tickers);
        } else if (channel != null && channel.startsWith('kline.')) {
          // K线数据
          _klineController.add(data);
        } else if (channel != null && channel.startsWith('orderbook.')) {
          // 订单薄数据
          _orderBookController.add(data);
        } else if (channel != null && channel.startsWith('trades.')) {
          // 交易记录数据
          _tradesController.add(data);
        }
      } else if (type == 'pong') {
        // 心跳响应，无需处理
      }
    } catch (e) {
      // WebSocket message parse error
    }
  }

  /// 处理错误
  void _onError(dynamic error) {
    _updateConnectionState(
      _connectionState.copyWith(
        status: ConnectionStatus.error,
        lastError: error.toString(),
      ),
    );
    _scheduleReconnect();
  }

  /// 处理连接关闭
  void _onDone() {
    if (_connectionState.status != ConnectionStatus.disconnected) {
      _updateConnectionState(
        _connectionState.copyWith(status: ConnectionStatus.disconnected),
      );
      _scheduleReconnect();
    }
  }

  /// 安排重连
  void _scheduleReconnect() {
    _heartbeatTimer?.cancel();
    _channel = null;

    if (!_connectionState.canRetry) {
      _updateConnectionState(
        _connectionState.copyWith(
          status: ConnectionStatus.error,
          lastError: 'Max retry attempts reached',
        ),
      );
      return;
    }

    final delay = _connectionState.getRetryDelay();
    _updateConnectionState(
      _connectionState.copyWith(
        retryCount: _connectionState.retryCount + 1,
      ),
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      connect();
    });
  }

  /// 手动重试连接
  void retry() {
    _reconnectTimer?.cancel();
    _updateConnectionState(
      WebSocketConnectionState(status: ConnectionStatus.disconnected),
    );
    connect();
  }

  /// 更新连接状态
  void _updateConnectionState(WebSocketConnectionState state) {
    _connectionState = state;
    _connectionStateController.add(state);
  }
  
  /// 启动模拟数据生成
  void _startMockDataGeneration() {
    if (_mockDataTimer != null && _mockDataTimer!.isActive) {
      return;
    }
    
    // 详情页数据更新频率：500ms（与行情列表同步）
    _mockDataTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _generateMockData();
    });
  }
  
  /// 生成模拟数据（所有数据关联一致）
  void _generateMockData() {
    // 收集所有需要生成数据的交易对
    final symbols = <String>{};
    
    for (final channel in _subscribedChannels) {
      if (channel.startsWith('orderbook.')) {
        symbols.add(channel.replaceFirst('orderbook.', ''));
      } else if (channel.startsWith('trades.')) {
        symbols.add(channel.replaceFirst('trades.', ''));
      } else if (channel.startsWith('kline.')) {
        final parts = channel.split('.');
        if (parts.length >= 2) {
          symbols.add(parts[1]);
        }
      }
    }
    
    // 为每个交易对生成关联的数据
    for (final symbol in symbols) {
      _generateCoordinatedData(symbol);
    }
  }
  
  /// 生成关联的数据（确保价格一致性）
  void _generateCoordinatedData(String symbol) {
    try {
      // 1. 生成交易记录（这会更新价格）
      if (_subscribedChannels.contains('trades.$symbol')) {
        final trade = _coordinator.generateTrade(symbol);
        final data = {
          'type': 'data',
          'channel': 'trades.$symbol',
          'data': trade.toJson(),
        };
        _tradesController.add(data);
        // print('💰 Generated trade for $symbol: ${trade.isBuy ? "BUY" : "SELL"} ${trade.amount.toStringAsFixed(4)} @ ${trade.price.toStringAsFixed(2)}');
      }
      
      // 2. 生成订单薄（基于最新价格）
      if (_subscribedChannels.contains('orderbook.$symbol')) {
        final orderBook = _coordinator.generateOrderBook(symbol);
        final data = {
          'type': 'data',
          'channel': 'orderbook.$symbol',
          'data': orderBook.toJson(),
        };
        _orderBookController.add(data);
      }
      
      // 3. 生成K线数据（基于最新价格）
      for (final channel in _subscribedChannels) {
        if (channel.startsWith('kline.$symbol.')) {
          final parts = channel.split('.');
          if (parts.length >= 3) {
            final intervalValue = parts[2];
            final interval = _parseInterval(intervalValue);
            if (interval != null) {
              final kline = _coordinator.generateKlineUpdate(symbol, interval);
              final data = {
                'type': 'data',
                'channel': channel,
                'data': {
                  'symbol': symbol,
                  'timestamp': kline.timestamp.toIso8601String(),
                  'open': kline.open,
                  'high': kline.high,
                  'low': kline.low,
                  'close': kline.close,
                  'volume': kline.volume,
                },
              };
              _klineController.add(data);
            }
          }
        }
      }
    } catch (e) {
      // Error generating coordinated data
    }
  }
  
  /// 解析时间周期
  KlineInterval? _parseInterval(String value) {
    switch (value) {
      case '1m':
        return KlineInterval.min1;
      case '5m':
        return KlineInterval.min5;
      case '15m':
        return KlineInterval.min15;
      case '30m':
        return KlineInterval.min30;
      case '1h':
        return KlineInterval.hour1;
      case '4h':
        return KlineInterval.hour4;
      case '1d':
        return KlineInterval.day1;
      case '1w':
        return KlineInterval.week1;
      default:
        return null;
    }
  }
  
  /// 获取市场数据协调器（用于生成历史数据）
  MarketDataCoordinator get coordinator => _coordinator;
  
  /// 启动行情列表数据生成
  void _startMarketTickersGeneration() {
    // 如果定时器已经在运行，先取消
    if (_tickersTimer != null && _tickersTimer!.isActive) {
      return;
    }
    
    // 生成初始行情列表
    Timer(const Duration(milliseconds: 500), () {
      _generateMarketTickers();
    });
    
    // 定期更新行情列表（每1秒）
    _tickersTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_connectionState.isConnected && _subscribedChannels.contains('market.all')) {
        _generateMarketTickers();
      }
    });
  }
  
  /// 生成行情列表数据（500条）
  void _generateMarketTickers() {
    try {
      final symbols = _generate500Symbols();
      
      final tickers = symbols.map((symbol) {
        return _coordinator.generateTicker(symbol);
      }).toList();
      
      _tickersController.add(tickers);
    } catch (e) {
      // Error generating market tickers
    }
  }
  
  /// 生成500个交易对
  List<String> _generate500Symbols() {
    final symbols = <String>[];
    
    // 主流币种（永续合约）- 50个
    final mainCoins = [
      'BTC', 'ETH', 'BNB', 'SOL', 'XRP', 'ADA', 'DOGE', 'MATIC', 'DOT', 'AVAX',
      'LINK', 'UNI', 'ATOM', 'LTC', 'ETC', 'BCH', 'XLM', 'ALGO', 'VET', 'ICP',
      'FIL', 'TRX', 'APT', 'ARB', 'OP', 'NEAR', 'AAVE', 'GRT', 'SNX', 'MKR',
      'COMP', 'SUSHI', 'YFI', 'CRV', 'BAL', 'REN', 'ZRX', 'KNC', 'LRC', 'ENJ',
      'MANA', 'SAND', 'AXS', 'GALA', 'CHZ', 'FTM', 'ONE', 'HBAR', 'EGLD', 'THETA',
    ];
    
    // 添加永续合约（250个）
    for (final coin in mainCoins) {
      symbols.add('${coin}USDT');
    }
    
    // 生成更多永续合约（200个）
    for (int i = 1; i <= 200; i++) {
      symbols.add('TOKEN${i}USDT');
    }
    
    // 添加现货交易对（250个）
    for (final coin in mainCoins) {
      symbols.add('$coin/USDT');
    }
    
    // 生成更多现货交易对（200个）
    for (int i = 1; i <= 200; i++) {
      symbols.add('TOKEN$i/USDT');
    }
    
    return symbols;
  }

  /// 释放资源
  void dispose() {
    disconnect();
    _connectionStateController.close();
    _tickersController.close();
    _klineController.close();
    _orderBookController.close();
    _tradesController.close();
  }
}

