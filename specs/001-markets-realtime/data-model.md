# Data Model: 行情模块数据模型

**Feature**: 行情模块 - 实时价格展示  
**Date**: 2026-02-12  
**Status**: Completed

## 概述

本文档定义行情模块涉及的所有数据实体、字段、关系和验证规则。

---

## 核心实体

### 1. MarketTicker（行情数据）

**描述**：表示单个交易对的实时行情数据。

**字段**：

| 字段名 | 类型 | 必填 | 描述 | 验证规则 | 示例 |
|--------|------|------|------|----------|------|
| symbol | String | ✅ | 交易对符号 | 大写字母，无空格 | "BTCUSDT" |
| price | double | ✅ | 当前价格 | > 0 | 45000.50 |
| change24h | double | ✅ | 24小时涨跌幅（百分比） | 可正可负 | 2.5 或 -1.8 |
| volume24h | double | ✅ | 24小时成交量 | >= 0 | 1234567890.0 |
| high24h | double | ✅ | 24小时最高价 | > 0 | 46000.00 |
| low24h | double | ✅ | 24小时最低价 | > 0 | 44000.00 |
| timestamp | DateTime | ✅ | 数据时间戳 | 不能是未来时间 | 2026-02-12T10:30:00Z |

**Dart 实现**：

```dart
class MarketTicker {
  final String symbol;
  final double price;
  final double change24h;
  final double volume24h;
  final double high24h;
  final double low24h;
  final DateTime timestamp;

  MarketTicker({
    required this.symbol,
    required this.price,
    required this.change24h,
    required this.volume24h,
    required this.high24h,
    required this.low24h,
    required this.timestamp,
  });

  // 从 JSON 解析
  factory MarketTicker.fromJson(Map<String, dynamic> json) {
    return MarketTicker(
      symbol: json['symbol'] as String,
      price: double.parse(json['price'].toString()),
      change24h: double.parse(json['change24h'].toString()),
      volume24h: double.parse(json['volume24h'].toString()),
      high24h: double.parse(json['high24h'].toString()),
      low24h: double.parse(json['low24h'].toString()),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        json['timestamp'] as int,
      ),
    );
  }

  // 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'price': price.toString(),
      'change24h': change24h.toString(),
      'volume24h': volume24h.toString(),
      'high24h': high24h.toString(),
      'low24h': low24h.toString(),
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  // 判断是否上涨
  bool get isPositive => change24h >= 0;

  // 格式化涨跌幅
  String get formattedChange => '${isPositive ? '+' : ''}${change24h.toStringAsFixed(2)}%';
}
```

**TypeScript 实现（后端）**：

```typescript
export interface MarketTicker {
  symbol: string;
  price: string;        // 使用字符串避免精度问题
  change24h: string;
  volume24h: string;
  high24h: string;
  low24h: string;
  timestamp: number;    // Unix 时间戳（毫秒）
}

export class MarketTickerDto {
  symbol: string;
  price: string;
  change24h: string;
  volume24h: string;
  high24h: string;
  low24h: string;
  timestamp: number;

  constructor(data: Partial<MarketTicker>) {
    this.symbol = data.symbol || '';
    this.price = data.price || '0';
    this.change24h = data.change24h || '0';
    this.volume24h = data.volume24h || '0';
    this.high24h = data.high24h || '0';
    this.low24h = data.low24h || '0';
    this.timestamp = data.timestamp || Date.now();
  }

  validate(): boolean {
    return (
      this.symbol.length > 0 &&
      parseFloat(this.price) > 0 &&
      parseFloat(this.volume24h) >= 0 &&
      parseFloat(this.high24h) > 0 &&
      parseFloat(this.low24h) > 0
    );
  }
}
```

---

### 2. WebSocketConnectionState（WebSocket 连接状态）

**描述**：表示 WebSocket 连接的当前状态。

**字段**：

| 字段名 | 类型 | 必填 | 描述 | 可选值 | 示例 |
|--------|------|------|------|--------|------|
| status | ConnectionStatus | ✅ | 连接状态 | connecting, connected, disconnected, error | connected |
| retryCount | int | ✅ | 重连次数 | >= 0 | 3 |
| lastError | String? | ❌ | 最后一次错误信息 | - | "Connection timeout" |
| connectedAt | DateTime? | ❌ | 连接建立时间 | - | 2026-02-12T10:30:00Z |

**Dart 实现**：

```dart
enum ConnectionStatus {
  connecting,    // 连接中
  connected,     // 已连接
  disconnected,  // 已断开
  error,         // 错误
}

class WebSocketConnectionState {
  final ConnectionStatus status;
  final int retryCount;
  final String? lastError;
  final DateTime? connectedAt;

  WebSocketConnectionState({
    required this.status,
    this.retryCount = 0,
    this.lastError,
    this.connectedAt,
  });

  // 复制并修改部分字段
  WebSocketConnectionState copyWith({
    ConnectionStatus? status,
    int? retryCount,
    String? lastError,
    DateTime? connectedAt,
  }) {
    return WebSocketConnectionState(
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      connectedAt: connectedAt ?? this.connectedAt,
    );
  }

  // 判断是否已连接
  bool get isConnected => status == ConnectionStatus.connected;

  // 判断是否可以重连
  bool get canRetry => retryCount < 10;

  // 获取状态描述（用于 UI 显示）
  String getStatusText(AppLocalizations l10n) {
    switch (status) {
      case ConnectionStatus.connecting:
        return l10n.connecting;
      case ConnectionStatus.connected:
        return l10n.connected;
      case ConnectionStatus.disconnected:
        return l10n.disconnected;
      case ConnectionStatus.error:
        return l10n.connectionError;
    }
  }
}
```

---

### 3. MarketFilter（行情筛选条件）

**描述**：表示用户选择的筛选和排序条件。

**字段**：

| 字段名 | 类型 | 必填 | 描述 | 可选值 | 默认值 |
|--------|------|------|------|--------|--------|
| searchQuery | String | ❌ | 搜索关键词 | - | "" |
| sortBy | SortType | ✅ | 排序方式 | default, topGainers, topLosers, volume | default |

**Dart 实现**：

```dart
enum SortType {
  default_,      // 默认排序（按交易对名称）
  topGainers,    // 涨幅榜
  topLosers,     // 跌幅榜
  volume,        // 成交量榜
}

class MarketFilter {
  final String searchQuery;
  final SortType sortBy;

  MarketFilter({
    this.searchQuery = '',
    this.sortBy = SortType.default_,
  });

  MarketFilter copyWith({
    String? searchQuery,
    SortType? sortBy,
  }) {
    return MarketFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  // 判断是否有搜索条件
  bool get hasSearch => searchQuery.isNotEmpty;

  // 应用筛选和排序
  List<MarketTicker> apply(List<MarketTicker> tickers) {
    var result = tickers;

    // 应用搜索
    if (hasSearch) {
      result = result.where((ticker) {
        return ticker.symbol.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    // 应用排序
    switch (sortBy) {
      case SortType.topGainers:
        result.sort((a, b) => b.change24h.compareTo(a.change24h));
        break;
      case SortType.topLosers:
        result.sort((a, b) => a.change24h.compareTo(b.change24h));
        break;
      case SortType.volume:
        result.sort((a, b) => b.volume24h.compareTo(a.volume24h));
        break;
      case SortType.default_:
        result.sort((a, b) => a.symbol.compareTo(b.symbol));
        break;
    }

    return result;
  }
}
```

---

## 数据关系

```
WebSocketService
    ↓ (推送)
MarketTicker (List)
    ↓ (应用)
MarketFilter
    ↓ (输出)
Filtered & Sorted MarketTicker (List)
    ↓ (展示)
UI (ListView)
```

---

## 数据流

### 1. WebSocket 数据接收流程

```
后端 WebSocket 服务器
    ↓ (推送 JSON)
移动端 WebSocketService
    ↓ (解析 JSON)
List<MarketTicker>
    ↓ (发送到 Stream)
StreamProvider
    ↓ (监听)
UI Widget
```

### 2. 用户筛选流程

```
用户输入搜索关键词 / 点击筛选按钮
    ↓
更新 MarketFilter
    ↓
应用筛选和排序逻辑
    ↓
更新 UI 显示
```

---

## 数据验证规则

### MarketTicker 验证

```dart
class MarketTickerValidator {
  static String? validate(MarketTicker ticker) {
    if (ticker.symbol.isEmpty) {
      return 'Symbol cannot be empty';
    }
    if (ticker.price <= 0) {
      return 'Price must be greater than 0';
    }
    if (ticker.volume24h < 0) {
      return 'Volume cannot be negative';
    }
    if (ticker.high24h <= 0 || ticker.low24h <= 0) {
      return 'High and low prices must be greater than 0';
    }
    if (ticker.high24h < ticker.low24h) {
      return 'High price cannot be less than low price';
    }
    if (ticker.timestamp.isAfter(DateTime.now())) {
      return 'Timestamp cannot be in the future';
    }
    return null; // 验证通过
  }
}
```

---

## 状态转换

### WebSocket 连接状态转换

```
[初始状态]
    ↓
connecting (连接中)
    ↓
    ├─→ connected (已连接) ──→ disconnected (断开) ──→ connecting (重连)
    │                                                      ↓
    └─→ error (错误) ──────────────────────────────────→ connecting (重连)
                                                            ↓
                                                    (超过最大重试次数)
                                                            ↓
                                                        error (最终失败)
```

---

## 数据示例

### WebSocket 推送消息示例

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
  ]
}
```

---

## 性能考虑

### 1. 数据更新频率

- WebSocket 推送频率：每秒最多 1 次（后端节流）
- UI 更新频率：~60 fps（16ms 一次）
- 使用 `throttleTime` 限制数据流频率

### 2. 内存管理

- 只保留最新的行情数据，不缓存历史数据
- 使用 `ListView.builder` 懒加载，减少内存占用
- 离开行情页面时，关闭 WebSocket 连接

### 3. 数据精度

- 价格使用 `double` 类型（Dart）
- 后端使用 `string` 类型传输，避免精度丢失
- 前端解析时使用 `double.parse()`

---

## 总结

本文档定义了行情模块的核心数据模型：

1. **MarketTicker**：行情数据实体
2. **WebSocketConnectionState**：连接状态实体
3. **MarketFilter**：筛选条件实体

所有实体都包含完整的字段定义、验证规则和代码实现示例。

**下一步**：创建 API 契约文档（`contracts/websocket.md`）。

