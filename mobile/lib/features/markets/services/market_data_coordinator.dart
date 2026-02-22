import 'dart:math';
import '../models/kline_data.dart';
import '../models/order_book.dart';
import '../models/order_book_entry.dart';
import '../models/trade.dart';
import '../models/market_ticker.dart';
import '../models/kline_interval.dart';

/// 市场数据协调器 - 确保所有数据关联一致
/// 
/// 核心思想：
/// 1. 维护一个统一的价格源（最新成交价）
/// 2. 所有数据（K线、订单薄、成交记录）都基于这个价格生成
/// 3. 价格变化有连续性，模拟真实市场波动
class MarketDataCoordinator {
  final Random _random = Random();
  
  // 每个交易对的价格状态
  final Map<String, _PriceState> _priceStates = {};
  
  // 每个交易对的K线缓存
  final Map<String, Map<KlineInterval, List<KlineData>>> _klineCache = {};
  
  /// 获取或创建价格状态
  _PriceState _getPriceState(String symbol) {
    if (!_priceStates.containsKey(symbol)) {
      // 检查是否有相同币种的其他格式（例如 BTCUSDT 和 BTC/USDT）
      final alternativeSymbol = symbol.contains('/') 
          ? symbol.replaceAll('/', '')
          : _insertSlash(symbol);
      
      // 如果存在相同币种的其他格式，使用相同的价格
      if (_priceStates.containsKey(alternativeSymbol)) {
        final existingState = _priceStates[alternativeSymbol]!;
        _priceStates[symbol] = _PriceState(
          symbol: symbol,
          currentPrice: existingState.currentPrice,
          lastUpdateTime: DateTime.now(),
        );
        // print('🔗 Linked $symbol to $alternativeSymbol (price: ${existingState.currentPrice.toStringAsFixed(2)})');
      } else {
        _priceStates[symbol] = _PriceState(
          symbol: symbol,
          currentPrice: _generateInitialPrice(symbol),
          lastUpdateTime: DateTime.now(),
        );
        // print('🆕 Created new price state for $symbol (price: ${_priceStates[symbol]!.currentPrice.toStringAsFixed(2)})');
      }
    }
    return _priceStates[symbol]!;
  }
  
  /// 在USDT前插入斜杠（例如：BTCUSDT -> BTC/USDT）
  String _insertSlash(String symbol) {
    if (symbol.endsWith('USDT')) {
      final base = symbol.substring(0, symbol.length - 4);
      return '$base/USDT';
    }
    return symbol;
  }
  
  /// 生成初始价格（基于交易对名称）
  double _generateInitialPrice(String symbol) {
    // 移除 / 符号，统一处理
    final cleanSymbol = symbol.replaceAll('/', '');
    
    // 根据交易对生成合理的初始价格
    if (cleanSymbol.contains('BTC')) {
      return 40000 + _random.nextDouble() * 30000; // BTC: 40k-70k
    } else if (cleanSymbol.contains('ETH')) {
      return 2000 + _random.nextDouble() * 2000; // ETH: 2k-4k
    } else if (cleanSymbol.contains('BNB')) {
      return 300 + _random.nextDouble() * 200; // BNB: 300-500
    } else if (cleanSymbol.contains('SOL')) {
      return 50 + _random.nextDouble() * 150; // SOL: 50-200
    } else if (cleanSymbol.contains('XRP')) {
      return 0.3 + _random.nextDouble() * 0.7; // XRP: 0.3-1.0
    } else if (cleanSymbol.contains('ADA')) {
      return 0.2 + _random.nextDouble() * 0.8; // ADA: 0.2-1.0
    } else if (cleanSymbol.contains('DOGE')) {
      return 0.05 + _random.nextDouble() * 0.15; // DOGE: 0.05-0.2
    } else if (cleanSymbol.contains('MATIC')) {
      return 0.5 + _random.nextDouble() * 1.5; // MATIC: 0.5-2.0
    } else if (cleanSymbol.contains('DOT')) {
      return 4 + _random.nextDouble() * 6; // DOT: 4-10
    } else if (cleanSymbol.contains('AVAX')) {
      return 10 + _random.nextDouble() * 30; // AVAX: 10-40
    } else if (cleanSymbol.contains('LINK')) {
      return 5 + _random.nextDouble() * 15; // LINK: 5-20
    } else if (cleanSymbol.contains('UNI')) {
      return 4 + _random.nextDouble() * 8; // UNI: 4-12
    } else if (cleanSymbol.contains('ATOM')) {
      return 6 + _random.nextDouble() * 12; // ATOM: 6-18
    } else if (cleanSymbol.contains('LTC')) {
      return 50 + _random.nextDouble() * 100; // LTC: 50-150
    } else if (cleanSymbol.contains('ETC')) {
      return 15 + _random.nextDouble() * 25; // ETC: 15-40
    } else if (cleanSymbol.startsWith('TOKEN')) {
      // TOKEN1-TOKEN200: 随机价格
      final tokenNum = int.tryParse(cleanSymbol.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
      final seed = tokenNum % 10;
      
      if (seed < 3) {
        return 0.01 + _random.nextDouble() * 0.99; // 小币: 0.01-1
      } else if (seed < 6) {
        return 1 + _random.nextDouble() * 9; // 中币: 1-10
      } else if (seed < 9) {
        return 10 + _random.nextDouble() * 90; // 大币: 10-100
      } else {
        return 100 + _random.nextDouble() * 900; // 超大币: 100-1000
      }
    } else {
      // 其他币种: 随机价格
      return 1 + _random.nextDouble() * 99; // 1-100
    }
  }
  
  /// 更新价格（模拟市场波动）
  double updatePrice(String symbol) {
    final state = _getPriceState(symbol);
    final now = DateTime.now();
    final timeDiff = now.difference(state.lastUpdateTime).inMilliseconds;
    
    // 价格波动幅度（基于时间间隔）
    final volatility = 0.0005; // 0.05%的基础波动
    final timeMultiplier = min(timeDiff / 1000.0, 5.0); // 最多5倍
    
    // 添加趋势性（让价格有方向性）
    state.trendCounter++;
    if (state.trendCounter > 10) {
      state.trendDirection = _random.nextBool() ? 1 : -1;
      state.trendCounter = 0;
    }
    
    // 计算价格变化
    final randomChange = (_random.nextDouble() - 0.5) * 2; // -1 到 1
    final trendInfluence = state.trendDirection * 0.3; // 趋势影响
    final priceChange = state.currentPrice * volatility * timeMultiplier * 
                       (randomChange + trendInfluence);
    
    // 更新价格
    state.currentPrice += priceChange;
    state.lastUpdateTime = now;
    state.priceHistory.add(state.currentPrice);
    
    // 保持历史记录在合理范围
    if (state.priceHistory.length > 1000) {
      state.priceHistory.removeAt(0);
    }
    
    // 同步相同币种的其他格式价格
    _syncAlternativeSymbol(symbol, state.currentPrice);
    
    return state.currentPrice;
  }
  
  /// 同步相同币种的其他格式价格（永续合约 <-> 现货）
  void _syncAlternativeSymbol(String symbol, double price) {
    final alternativeSymbol = symbol.contains('/') 
        ? symbol.replaceAll('/', '')
        : _insertSlash(symbol);
    
    // 如果存在相同币种的其他格式，同步价格
    if (_priceStates.containsKey(alternativeSymbol)) {
      final altState = _priceStates[alternativeSymbol]!;
      altState.currentPrice = price;
      altState.lastUpdateTime = DateTime.now();
      altState.priceHistory.add(price);
      
      // 保持历史记录在合理范围
      if (altState.priceHistory.length > 1000) {
        altState.priceHistory.removeAt(0);
      }
    }
  }
  
  /// 获取当前价格
  double getCurrentPrice(String symbol) {
    return _getPriceState(symbol).currentPrice;
  }
  
  /// 生成关联的交易记录
  Trade generateTrade(String symbol) {
    final state = _getPriceState(symbol);
    
    // 获取当前价格，但不更新（避免价格跳变太大）
    final currentPrice = state.currentPrice;
    
    // 在当前价格附近小幅波动（±0.02%）
    final priceVariation = currentPrice * 0.0002;
    final price = currentPrice + (_random.nextDouble() - 0.5) * 2 * priceVariation;
    
    // 更新价格状态（使用小幅波动后的价格）
    state.currentPrice = price;
    state.lastUpdateTime = DateTime.now();
    state.priceHistory.add(price);
    
    // 保持历史记录在合理范围
    if (state.priceHistory.length > 1000) {
      state.priceHistory.removeAt(0);
    }
    
    // 同步相同币种的其他格式价格
    _syncAlternativeSymbol(symbol, price);
    
    // 成交量：基于价格波动生成（波动大时成交量大）
    final priceChangePercent = state.priceHistory.length > 1
        ? ((price - state.priceHistory[state.priceHistory.length - 2]) / 
           state.priceHistory[state.priceHistory.length - 2]).abs()
        : 0.001;
    
    final baseAmount = 0.01 + _random.nextDouble() * 0.5;
    final amount = baseAmount * (1 + priceChangePercent * 100);
    
    // 买卖方向：价格上涨时更多买单，下跌时更多卖单
    final isBuy = priceChangePercent > 0 
        ? _random.nextDouble() > 0.3  // 70%买单
        : _random.nextDouble() > 0.7; // 30%买单
    
    return Trade(
      id: 'trade_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}',
      symbol: symbol,
      price: price,
      amount: amount,
      timestamp: DateTime.now(),
      isBuy: isBuy,
    );
  }
  
  /// 生成关联的订单薄
  OrderBook generateOrderBook(String symbol, {int depth = 20}) {
    final currentPrice = getCurrentPrice(symbol);
    
    // 计算买卖价差（基于价格的0.01% - 0.03%，更小的价差）
    final spreadPercent = 0.0001 + _random.nextDouble() * 0.0002;
    final spread = currentPrice * spreadPercent;
    
    final bestBid = currentPrice - spread / 2;
    final bestAsk = currentPrice + spread / 2;
    
    // 生成买单（价格递减）
    final bids = <OrderBookEntry>[];
    double bidTotal = 0;
    for (int i = 0; i < depth; i++) {
      // 价格间隔：越远离最优价格，间隔越大
      final priceStep = currentPrice * 0.0001 * (1 + i * 0.1);
      final price = bestBid - priceStep * i;
      
      // 数量：越接近最优价格，数量越小（模拟真实市场）
      final baseAmount = 0.5 + _random.nextDouble() * 2;
      final amount = baseAmount * (1 + i * 0.3);
      
      bidTotal += amount;
      bids.add(OrderBookEntry(
        price: price,
        amount: amount,
        total: bidTotal,
      ));
    }
    
    // 生成卖单（价格递增）
    final asks = <OrderBookEntry>[];
    double askTotal = 0;
    for (int i = 0; i < depth; i++) {
      final priceStep = currentPrice * 0.0001 * (1 + i * 0.1);
      final price = bestAsk + priceStep * i;
      
      final baseAmount = 0.5 + _random.nextDouble() * 2;
      final amount = baseAmount * (1 + i * 0.3);
      
      askTotal += amount;
      asks.add(OrderBookEntry(
        price: price,
        amount: amount,
        total: askTotal,
      ));
    }
    
    return OrderBook(
      symbol: symbol,
      bids: bids,
      asks: asks,
      timestamp: DateTime.now(),
    );
  }
  
  /// 生成关联的K线数据
  KlineData generateKlineUpdate(String symbol, KlineInterval interval) {
    final state = _getPriceState(symbol);
    final now = DateTime.now();
    final intervalMinutes = _getIntervalMinutes(interval);
    
    // 计算当前K线的时间窗口
    final candleTimestamp = _getCandleTimestamp(now, intervalMinutes);
    
    // 获取或创建K线缓存
    if (!_klineCache.containsKey(symbol)) {
      _klineCache[symbol] = {};
    }
    if (!_klineCache[symbol]!.containsKey(interval)) {
      _klineCache[symbol]![interval] = [];
    }
    
    final klineList = _klineCache[symbol]![interval]!;
    
    // 获取当前价格，使用小幅波动（±0.02%）
    final currentPrice = state.currentPrice;
    final priceVariation = currentPrice * 0.0002;
    final newPrice = currentPrice + (_random.nextDouble() - 0.5) * 2 * priceVariation;
    
    // 更新价格状态
    state.currentPrice = newPrice;
    state.lastUpdateTime = now;
    state.priceHistory.add(newPrice);
    
    // 保持历史记录在合理范围
    if (state.priceHistory.length > 1000) {
      state.priceHistory.removeAt(0);
    }
    
    // 同步相同币种的其他格式价格
    _syncAlternativeSymbol(symbol, newPrice);
    
    // 判断是更新现有K线还是创建新K线
    if (klineList.isEmpty || 
        klineList.last.timestamp.isBefore(candleTimestamp)) {
      // 创建新K线
      final newKline = KlineData(
        timestamp: candleTimestamp,
        open: newPrice,
        high: newPrice,
        low: newPrice,
        close: newPrice,
        volume: 0,
      );
      klineList.add(newKline);
      
      // 限制缓存大小
      if (klineList.length > 500) {
        klineList.removeAt(0);
      }
      
      return newKline;
    } else {
      // 更新最后一根K线
      final lastKline = klineList.last;
      final updatedKline = KlineData(
        timestamp: lastKline.timestamp,
        open: lastKline.open,
        high: max(lastKline.high, newPrice),
        low: min(lastKline.low, newPrice),
        close: newPrice,
        volume: lastKline.volume + (0.01 + _random.nextDouble() * 0.5),
      );
      
      klineList[klineList.length - 1] = updatedKline;
      return updatedKline;
    }
  }
  
  /// 生成历史K线数据
  List<KlineData> generateHistoricalKlines(
    String symbol, 
    KlineInterval interval, 
    {int count = 200}
  ) {
    final state = _getPriceState(symbol);
    final now = DateTime.now();
    final intervalMinutes = _getIntervalMinutes(interval);
    final klineList = <KlineData>[];
    
    // 保存初始价格，确保最后一根K线的收盘价接近当前价格
    final targetPrice = state.currentPrice;
    
    // 从目标价格反推起始价格（确保价格不会偏离太远）
    // 使用较小的波动率，让历史价格围绕当前价格波动
    double price = targetPrice * (0.95 + _random.nextDouble() * 0.1); // 95%-105%范围
    
    // 从过去生成到现在
    for (int i = count - 1; i >= 0; i--) {
      final timestamp = now.subtract(Duration(minutes: intervalMinutes * i));
      final candleTimestamp = _getCandleTimestamp(timestamp, intervalMinutes);
      
      // 生成K线的OHLC
      final open = price;
      
      // 使用较小的波动率（0.3%），避免价格偏离太远
      final volatility = 0.003;
      
      // 如果是最后几根K线，让价格逐渐回归到目标价格
      double close;
      if (i < 10) {
        // 最后10根K线，逐渐向目标价格靠拢
        final progress = (10 - i) / 10.0;
        final targetChange = (targetPrice - price) * progress * 0.3;
        final randomChange = ((_random.nextDouble() - 0.5) * 2) * price * volatility;
        close = price + targetChange + randomChange;
      } else {
        // 正常波动
        final change = ((_random.nextDouble() - 0.5) * 2) * price * volatility;
        close = open + change;
      }
      
      // 高低价
      final highExtra = _random.nextDouble() * price * volatility * 0.5;
      final lowExtra = _random.nextDouble() * price * volatility * 0.5;
      final high = max(open, close) + highExtra;
      final low = min(open, close) - lowExtra;
      
      // 成交量
      final volume = 50 + _random.nextDouble() * 500;
      
      klineList.add(KlineData(
        timestamp: candleTimestamp,
        open: open,
        high: high,
        low: low,
        close: close,
        volume: volume,
      ));
      
      // 更新价格为收盘价，用于下一根K线
      price = close;
    }
    
    // 确保最后一根K线的收盘价接近目标价格（误差<1%）
    if (klineList.isNotEmpty) {
      final lastKline = klineList.last;
      final priceDiff = (lastKline.close - targetPrice).abs();
      final diffPercent = priceDiff / targetPrice;
      
      if (diffPercent > 0.01) {
        // 如果误差超过1%，调整最后一根K线
        final adjustedKline = KlineData(
          timestamp: lastKline.timestamp,
          open: lastKline.open,
          high: max(lastKline.high, targetPrice),
          low: min(lastKline.low, targetPrice),
          close: targetPrice,
          volume: lastKline.volume,
        );
        klineList[klineList.length - 1] = adjustedKline;
      }
      
      // 更新当前价格为最后一根K线的收盘价
      state.currentPrice = klineList.last.close;
    }
    
    // 缓存K线数据
    if (!_klineCache.containsKey(symbol)) {
      _klineCache[symbol] = {};
    }
    _klineCache[symbol]![interval] = klineList;
    
    return klineList;
  }
  
  /// 生成行情Ticker数据
  MarketTicker generateTicker(String symbol) {
    final state = _getPriceState(symbol);
    final currentPrice = getCurrentPrice(symbol);
    
    // 计算24小时数据（基于价格历史）
    final priceHistory = state.priceHistory;
    
    // 如果历史数据不足，使用当前价格的98%作为24小时前价格
    final price24hAgo = priceHistory.length > 100 
        ? priceHistory[priceHistory.length - 100]
        : currentPrice * (0.98 + _random.nextDouble() * 0.04); // 98%-102%
    
    final change24h = ((currentPrice - price24hAgo) / price24hAgo) * 100;
    
    // 24小时高低价（基于当前价格的±2%范围，更合理）
    double high24h;
    double low24h;
    
    if (priceHistory.length > 100) {
      final recentPrices = priceHistory.sublist(priceHistory.length - 100);
      high24h = recentPrices.reduce(max);
      low24h = recentPrices.reduce(min);
      
      // 确保高低价在合理范围内（当前价格的±3%）
      high24h = min(high24h, currentPrice * 1.03);
      low24h = max(low24h, currentPrice * 0.97);
    } else {
      // 如果历史数据不足，使用当前价格的±1.5%
      high24h = currentPrice * (1 + _random.nextDouble() * 0.015);
      low24h = currentPrice * (1 - _random.nextDouble() * 0.015);
    }
    
    // 确保当前价格在高低价之间
    if (currentPrice > high24h) {
      high24h = currentPrice;
    }
    if (currentPrice < low24h) {
      low24h = currentPrice;
    }
    
    // 24小时成交量（基于价格波动）
    final volatility = (high24h - low24h) / currentPrice;
    final baseVolume = 1000000.0;
    final volume24h = baseVolume * (1 + volatility * 10);
    
    return MarketTicker(
      symbol: symbol,
      price: currentPrice,
      change24h: change24h,
      volume24h: volume24h,
      high24h: high24h,
      low24h: low24h,
      timestamp: DateTime.now(),
    );
  }
  
  /// 获取K线时间窗口的起始时间
  DateTime _getCandleTimestamp(DateTime time, int intervalMinutes) {
    final milliseconds = time.millisecondsSinceEpoch;
    final intervalMillis = intervalMinutes * 60 * 1000;
    final candleMillis = (milliseconds ~/ intervalMillis) * intervalMillis;
    return DateTime.fromMillisecondsSinceEpoch(candleMillis);
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
  
  /// 清除交易对的缓存数据
  void clearCache(String symbol) {
    _priceStates.remove(symbol);
    _klineCache.remove(symbol);
  }
  
  /// 清除所有缓存
  void clearAllCache() {
    _priceStates.clear();
    _klineCache.clear();
  }
}

/// 价格状态
class _PriceState {
  final String symbol;
  double currentPrice;
  DateTime lastUpdateTime;
  final List<double> priceHistory = [];
  
  // 趋势控制
  int trendDirection = 1; // 1=上涨趋势, -1=下跌趋势
  int trendCounter = 0;
  
  _PriceState({
    required this.symbol,
    required this.currentPrice,
    required this.lastUpdateTime,
  }) {
    priceHistory.add(currentPrice);
  }
}

