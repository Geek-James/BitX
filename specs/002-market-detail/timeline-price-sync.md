# 分时图价格同步优化

## 版本信息
- 版本：v1.0.0
- 日期：2026-02-22
- 状态：已完成

## 问题描述

分时图之前使用独立的随机数据生成逻辑，导致分时图的价格与以下数据源不一致：
- 订单薄价格
- 深度图价格
- 最新成交价格
- 当前市场价格

这种不一致性会给用户造成困惑，影响交易决策。

## 解决方案

### 核心思路

使用 `MarketDataCoordinator` 作为统一的价格源，确保所有数据模块使用相同的价格基准。

### 实现细节

#### 1. 数据源统一

**修改前：**
```dart
// 独立生成随机价格
double basePrice = 50000 + random.nextDouble() * 10000;
final priceChange = (random.nextDouble() - 0.5) * lastPrice * 0.001;
final newPrice = lastPrice + priceChange;
```

**修改后：**
```dart
// 从协调器获取统一价格
final wsService = ref.read(webSocketServiceProvider);
final coordinator = wsService.coordinator;
final currentPrice = coordinator.getCurrentPrice(widget.symbol);
```

#### 2. 历史数据生成优化

**策略：**
- 开盘价设为当前价格的 95%-105% 范围
- 最后 10 个数据点逐渐向当前价格收敛
- 确保最后一个点的价格等于当前市场价格

**代码实现：**
```dart
void _generateInitialData(coordinator) {
  // 从协调器获取当前价格
  final currentPrice = coordinator.getCurrentPrice(widget.symbol);
  
  // 开盘价在当前价格附近
  double basePrice = currentPrice * (0.95 + random.nextDouble() * 0.1);
  
  for (int i = 0; i < pointCount; i++) {
    // 最后10个点向当前价格收敛
    if (i >= pointCount - 10) {
      final progress = (i - (pointCount - 10)) / 10.0;
      final targetChange = (currentPrice - basePrice) * progress * 0.3;
      final randomChange = (random.nextDouble() - 0.5) * basePrice * 0.001;
      basePrice += targetChange + randomChange;
    } else {
      // 正常波动
      final priceChange = (random.nextDouble() - 0.5) * basePrice * 0.002;
      basePrice += priceChange;
    }
    
    _dataPoints.add(TimelinePoint(
      timestamp: timestamp,
      price: basePrice,
      volume: 100 + random.nextDouble() * 500,
    ));
  }
  
  // 强制最后一个点等于当前价格
  if (_dataPoints.isNotEmpty) {
    final lastPoint = _dataPoints.last;
    _dataPoints[_dataPoints.length - 1] = TimelinePoint(
      timestamp: lastPoint.timestamp,
      price: currentPrice,
      volume: lastPoint.volume,
    );
  }
}
```

#### 3. 实时更新优化

**修改前：**
```dart
// 基于上一个价格随机波动
final lastPrice = _dataPoints.last.price;
final priceChange = (random.nextDouble() - 0.5) * lastPrice * 0.001;
final newPrice = lastPrice + priceChange;
```

**修改后：**
```dart
// 直接使用协调器的当前价格
final newPrice = coordinator.getCurrentPrice(widget.symbol);
```

#### 4. 成交触发动画

监听实时成交流，当有新成交时触发水花动画：

```dart
void _subscribeToTrades(WebSocketService wsService) {
  _tradeSubscription = wsService.tradesStream.listen((data) {
    final channel = data['channel'] as String?;
    final expectedChannel = 'trades.${widget.symbol}';
    
    if (channel == expectedChannel) {
      // 成交时触发水花动画
      if (mounted) {
        setState(() {
          _showRipple = true;
          _rippleController.forward(from: 0);
        });
      }
    }
  });
  
  wsService.subscribeTrades(widget.symbol);
}
```

## 技术架构

### 数据流向

```
MarketDataCoordinator (统一价格源)
         ↓
    ┌────┴────┬────────┬──────────┐
    ↓         ↓        ↓          ↓
  分时图   订单薄   深度图   成交记录
```

### 价格同步机制

1. **初始化阶段**
   - 从协调器获取当前价格
   - 生成历史数据时确保最后价格等于当前价格

2. **运行阶段**
   - 定时器每 3 秒从协调器获取最新价格
   - 订阅成交流，成交时触发动画
   - 所有模块共享同一个协调器实例

3. **价格更新流程**
   ```
   协调器更新价格
        ↓
   生成成交记录 → 触发成交流 → 分时图动画
        ↓
   更新订单薄
        ↓
   更新深度图
   ```

## 代码变更

### 修改文件
- `lib/features/markets/widgets/timeline_chart.dart`

### 新增依赖
```dart
import '../providers/market_detail_provider.dart';
import '../../../shared/network/websocket_service.dart';
import 'dart:async';
```

### 新增成员变量
```dart
StreamSubscription? _tradeSubscription;
Timer? _updateTimer;
```

### 生命周期管理
```dart
@override
void dispose() {
  _rippleController.dispose();
  _tradeSubscription?.cancel();
  _updateTimer?.cancel();
  super.dispose();
}
```

## 测试验证

### 验证点

1. **价格一致性**
   - [ ] 分时图最新价格 = 订单薄最优价格
   - [ ] 分时图最新价格 = 最新成交价格
   - [ ] 分时图最新价格 = 深度图中心价格

2. **动画效果**
   - [ ] 成交时触发水花动画
   - [ ] 每 3 秒更新价格并触发动画
   - [ ] 动画不影响价格显示

3. **性能表现**
   - [ ] 内存占用稳定（数据点限制在 300 个）
   - [ ] CPU 占用正常
   - [ ] 无内存泄漏

## 优势

1. **数据一致性**
   - 所有价格数据来自同一个源
   - 避免了不同模块价格不一致的问题

2. **代码可维护性**
   - 价格生成逻辑集中在协调器
   - 各模块只负责展示，不负责生成

3. **用户体验**
   - 价格变化连贯自然
   - 成交动画实时响应
   - 数据可信度提升

## 后续优化

1. **性能优化**
   - 考虑使用防抖减少更新频率
   - 优化大数据量时的渲染性能

2. **功能增强**
   - 支持自定义时间范围
   - 支持缩放和拖动
   - 添加十字线和详情提示

3. **数据精度**
   - 接入真实 API 后验证价格精度
   - 优化价格波动算法

## 相关文档

- [分时图实现文档](./timeline-chart-implementation.md)
- [K线优化方案](./kline-optimization-plan.md)
- [WebSocket 修复文档](../../WEBSOCKET_FIX.md)

