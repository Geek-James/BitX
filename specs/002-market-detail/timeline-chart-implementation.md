# 分时图功能实现 - 总结文档

## 实现时间
2026-02-22

## 一、功能概述

在K线图的时间轴上新增"分时"选项，通过实时数据进行绘制，当前价格显示为一个小点，每3秒添加新数据点时触发水花动画效果。

## 二、核心功能

### 2.1 分时图组件

**文件**: `mobile/lib/features/markets/widgets/timeline_chart.dart`

**主要特性**:
1. 实时价格线绘制
2. 均价线显示（黄色）
3. 渐变填充效果
4. 当前价格点标记
5. 水花动画效果（每3秒触发）
6. 价格标签显示（含涨跌幅）
7. 时间轴显示

### 2.2 数据结构

```dart
class TimelinePoint {
  final DateTime timestamp;  // 时间戳
  final double price;         // 价格
  final double volume;        // 成交量
}
```

### 2.3 动画实现

**水花动画**:
```dart
// 动画控制器（1.5秒）
_rippleController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 1500),
);

// 绘制3个水花圆圈（延迟扩散）
for (int i = 0; i < 3; i++) {
  final delay = i * 0.15;
  final rippleProgress = (progress - delay) / (1 - delay);
  final radius = 6 + rippleProgress * 20;
  final opacity = (1 - rippleProgress) * 0.5;
  
  canvas.drawCircle(
    currentPoint,
    radius,
    Paint()..color = color.withOpacity(opacity)..strokeWidth = 2,
  );
}
```

**效果**:
- 3个同心圆依次扩散
- 半径从6px扩大到26px
- 透明度从0.5渐变到0
- 总时长1.5秒

## 三、技术实现

### 3.1 初始数据生成

```dart
void _generateInitialData() {
  final startTime = DateTime(now.year, now.month, now.day, 9, 30); // 9:30开盘
  final minutesSinceOpen = now.difference(startTime).inMinutes;
  final pointCount = min(minutesSinceOpen, 240); // 最多240个点（4小时）
  
  // 生成从开盘到现在的数据点（每分钟一个点）
  for (int i = 0; i < pointCount; i++) {
    final timestamp = startTime.add(Duration(minutes: i));
    final priceChange = (random - 0.5) * basePrice * 0.002;
    basePrice += priceChange;
    
    _dataPoints.add(TimelinePoint(...));
  }
}
```

### 3.2 实时数据更新

```dart
void _addDataPointWithRipple() {
  // 1. 生成新数据点
  final newPrice = lastPrice + priceChange;
  _dataPoints.add(TimelinePoint(...));
  
  // 2. 限制数据点数量（最多300个）
  if (_dataPoints.length > 300) {
    _dataPoints.removeAt(0);
  }
  
  // 3. 触发水花动画
  _showRipple = true;
  _rippleController.forward(from: 0);
  
  // 4. 3秒后添加下一个数据点
  Future.delayed(const Duration(seconds: 3), _addDataPointWithRipple);
}
```

### 3.3 价格线绘制

```dart
void _drawPriceLine(Canvas canvas, Size size, ...) {
  // 1. 绘制价格线
  final linePath = Path();
  for (int i = 0; i < dataPoints.length; i++) {
    final x = size.width * i / (dataPoints.length - 1);
    final y = _getY(dataPoints[i].price, minPrice, maxPrice, size.height);
    if (i == 0) {
      linePath.moveTo(x, y);
    } else {
      linePath.lineTo(x, y);
    }
  }
  canvas.drawPath(linePath, linePaint);
  
  // 2. 绘制渐变填充
  final fillPath = Path.from(linePath);
  fillPath.lineTo(size.width, size.height);
  fillPath.lineTo(0, size.height);
  fillPath.close();
  
  final gradient = LinearGradient(
    colors: [
      lineColor.withOpacity(0.3),
      lineColor.withOpacity(0.05),
    ],
  );
  canvas.drawPath(fillPath, fillPaint);
}
```

### 3.4 当前价格点

```dart
void _drawCurrentPricePoint(Canvas canvas, ...) {
  final lastPoint = dataPoints.last;
  final x = size.width;
  final y = _getY(lastPoint.price, ...);
  
  // 外圈（白色）
  canvas.drawCircle(Offset(x, y), 6, Paint()..color = Colors.white);
  
  // 内圈（涨跌颜色）
  canvas.drawCircle(Offset(x, y), 4, Paint()..color = color);
}
```

### 3.5 均价线计算

```dart
void _drawAverageLine(Canvas canvas, ...) {
  double sum = 0;
  for (int i = 0; i < dataPoints.length; i++) {
    sum += dataPoints[i].price;
    final avgPrice = sum / (i + 1);  // 累计平均价
    // 绘制均价线点
  }
}
```

## 四、界面集成

### 4.1 时间周期选择器

**修改**: `mobile/lib/features/markets/models/kline_interval.dart`

```dart
enum KlineInterval {
  timeline('timeline', '分时'),  // 新增
  min1('1m', '1分'),
  min5('5m', '5分'),
  // ...
}
```

### 4.2 市场详情页

**修改**: `mobile/lib/features/markets/screens/market_detail_screen.dart`

```dart
Widget _buildPriceTab() {
  final selectedInterval = ref.watch(selectedIntervalProvider);
  final isTimeline = selectedInterval == KlineInterval.timeline;
  
  return Column(
    children: [
      // 时间周期选择器
      Row(
        children: [
          const Expanded(child: TimePeriodSelector()),
          // 分时图不显示指标选择器
          if (!isTimeline) const IndicatorSelector(),
        ],
      ),
      
      // 根据选择显示K线图或分时图
      Expanded(
        child: isTimeline
            ? TimelineChart(symbol: widget.symbol)
            : Column(
                children: [
                  CustomKlineChart(...),
                  SubChartContainer(...),
                ],
              ),
      ),
    ],
  );
}
```

## 五、视觉效果

### 5.1 分时图布局

```
┌─────────────────────────────────────────────┐
│  价格线（涨绿/跌红）                         │
│    ╱╲                                       │
│   ╱  ╲    ╱╲                               │
│  ╱    ╲  ╱  ╲                              │
│ ╱      ╲╱    ╲                             │
│╱              ╲                            │
│  渐变填充区域   ╲                          │
│                 ╲                          │
│  均价线（黄色）   ╲                        │
│  ─ ─ ─ ─ ─ ─ ─ ─ ─                        │
│                    ╲                       │
│                     ●  ← 当前价格点        │
│                      ◯◯◯ ← 水花动画        │
└─────────────────────────────────────────────┘
  9:30        12:00        15:30  ← 时间轴
```

### 5.2 颜色方案

| 元素 | 颜色 | 说明 |
|------|------|------|
| 价格线 | 涨绿/跌红 | 相对开盘价 |
| 填充渐变 | 半透明 | 0.3 → 0.05 |
| 均价线 | 黄色 | Colors.yellow[700] |
| 当前价格点 | 白色+涨跌色 | 外白内彩 |
| 水花动画 | 涨跌色 | 半透明扩散 |
| 价格标签 | 涨跌色 | 含涨跌幅 |

### 5.3 动画效果

**水花扩散**:
```
t=0.0s:  ●
t=0.5s:  ●◯
t=1.0s:  ●◯◯
t=1.5s:  ●◯◯◯ (消失)
```

## 六、性能优化

### 6.1 数据量控制

```dart
// 限制最多300个数据点
if (_dataPoints.length > 300) {
  _dataPoints.removeAt(0);
}
```

### 6.2 动画优化

```dart
// 使用CustomPainter的repaint参数
TimelineChartPainter(...) : super(repaint: rippleAnimation);

// 只在必要时重绘
@override
bool shouldRepaint(TimelineChartPainter oldDelegate) {
  return oldDelegate.dataPoints != dataPoints ||
      oldDelegate.showRipple != showRipple;
}
```

### 6.3 裁剪区域

```dart
// 设置裁剪区域，避免超出边界
canvas.save();
canvas.clipRect(Rect.fromLTWH(0, 0, chartWidth, size.height));
// 绘制图表
canvas.restore();
```

## 七、使用说明

### 7.1 切换到分时图

1. 打开行情详情页
2. 点击时间周期选择器
3. 选择"分时"选项
4. 自动切换到分时图显示

### 7.2 观察水花动画

1. 等待3秒
2. 新数据点添加时自动触发
3. 3个同心圆依次扩散
4. 1.5秒后动画结束

### 7.3 查看价格信息

- **右侧价格标签**: 显示5个价格点及涨跌幅
- **底部时间轴**: 显示开盘、中间、当前时间
- **当前价格点**: 图表最右侧的彩色圆点
- **均价线**: 黄色虚线，显示累计平均价

## 八、后续优化方向

### 8.1 功能增强

1. **成交量柱状图**
   - 在底部显示成交量
   - 与价格线联动

2. **更多时间范围**
   - 支持选择不同日期
   - 查看历史分时数据

3. **十字光标**
   - 长按显示详细信息
   - 查看任意时间点的价格

### 8.2 交互优化

1. **缩放功能**
   - 双指缩放查看细节
   - 左右滑动查看历史

2. **实时更新频率**
   - 可配置更新间隔
   - 支持1秒、3秒、5秒

3. **动画自定义**
   - 可选择不同的动画效果
   - 调整动画速度

### 8.3 数据优化

1. **真实数据接入**
   - 连接WebSocket实时数据
   - 替换模拟数据生成

2. **数据缓存**
   - 缓存历史分时数据
   - 减少重复请求

3. **数据压缩**
   - 对历史数据进行抽样
   - 减少内存占用

## 九、总结

通过本次实现，成功添加了分时图功能：

✅ **分时图组件**: 完整的分时图绘制功能  
✅ **实时数据**: 每3秒自动添加新数据点  
✅ **当前价格点**: 彩色圆点标记最新价格  
✅ **水花动画**: 3个同心圆扩散效果（1.5秒）  
✅ **均价线**: 黄色线显示累计平均价  
✅ **渐变填充**: 半透明渐变填充效果  
✅ **价格标签**: 右侧显示价格和涨跌幅  
✅ **时间轴**: 底部显示时间信息  
✅ **界面集成**: 与K线图无缝切换  

### 核心亮点

1. **水花动画**: 3个同心圆依次扩散，视觉效果出色
2. **实时更新**: 每3秒自动添加数据并触发动画
3. **性能优化**: 数据量控制、动画优化、裁剪区域
4. **无缝切换**: 分时图与K线图一键切换

现在用户可以在时间周期选择器中选择"分时"，查看实时价格走势，每3秒会有新的数据点添加，并伴随漂亮的水花动画效果！

---

**实现完成**: ✅  
**测试验证**: 待进行  
**文档更新**: ✅

