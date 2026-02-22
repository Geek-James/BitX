# WebSocket API 规范

## 连接端点

- **开发环境**：`ws://localhost:3001`
- **生产环境**：`wss://api.cybitx.com/ws`

## 认证方式

### 方式 1：URL 参数认证

```
ws://localhost:3001?token=<JWT_TOKEN>
```

### 方式 2：首条消息认证

连接后发送认证消息：

```json
{
  "action": "auth",
  "token": "<JWT_TOKEN>"
}
```

响应：

```json
{
  "type": "auth",
  "status": "success",
  "message": "Authentication successful"
}
```

## 消息格式

所有消息使用 JSON 格式，遵循以下结构：

### 客户端 → 服务器

```json
{
  "action": "subscribe|unsubscribe|ping",
  "channel": "channel_name",
  "params": {}
}
```

### 服务器 → 客户端

```json
{
  "type": "data|error|pong",
  "channel": "channel_name",
  "data": {},
  "timestamp": 1234567890
}
```

## 订阅/取消订阅协议

### 订阅频道

```json
{
  "action": "subscribe",
  "channel": "market.btcusdt"
}
```

响应：

```json
{
  "type": "subscribed",
  "channel": "market.btcusdt",
  "message": "Successfully subscribed to market.btcusdt"
}
```

### 取消订阅

```json
{
  "action": "unsubscribe",
  "channel": "market.btcusdt"
}
```

响应：

```json
{
  "type": "unsubscribed",
  "channel": "market.btcusdt",
  "message": "Successfully unsubscribed from market.btcusdt"
}
```

## 频道列表

### 1. 行情数据（Market Data）

#### 实时价格

**频道**：`market.{symbol}`

**示例**：`market.btcusdt`

**数据格式**：

```json
{
  "type": "data",
  "channel": "market.btcusdt",
  "data": {
    "symbol": "BTCUSDT",
    "price": "45000.50",
    "change24h": "2.5",
    "volume24h": "1234567890",
    "high24h": "46000.00",
    "low24h": "44000.00"
  },
  "timestamp": 1234567890
}
```

#### 深度数据

**频道**：`depth.{symbol}`

**示例**：`depth.btcusdt`

**数据格式**：

```json
{
  "type": "data",
  "channel": "depth.btcusdt",
  "data": {
    "symbol": "BTCUSDT",
    "bids": [
      ["45000.00", "1.5"],
      ["44999.00", "2.3"]
    ],
    "asks": [
      ["45001.00", "1.2"],
      ["45002.00", "3.1"]
    ]
  },
  "timestamp": 1234567890
}
```

### 2. K线图数据（Kline Data）

**频道**：`kline.{symbol}.{interval}`

**示例**：`kline.btcusdt.1m`（1分钟K线）

**支持的时间间隔**：`1m`, `5m`, `15m`, `30m`, `1h`, `4h`, `1d`, `1w`

**数据格式**：

```json
{
  "type": "data",
  "channel": "kline.btcusdt.1m",
  "data": {
    "symbol": "BTCUSDT",
    "interval": "1m",
    "openTime": 1234567890,
    "closeTime": 1234567950,
    "open": "45000.00",
    "high": "45100.00",
    "low": "44950.00",
    "close": "45050.00",
    "volume": "123.45"
  },
  "timestamp": 1234567890
}
```

### 3. 跟单数据（Copy Trading Data）

#### 跟单信号

**频道**：`copytrade.signal.{traderId}`

**示例**：`copytrade.signal.trader123`

**数据格式**：

```json
{
  "type": "data",
  "channel": "copytrade.signal.trader123",
  "data": {
    "traderId": "trader123",
    "signalType": "open|close",
    "symbol": "BTCUSDT",
    "side": "buy|sell",
    "price": "45000.00",
    "quantity": "1.5",
    "timestamp": 1234567890
  },
  "timestamp": 1234567890
}
```

#### 跟单收益更新

**频道**：`copytrade.profit.{traderId}`

**示例**：`copytrade.profit.trader123`

**数据格式**：

```json
{
  "type": "data",
  "channel": "copytrade.profit.trader123",
  "data": {
    "traderId": "trader123",
    "totalProfit": "12345.67",
    "profitRate": "15.5",
    "followers": 1234,
    "timestamp": 1234567890
  },
  "timestamp": 1234567890
}
```

### 4. 订单与仓位更新（Order & Position Updates）

**频道**：`user.orders` 或 `user.positions`

**需要认证**：是

**数据格式**：

```json
{
  "type": "data",
  "channel": "user.orders",
  "data": {
    "orderId": "order123",
    "symbol": "BTCUSDT",
    "status": "filled|partial|cancelled",
    "side": "buy|sell",
    "price": "45000.00",
    "quantity": "1.5",
    "filledQuantity": "1.5",
    "timestamp": 1234567890
  },
  "timestamp": 1234567890
}
```

## 心跳机制

### 客户端发送 Ping

```json
{
  "action": "ping"
}
```

### 服务器响应 Pong

```json
{
  "type": "pong",
  "timestamp": 1234567890
}
```

**心跳间隔**：建议每 30 秒发送一次 ping

**超时策略**：如果 60 秒内未收到任何消息（包括 pong），客户端应主动重连

## 错误码定义

| 错误码 | 说明 | 处理建议 |
|--------|------|----------|
| 1001 | 认证失败 | 检查 token 是否有效 |
| 1002 | 订阅失败 | 检查频道名称是否正确 |
| 1003 | 权限不足 | 检查用户权限 |
| 1004 | 频道不存在 | 检查频道名称 |
| 1005 | 参数错误 | 检查请求参数 |
| 5000 | 服务器内部错误 | 稍后重试 |

**错误消息格式**：

```json
{
  "type": "error",
  "code": 1002,
  "message": "Subscription failed: invalid channel name",
  "channel": "invalid.channel",
  "timestamp": 1234567890
}
```

## 重连策略

### 推荐策略：指数退避

1. 首次重连：立即重连
2. 第二次重连：等待 1 秒
3. 第三次重连：等待 2 秒
4. 第四次重连：等待 4 秒
5. 第五次及以后：等待 8 秒（最大间隔）

**最大重试次数**：建议设置为 10 次，超过后提示用户网络异常

### 重连后处理

1. 重新认证（如果需要）
2. 重新订阅之前的所有频道
3. 更新本地数据状态

## 连接限制

- **单个 IP 最大连接数**：10
- **单个连接最大订阅频道数**：50
- **消息发送频率限制**：每秒最多 10 条消息

## 示例代码

### JavaScript/TypeScript

```typescript
const ws = new WebSocket('ws://localhost:3001?token=YOUR_TOKEN');

ws.onopen = () => {
  console.log('WebSocket connected');
  
  // 订阅行情数据
  ws.send(JSON.stringify({
    action: 'subscribe',
    channel: 'market.btcusdt'
  }));
};

ws.onmessage = (event) => {
  const message = JSON.parse(event.data);
  console.log('Received:', message);
};

ws.onerror = (error) => {
  console.error('WebSocket error:', error);
};

ws.onclose = () => {
  console.log('WebSocket disconnected');
  // 实现重连逻辑
};
```

### Dart/Flutter

```dart
import 'package:web_socket_channel/web_socket_channel.dart';

final channel = WebSocketChannel.connect(
  Uri.parse('ws://localhost:3001?token=YOUR_TOKEN'),
);

// 订阅行情数据
channel.sink.add(jsonEncode({
  'action': 'subscribe',
  'channel': 'market.btcusdt',
}));

// 监听消息
channel.stream.listen(
  (message) {
    final data = jsonDecode(message);
    print('Received: $data');
  },
  onError: (error) {
    print('Error: $error');
  },
  onDone: () {
    print('Connection closed');
    // 实现重连逻辑
  },
);
```

## 版本历史

- **v0.1.0** (2026-02-12): 初始版本

