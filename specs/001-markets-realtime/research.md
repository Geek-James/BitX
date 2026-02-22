# Research: 行情模块技术研究

**Feature**: 行情模块 - 实时价格展示  
**Date**: 2026-02-12  
**Status**: Completed

## 研究概述

本文档记录行情模块实现过程中的技术研究与决策，包括 WebSocket 库选择、状态管理方案、重连策略、国际化方案、性能优化等关键技术点。

---

## 1. WebSocket 库选择（移动端）

### 研究问题

Flutter 中有多个 WebSocket 库可选，需要选择最适合本项目的方案。

### 候选方案

| 方案 | 优点 | 缺点 |
|------|------|------|
| **web_socket_channel** | Flutter 官方推荐；轻量级；符合标准 WebSocket 协议；API 简洁 | 功能相对基础，需要自己实现重连等高级功能 |
| **socket_io_client** | 功能丰富；自动重连；支持房间、命名空间等高级特性 | 体积较大；需要后端也使用 Socket.IO；协议不是标准 WebSocket |

### 决策

**选择：web_socket_channel**

**理由**：
1. Flutter 官方推荐，维护活跃
2. 轻量级，符合项目性能要求
3. 符合标准 WebSocket 协议，后端可以使用任何 WebSocket 库
4. API 简洁，易于理解和维护
5. 重连逻辑可以自己实现，更灵活可控

**实现示例**：
```dart
import 'package:web_socket_channel/web_socket_channel.dart';

final channel = WebSocketChannel.connect(
  Uri.parse('wss://api.cybitx.com/ws/markets'),
);

// 监听消息
channel.stream.listen(
  (message) {
    print('Received: $message');
  },
  onError: (error) {
    print('Error: $error');
  },
  onDone: () {
    print('Connection closed');
  },
);

// 发送消息
channel.sink.add(jsonEncode({'action': 'subscribe', 'channel': 'market.all'}));
```

---

## 2. WebSocket 库选择（后端）

### 研究问题

Node.js 中有多个 WebSocket 库可选，需要选择最适合本项目的方案。

### 候选方案

| 方案 | 优点 | 缺点 |
|------|------|------|
| **ws** | 轻量级；性能好；符合标准 WebSocket 协议；API 简洁 | 功能相对基础，需要自己实现房间、广播等功能 |
| **socket.io** | 功能丰富；自动降级（WebSocket -> 轮询）；支持房间、命名空间 | 体积较大；协议不是标准 WebSocket；需要客户端也使用 Socket.IO |
| **uWebSockets.js** | 性能极高；内存占用低 | API 较复杂；社区相对较小 |

### 决策

**选择：ws**

**理由**：
1. 轻量级，性能好，满足项目需求
2. 符合标准 WebSocket 协议，与移动端 `web_socket_channel` 兼容
3. API 简洁，易于理解和维护
4. 社区活跃，文档完善
5. 行情推送场景相对简单，不需要 Socket.IO 的高级特性

**实现示例**：
```typescript
import WebSocket, { WebSocketServer } from 'ws';
import express from 'express';

const app = express();
const server = app.listen(3000);

const wss = new WebSocketServer({ server, path: '/ws/markets' });

wss.on('connection', (ws) => {
  console.log('Client connected');

  ws.on('message', (message) => {
    const data = JSON.parse(message.toString());
    if (data.action === 'subscribe') {
      // 处理订阅逻辑
    }
  });

  ws.on('close', () => {
    console.log('Client disconnected');
  });
});

// 广播行情数据
function broadcastMarketData(data) {
  wss.clients.forEach((client) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(JSON.stringify({
        type: 'data',
        channel: 'market.all',
        data: data,
      }));
    }
  });
}
```

---

## 3. 状态管理方案（Riverpod）

### 研究问题

Riverpod 提供多种 Provider 类型，需要选择最适合 WebSocket 数据流的方案。

### 候选方案

| 方案 | 适用场景 | 优点 | 缺点 |
|------|----------|------|------|
| **StreamProvider** | 监听数据流（如 WebSocket） | 自动处理异步数据流；支持 loading/error 状态 | 需要手动管理 Stream 生命周期 |
| **StateNotifierProvider** | 复杂状态管理 | 灵活；可以封装复杂逻辑 | 需要更多代码；不如 StreamProvider 直观 |
| **FutureProvider** | 一次性异步操作 | 简单；适合 HTTP 请求 | 不适合持续的数据流 |

### 决策

**选择：StreamProvider**

**理由**：
1. 专为数据流设计，与 WebSocket 天然契合
2. 自动处理 loading/error 状态，减少样板代码
3. 支持 Riverpod 的精细化刷新（`select`）
4. 代码简洁，易于理解

**实现示例**：
```dart
// Provider 定义
final marketTickersProvider = StreamProvider<List<MarketTicker>>((ref) {
  final wsService = ref.watch(webSocketServiceProvider);
  return wsService.marketTickersStream;
});

// UI 中使用
class MarketsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickersAsync = ref.watch(marketTickersProvider);

    return tickersAsync.when(
      data: (tickers) => ListView.builder(
        itemCount: tickers.length,
        itemBuilder: (context, index) => MarketTickerTile(tickers[index]),
      ),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

---

## 4. 重连策略实现

### 研究问题

WebSocket 连接可能因网络波动而断开，需要实现自动重连机制。

### 候选方案

| 方案 | 优点 | 缺点 |
|------|------|------|
| **固定间隔重连** | 实现简单 | 可能对服务器造成压力；不够智能 |
| **指数退避** | 平衡重连速度与服务器压力；业界标准 | 实现稍复杂 |
| **线性退避** | 实现简单；比固定间隔好 | 不如指数退避高效 |

### 决策

**选择：指数退避（Exponential Backoff）**

**理由**：
1. 业界标准做法（Google、AWS 等都推荐）
2. 平衡重连速度与服务器压力
3. 符合宪章要求（FR-004）

**参数设置**：
- 初始延迟：1 秒
- 最大延迟：8 秒
- 最大重试次数：10 次
- 退避序列：1s → 2s → 4s → 8s → 8s → ...

**实现示例**：
```dart
class WebSocketService {
  int _retryCount = 0;
  static const int _maxRetries = 10;
  static const List<int> _retryDelays = [1, 2, 4, 8]; // 秒

  Future<void> _reconnect() async {
    if (_retryCount >= _maxRetries) {
      _logger.error('Max retries reached');
      return;
    }

    final delayIndex = _retryCount < _retryDelays.length 
        ? _retryCount 
        : _retryDelays.length - 1;
    final delay = Duration(seconds: _retryDelays[delayIndex]);

    _logger.info('Reconnecting in ${delay.inSeconds}s (attempt ${_retryCount + 1})');
    await Future.delayed(delay);

    _retryCount++;
    _connect();
  }
}
```

---

## 5. 国际化方案

### 研究问题

Flutter 提供多种国际化方案，需要选择最适合本项目的方案。

### 候选方案

| 方案 | 优点 | 缺点 |
|------|------|------|
| **ARB 文件 + flutter_localizations** | Flutter 官方推荐；易于维护；支持复数、性别等 | 需要代码生成步骤 |
| **intl 包 + 手动管理** | 灵活；不需要代码生成 | 维护成本高；容易出错 |
| **easy_localization** | 第三方库；功能丰富 | 增加依赖；不如官方方案稳定 |

### 决策

**选择：ARB 文件 + flutter_localizations**

**理由**：
1. Flutter 官方推荐方案
2. 易于维护（所有文案集中在 ARB 文件中）
3. 支持复数、性别、日期格式化等高级特性
4. 符合宪章要求（I18N-002）

**文件结构**：
```
mobile/lib/shared/l10n/
├── app_zh.arb    # 简体中文
└── app_en.arb    # 英语
```

**ARB 文件示例**：
```json
// app_zh.arb
{
  "@@locale": "zh",
  "markets": "行情",
  "search": "搜索",
  "topGainers": "涨幅榜",
  "topLosers": "跌幅榜",
  "volume": "成交量",
  "price": "价格",
  "change24h": "24h涨跌"
}

// app_en.arb
{
  "@@locale": "en",
  "markets": "Markets",
  "search": "Search",
  "topGainers": "Top Gainers",
  "topLosers": "Top Losers",
  "volume": "Volume",
  "price": "Price",
  "change24h": "24h Change"
}
```

**使用示例**：
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Text(AppLocalizations.of(context)!.markets)
```

---

## 6. 性能优化

### 研究问题

行情页面需要保持 60 fps 流畅度，需要研究性能优化方案。

### 优化方向

#### 6.1 列表组件选择

**决策：ListView.builder**

**理由**：
- 懒加载，只构建可见的 Widget
- 性能好，适合长列表
- Flutter 官方推荐

**实现示例**：
```dart
ListView.builder(
  itemCount: tickers.length,
  itemBuilder: (context, index) {
    return MarketTickerTile(tickers[index]);
  },
)
```

#### 6.2 Riverpod 精细化刷新

**决策：使用 `select` 精细化订阅**

**理由**：
- 只在关心的数据变化时才重建 Widget
- 减少不必要的重建，提升性能

**实现示例**：
```dart
// 只在特定交易对的价格变化时重建
final btcPrice = ref.watch(
  marketTickersProvider.select((tickers) {
    return tickers.value
        ?.firstWhere((t) => t.symbol == 'BTCUSDT')
        .price;
  }),
);
```

#### 6.3 避免频繁重建

**决策：使用 `const` 构造函数**

**理由**：
- `const` Widget 不会重建，提升性能
- 适用于静态 UI 组件

**实现示例**：
```dart
const Text('Markets', style: TextStyle(fontSize: 24))
```

#### 6.4 数据更新节流

**决策：限制 WebSocket 数据更新频率**

**理由**：
- 避免过于频繁的 UI 更新
- 人眼无法感知超过 60 fps 的变化

**实现示例**：
```dart
Stream<List<MarketTicker>> get marketTickersStream {
  return _rawStream
      .throttleTime(Duration(milliseconds: 16)) // ~60 fps
      .distinct(); // 只在数据真正变化时发出
}
```

---

## 7. 数字格式化

### 研究问题

不同语言的数字格式不同（千分位、小数点），需要正确处理。

### 决策

**使用 `intl` 包的 `NumberFormat`**

**理由**：
1. 支持多种语言的数字格式
2. 自动处理千分位、小数点
3. Flutter 官方推荐

**实现示例**：
```dart
import 'package:intl/intl.dart';

String formatPrice(double price, Locale locale) {
  final formatter = NumberFormat.currency(
    locale: locale.toString(),
    symbol: '\$',
    decimalDigits: 2,
  );
  return formatter.format(price);
}

// 使用
formatPrice(45000.50, Locale('zh', 'CN')); // ¥45,000.50
formatPrice(45000.50, Locale('en', 'US')); // $45,000.50
```

---

## 8. 错误处理与日志

### 研究问题

需要记录 WebSocket 连接状态、错误信息，便于调试和监控。

### 决策

**使用结构化日志**

**理由**：
1. 便于搜索和分析
2. 可以集成到日志平台（如 Sentry、Firebase Crashlytics）
3. 符合宪章要求（OBS-001/002）

**实现示例**：
```dart
class Logger {
  static void info(String message, {Map<String, dynamic>? extra}) {
    print('[INFO] $message ${extra != null ? jsonEncode(extra) : ''}');
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    print('[ERROR] $message');
    if (error != null) print('Error: $error');
    if (stackTrace != null) print('StackTrace: $stackTrace');
  }
}

// 使用
Logger.info('WebSocket connected', extra: {'url': wsUrl});
Logger.error('WebSocket connection failed', error: e, stackTrace: stack);
```

---

## 研究结论

所有关键技术点已完成研究，决策如下：

| 技术点 | 决策 | 状态 |
|--------|------|------|
| WebSocket 库（移动端） | web_socket_channel | ✅ 已确定 |
| WebSocket 库（后端） | ws | ✅ 已确定 |
| 状态管理 | Riverpod StreamProvider | ✅ 已确定 |
| 重连策略 | 指数退避（1s、2s、4s、8s） | ✅ 已确定 |
| 国际化方案 | ARB 文件 + flutter_localizations | ✅ 已确定 |
| 列表组件 | ListView.builder | ✅ 已确定 |
| 性能优化 | select 精细化订阅 + const + 节流 | ✅ 已确定 |
| 数字格式化 | intl NumberFormat | ✅ 已确定 |
| 日志方案 | 结构化日志 | ✅ 已确定 |

**下一步**：进入 Phase 1，创建数据模型和 API 契约文档。


