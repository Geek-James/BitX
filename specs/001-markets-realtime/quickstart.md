# Quick Start: 行情模块开发指南

**Feature**: 行情模块 - 实时价格展示  
**Date**: 2026-02-12  
**Audience**: 开发人员

## 概述

本指南帮助开发人员快速上手行情模块的开发，包括环境准备、本地开发、测试和部署。

---

## 前置要求

### 移动端

- Flutter SDK 3.38.1
- Dart SDK（随 Flutter 安装）
- Android Studio / Xcode（用于模拟器）
- VS Code 或 Android Studio（推荐安装 Flutter 插件）

### 后端

- Node.js >= 16.x
- npm 或 yarn
- VS Code 或其他代码编辑器

---

## 快速开始（5 分钟）

### 1. 克隆项目

```bash
cd d:\Bit-Project
```

### 2. 启动后端服务

```bash
cd backend
npm install
npm run start:dev
```

后端服务将在 `http://localhost:3000` 启动，WebSocket 端点为 `ws://localhost:3001/ws/markets`。

### 3. 启动移动端

```bash
cd mobile
flutter pub get
flutter run
```

选择目标设备（Android 模拟器、iOS 模拟器或 Windows 桌面）。

### 4. 验证功能

- 打开 App，进入行情页面
- 应该能看到实时更新的价格列表
- 尝试搜索交易对（如 "BTC"）
- 尝试切换筛选条件（涨幅榜、跌幅榜、成交量榜）

---

## 目录结构

### 移动端

```
mobile/lib/features/markets/
├── models/
│   ├── market_ticker.dart           # 行情数据模型
│   ├── websocket_connection_state.dart  # 连接状态模型
│   └── market_filter.dart           # 筛选条件模型
├── providers/
│   ├── markets_provider.dart        # Riverpod Provider
│   ├── websocket_service_provider.dart
│   └── market_filter_provider.dart
├── widgets/
│   ├── market_ticker_tile.dart      # 单个交易对卡片
│   ├── market_search_bar.dart       # 搜索框
│   ├── market_filter_tabs.dart      # 筛选标签
│   └── connection_status_banner.dart # 连接状态提示
└── screens/
    └── markets_screen.dart          # 行情页面
```

### 后端

```
backend/src/modules/markets/
├── markets.service.ts               # 行情服务（获取数据）
├── markets.gateway.ts               # WebSocket 网关
└── dto/
    └── market-ticker.dto.ts         # 数据传输对象
```

---

## 开发流程

### Step 1: 实现数据模型

**文件**: `mobile/lib/features/markets/models/market_ticker.dart`

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

  factory MarketTicker.fromJson(Map<String, dynamic> json) {
    return MarketTicker(
      symbol: json['symbol'] as String,
      price: double.parse(json['price'].toString()),
      change24h: double.parse(json['change24h'].toString()),
      volume24h: double.parse(json['volume24h'].toString()),
      high24h: double.parse(json['high24h'].toString()),
      low24h: double.parse(json['low24h'].toString()),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
    );
  }

  bool get isPositive => change24h >= 0;
}
```

### Step 2: 实现 WebSocket 服务

**文件**: `mobile/lib/shared/network/websocket_service.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<List<MarketTicker>>? _controller;
  Timer? _pingTimer;
  int _retryCount = 0;

  Stream<List<MarketTicker>> get marketTickersStream => _controller!.stream;

  void connect() {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:3001/ws/markets'),
    );

    _controller = StreamController<List<MarketTicker>>.broadcast();

    _channel!.stream.listen(
      (message) {
        final data = jsonDecode(message);
        if (data['type'] == 'data') {
          final tickers = (data['data'] as List)
              .map((json) => MarketTicker.fromJson(json))
              .toList();
          _controller?.add(tickers);
        }
      },
      onError: (_) => _reconnect(),
      onDone: () => _reconnect(),
    );

    _subscribe();
    _startPing();
  }

  void _subscribe() {
    _channel?.sink.add(jsonEncode({
      'action': 'subscribe',
      'channel': 'market.all',
    }));
  }

  void _startPing() {
    _pingTimer = Timer.periodic(Duration(seconds: 30), (_) {
      _channel?.sink.add(jsonEncode({'action': 'ping'}));
    });
  }

  Future<void> _reconnect() async {
    if (_retryCount >= 10) return;
    await Future.delayed(Duration(seconds: [1, 2, 4, 8][_retryCount.clamp(0, 3)]));
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

### Step 3: 创建 Riverpod Provider

**文件**: `mobile/lib/features/markets/providers/markets_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final webSocketServiceProvider = Provider((ref) {
  final service = WebSocketService();
  service.connect();
  ref.onDispose(() => service.dispose());
  return service;
});

final marketTickersProvider = StreamProvider<List<MarketTicker>>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.marketTickersStream;
});
```

### Step 4: 实现 UI

**文件**: `mobile/lib/features/markets/screens/markets_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MarketsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickersAsync = ref.watch(marketTickersProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Markets')),
      body: tickersAsync.when(
        data: (tickers) => ListView.builder(
          itemCount: tickers.length,
          itemBuilder: (context, index) {
            final ticker = tickers[index];
            return ListTile(
              title: Text(ticker.symbol),
              subtitle: Text('\$${ticker.price.toStringAsFixed(2)}'),
              trailing: Text(
                '${ticker.change24h >= 0 ? '+' : ''}${ticker.change24h.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: ticker.change24h >= 0 ? Colors.green : Colors.red,
                ),
              ),
            );
          },
        ),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
```

### Step 5: 实现后端 WebSocket 服务

**文件**: `backend/src/modules/markets/markets.gateway.ts`

```typescript
import { WebSocketGateway, WebSocketServer, SubscribeMessage } from '@nestjs/websockets';
import { Server, WebSocket } from 'ws';

@WebSocketGateway({ path: '/ws/markets' })
export class MarketsGateway {
  @WebSocketServer()
  server: Server;

  private subscribers = new Set<WebSocket>();

  @SubscribeMessage('subscribe')
  handleSubscribe(client: WebSocket, payload: any) {
    if (payload.channel === 'market.all') {
      this.subscribers.add(client);
      client.send(JSON.stringify({
        type: 'subscribed',
        channel: 'market.all',
        timestamp: Date.now(),
      }));
    }
  }

  @SubscribeMessage('ping')
  handlePing(client: WebSocket) {
    client.send(JSON.stringify({
      type: 'pong',
      timestamp: Date.now(),
    }));
  }

  // 定期推送行情数据
  broadcastMarketData() {
    const data = this.generateMockData();
    const message = JSON.stringify({
      type: 'data',
      channel: 'market.all',
      data: data,
      timestamp: Date.now(),
    });

    this.subscribers.forEach((client) => {
      if (client.readyState === WebSocket.OPEN) {
        client.send(message);
      }
    });
  }

  private generateMockData() {
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
    ];
  }
}
```

---

## 本地开发

### 热重载

移动端支持热重载，修改代码后按 `r` 即可刷新。

```bash
# 在 Flutter 运行时
r  # 热重载
R  # 热重启
q  # 退出
```

### 调试

#### 移动端调试

```bash
# 使用 Flutter DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

#### 后端调试

在 VS Code 中使用断点调试，或查看控制台日志。

---

## 测试

### 移动端单元测试

```bash
cd mobile
flutter test
```

### 移动端集成测试

```bash
cd mobile
flutter test integration_test/
```

### 后端测试

```bash
cd backend
npm test
```

---

## 常见问题

### Q1: WebSocket 连接失败

**解决方案**：
1. 确认后端服务已启动
2. 检查 WebSocket 端点是否正确（`ws://localhost:3001/ws/markets`）
3. 查看后端日志是否有错误

### Q2: 价格不更新

**解决方案**：
1. 检查 WebSocket 连接状态
2. 查看浏览器/移动端控制台是否有错误
3. 确认后端正在推送数据

### Q3: 性能问题（卡顿）

**解决方案**：
1. 使用 Flutter DevTools 检查性能
2. 确认使用了 `ListView.builder`（懒加载）
3. 使用 Riverpod 的 `select` 精细化订阅

---

## 性能优化建议

1. **使用 `const` 构造函数**：减少不必要的 Widget 重建
2. **使用 `ListView.builder`**：懒加载，提升列表性能
3. **使用 Riverpod `select`**：精细化订阅，只在关心的数据变化时重建
4. **限制数据更新频率**：使用 `throttleTime` 限制 WebSocket 数据流频率
5. **避免在 `build` 方法中创建对象**：将对象创建移到外部

---

## 部署

### 移动端

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

### 后端

```bash
cd backend
npm run build
npm run start:prod
```

---

## 相关文档

- [功能规格](./spec.md)
- [实现计划](./plan.md)
- [技术研究](./research.md)
- [数据模型](./data-model.md)
- [WebSocket API 契约](./contracts/websocket.md)

---

## 下一步

运行 `/speckit.tasks` 生成详细的任务列表（`tasks.md`），开始实现功能。

```
/speckit.tasks specs/001-markets-realtime/spec.md
```

---

**祝开发顺利！** 🚀

