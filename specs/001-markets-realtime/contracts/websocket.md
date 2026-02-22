# WebSocket API Contract: 行情数据推送

**Feature**: 行情模块 - 实时价格展示  
**Date**: 2026-02-12  
**Version**: 1.0.0  
**Protocol**: WebSocket (RFC 6455)

## 概述

本文档定义行情模块的 WebSocket API 契约，包括连接端点、认证方式、消息格式、订阅协议、心跳机制、错误码定义和重连策略。

---

## 连接端点

### 开发环境
```
ws://localhost:3001/ws/markets
```

### 生产环境
```
wss://api.cybitx.com/ws/markets
```

**注意**：生产环境必须使用 TLS 加密（wss://）。

---

## 认证方式

### 方式 1：无需认证（推荐）

行情数据为公开数据，无需认证即可订阅。

```javascript
// 直接连接
const ws = new WebSocket('wss://api.cybitx.com/ws/markets');
```

### 方式 2：URL 参数认证（预留）

如果未来需要认证，可以通过 URL 参数传递 token：

```javascript
const ws = new WebSocket('wss://api.cybitx.com/ws/markets?token=YOUR_TOKEN');
```

---

## 消息格式

所有消息使用 JSON 格式。

### 客户端 → 服务器

```typescript
interface ClientMessage {
  action: 'subscribe' | 'unsubscribe' | 'ping';
  channel?: string;
  params?: Record<string, any>;
}
```

### 服务器 → 客户端

```typescript
interface ServerMessage {
  type: 'subscribed' | 'unsubscribed' | 'data' | 'error' | 'pong';
  channel?: string;
  data?: any;
  message?: string;
  code?: number;
  timestamp: number;
}
```

---

## 订阅/取消订阅协议

### 订阅所有交易对

**客户端发送**：
```json
{
  "action": "subscribe",
  "channel": "market.all"
}
```

**服务器响应**：
```json
{
  "type": "subscribed",
  "channel": "market.all",
  "message": "Successfully subscribed to market.all",
  "timestamp": 1707728400000
}
```

### 订阅特定交易对

**客户端发送**：
```json
{
  "action": "subscribe",
  "channel": "market.BTCUSDT"
}
```

**服务器响应**：
```json
{
  "type": "subscribed",
  "channel": "market.BTCUSDT",
  "message": "Successfully subscribed to market.BTCUSDT",
  "timestamp": 1707728400000
}
```

### 取消订阅

**客户端发送**：
```json
{
  "action": "unsubscribe",
  "channel": "market.all"
}
```

**服务器响应**：
```json
{
  "type": "unsubscribed",
  "channel": "market.all",
  "message": "Successfully unsubscribed from market.all",
  "timestamp": 1707728400000
}
```

---

## 数据推送

### 行情数据推送（所有交易对）

**频道**：`market.all`

**推送频率**：每秒最多 1 次

**消息格式**：
```json
{
  "type": "data",
  "channel": "market.all",
  "data": [
    {
      "symbol": "BTCUSDT",
      "price": "45000.50",
      "change24h": "2.5",
      "volume24h": "1234567890",
      "high24h": "46000.00",
      "low24h": "44000.00",
      "timestamp": 1707728400000
    },
    {
      "symbol": "ETHUSDT",
      "price": "2500.30",
      "change24h": "-1.2",
      "volume24h": "987654321",
      "high24h": "2550.00",
      "low24h": "2480.00",
      "timestamp": 1707728400000
    }
  ],
  "timestamp": 1707728400000
}
```

### 行情数据推送（单个交易对）

**频道**：`market.{symbol}`（如 `market.BTCUSDT`）

**推送频率**：每秒最多 1 次

**消息格式**：
```json
{
  "type": "data",
  "channel": "market.BTCUSDT",
  "data": {
    "symbol": "BTCUSDT",
    "price": "45000.50",
    "change24h": "2.5",
    "volume24h": "1234567890",
    "high24h": "46000.00",
    "low24h": "44000.00",
    "timestamp": 1707728400000
  },
  "timestamp": 1707728400000
}
```

---

## 心跳机制

### 客户端发送 Ping

**建议频率**：每 30 秒发送一次

**消息格式**：
```json
{
  "action": "ping"
}
```

### 服务器响应 Pong

**消息格式**：
```json
{
  "type": "pong",
  "timestamp": 1707728400000
}
```

### 超时策略

- 如果 60 秒内未收到任何消息（包括 pong、数据推送），客户端应主动断开并重连
- 服务器如果 90 秒内未收到任何消息（包括 ping、订阅请求），将主动断开连接

---

## 错误码定义

| 错误码 | 说明 | 处理建议 |
|--------|------|----------|
| 1001 | 认证失败 | 检查 token 是否有效（如果需要认证） |
| 1002 | 订阅失败 | 检查频道名称是否正确 |
| 1003 | 权限不足 | 检查用户权限（如果需要认证） |
| 1004 | 频道不存在 | 检查频道名称是否正确 |
| 1005 | 参数错误 | 检查请求参数格式 |
| 1006 | 订阅数量超限 | 减少订阅的频道数量 |
| 5000 | 服务器内部错误 | 稍后重试 |

### 错误消息格式

```json
{
  "type": "error",
  "code": 1002,
  "message": "Subscription failed: invalid channel name",
  "channel": "invalid.channel",
  "timestamp": 1707728400000
}
```

---

## 重连策略

### 推荐策略：指数退避（Exponential Backoff）

1. **首次重连**：立即重连（0 秒）
2. **第二次重连**：等待 1 秒
3. **第三次重连**：等待 2 秒
4. **第四次重连**：等待 4 秒
5. **第五次及以后**：等待 8 秒（最大间隔）

**最大重试次数**：10 次

**超过最大重试次数后**：停止重连，提示用户"网络异常，请检查网络连接"，并提供"重试"按钮。

### 重连后处理

1. 重新订阅之前的所有频道
2. 更新本地连接状态
3. 记录重连日志

---

## 连接限制

- **单个 IP 最大连接数**：10
- **单个连接最大订阅频道数**：50
- **消息发送频率限制**：每秒最多 10 条消息

---

## 完整示例

### Dart/Flutter 客户端示例

```dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class MarketsWebSocketService {
  WebSocketChannel? _channel;
  StreamController<List<MarketTicker>>? _controller;
  Timer? _pingTimer;
  int _retryCount = 0;
  static const int _maxRetries = 10;
  static const List<int> _retryDelays = [1, 2, 4, 8];

  Stream<List<MarketTicker>> get marketTickersStream => _controller!.stream;

  void connect() {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('wss://api.cybitx.com/ws/markets'),
      );

      _controller = StreamController<List<MarketTicker>>.broadcast();

      // 监听消息
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      // 订阅所有交易对
      _subscribe();

      // 启动心跳
      _startPing();

      _retryCount = 0; // 重置重连次数
    } catch (e) {
      print('Connection error: $e');
      _reconnect();
    }
  }

  void _subscribe() {
    _channel?.sink.add(jsonEncode({
      'action': 'subscribe',
      'channel': 'market.all',
    }));
  }

  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      
      if (data['type'] == 'data') {
        final tickers = (data['data'] as List)
            .map((json) => MarketTicker.fromJson(json))
            .toList();
        _controller?.add(tickers);
      } else if (data['type'] == 'error') {
        print('Error: ${data['message']}');
      }
    } catch (e) {
      print('Parse error: $e');
    }
  }

  void _onError(error) {
    print('WebSocket error: $error');
    _reconnect();
  }

  void _onDone() {
    print('WebSocket connection closed');
    _reconnect();
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(Duration(seconds: 30), (_) {
      _channel?.sink.add(jsonEncode({'action': 'ping'}));
    });
  }

  Future<void> _reconnect() async {
    if (_retryCount >= _maxRetries) {
      print('Max retries reached');
      return;
    }

    final delayIndex = _retryCount < _retryDelays.length 
        ? _retryCount 
        : _retryDelays.length - 1;
    final delay = Duration(seconds: _retryDelays[delayIndex]);

    print('Reconnecting in ${delay.inSeconds}s (attempt ${_retryCount + 1})');
    await Future.delayed(delay);

    _retryCount++;
    connect();
  }

  void dispose() {
    _pingTimer?.cancel();
    _channel?.sink.close();
    _controller?.close();
  }
}
```

### Node.js 服务器示例

```typescript
import WebSocket, { WebSocketServer } from 'ws';
import express from 'express';

const app = express();
const server = app.listen(3001);

const wss = new WebSocketServer({ 
  server, 
  path: '/ws/markets' 
});

// 存储所有订阅的客户端
const subscribers = new Set<WebSocket>();

wss.on('connection', (ws) => {
  console.log('Client connected');

  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message.toString());

      if (data.action === 'subscribe') {
        handleSubscribe(ws, data.channel);
      } else if (data.action === 'unsubscribe') {
        handleUnsubscribe(ws, data.channel);
      } else if (data.action === 'ping') {
        ws.send(JSON.stringify({
          type: 'pong',
          timestamp: Date.now(),
        }));
      }
    } catch (error) {
      console.error('Parse error:', error);
    }
  });

  ws.on('close', () => {
    console.log('Client disconnected');
    subscribers.delete(ws);
  });
});

function handleSubscribe(ws: WebSocket, channel: string) {
  if (channel === 'market.all') {
    subscribers.add(ws);
    ws.send(JSON.stringify({
      type: 'subscribed',
      channel: 'market.all',
      message: 'Successfully subscribed to market.all',
      timestamp: Date.now(),
    }));
  } else {
    ws.send(JSON.stringify({
      type: 'error',
      code: 1004,
      message: 'Channel not found',
      channel: channel,
      timestamp: Date.now(),
    }));
  }
}

function handleUnsubscribe(ws: WebSocket, channel: string) {
  subscribers.delete(ws);
  ws.send(JSON.stringify({
    type: 'unsubscribed',
    channel: channel,
    message: `Successfully unsubscribed from ${channel}`,
    timestamp: Date.now(),
  }));
}

// 定期推送行情数据（模拟）
setInterval(() => {
  const marketData = generateMockMarketData();
  broadcastMarketData(marketData);
}, 1000);

function broadcastMarketData(data: any[]) {
  const message = JSON.stringify({
    type: 'data',
    channel: 'market.all',
    data: data,
    timestamp: Date.now(),
  });

  subscribers.forEach((client) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(message);
    }
  });
}

function generateMockMarketData() {
  return [
    {
      symbol: 'BTCUSDT',
      price: (45000 + Math.random() * 1000).toFixed(2),
      change24h: (Math.random() * 10 - 5).toFixed(2),
      volume24h: '1234567890',
      high24h: '46000.00',
      low24h: '44000.00',
      timestamp: Date.now(),
    },
    {
      symbol: 'ETHUSDT',
      price: (2500 + Math.random() * 100).toFixed(2),
      change24h: (Math.random() * 10 - 5).toFixed(2),
      volume24h: '987654321',
      high24h: '2550.00',
      low24h: '2480.00',
      timestamp: Date.now(),
    },
  ];
}
```

---

## 版本历史

- **v1.0.0** (2026-02-12): 初始版本
  - 定义连接端点、消息格式、订阅协议
  - 定义心跳机制、错误码、重连策略
  - 提供完整的客户端和服务器示例代码

---

## 附录：测试清单

### 功能测试

- [ ] 成功建立 WebSocket 连接
- [ ] 成功订阅 `market.all` 频道
- [ ] 成功接收行情数据推送
- [ ] 成功取消订阅
- [ ] 心跳机制正常工作（ping/pong）
- [ ] 错误消息正确返回

### 异常测试

- [ ] 网络断开后自动重连
- [ ] 重连后自动恢复订阅
- [ ] 超过最大重试次数后停止重连
- [ ] 无效频道名称返回错误
- [ ] 超时后自动断开连接

### 性能测试

- [ ] 100 个并发连接正常工作
- [ ] 数据推送延迟 < 100ms
- [ ] 长时间连接（1 小时）稳定

---

**下一步**：创建快速开始指南（`quickstart.md`）。

