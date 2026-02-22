# K线图表手势测试指南

## 问题诊断

如果手势不生效,可能的原因:

### 1. ScrollView 冲突
**问题**: K线图表在 `SingleChildScrollView` 中,垂直滚动会拦截水平手势
**解决方案**: 已调整布局结构,使用 `Column` + `Expanded` 包裹

### 2. 数据不足
**问题**: 如果K线数据点太少,缩放和拖动可能不明显
**解决方案**: 确保生成了足够的数据点 (当前是100个)

### 3. 图表未加载
**问题**: 如果图表还在加载状态,手势不会响应
**解决方案**: 等待加载完成后再测试

## 测试步骤

### 步骤 1: 确认图表已加载
1. 打开应用
2. 点击任意交易对进入详情页
3. 等待K线图表加载完成 (不再显示加载动画)
4. 确认能看到完整的K线图表

### 步骤 2: 测试水平拖动
1. 用单根手指触摸图表
2. 向左滑动 (查看更早的历史数据)
3. 向右滑动 (回到最新数据)
4. **预期效果**: 图表应该跟随手指移动

### 步骤 3: 测试双指缩放
1. 用两根手指同时触摸图表
2. 向外拉伸 (放大)
3. 向内收缩 (缩小)
4. **预期效果**: K线的宽度应该变化

### 步骤 4: 测试长按
1. 长按图表任意位置
2. **预期效果**: 应该显示十字线和详细数据
3. 保持长按并拖动
4. **预期效果**: 十字线应该跟随移动

## 调试技巧

### 检查数据
```dart
// 在 kline_chart.dart 中添加日志
print('Candles count: ${candles.length}');
print('First candle: ${candles.first.date}');
print('Last candle: ${candles.last.date}');
```

### 检查手势响应
```dart
// 在 Candlesticks 外包裹 GestureDetector 测试
GestureDetector(
  onTap: () => print('Chart tapped'),
  onLongPress: () => print('Chart long pressed'),
  child: Candlesticks(...),
)
```

### 检查布局
```dart
// 确保图表有固定高度
SizedBox(
  height: 400, // 固定高度
  child: Candlesticks(...),
)
```

## 常见问题

### Q1: 只能垂直滚动,不能水平拖动
**A**: 这是因为外层的 `SingleChildScrollView` 拦截了手势。解决方案:
- 使用 `physics: const NeverScrollableScrollPhysics()` 禁用滚动
- 或者将图表移到滚动视图外

### Q2: 双指缩放不灵敏
**A**: 可能是数据点太少。解决方案:
- 增加数据点数量 (当前是100个)
- 确保数据时间跨度足够大

### Q3: 长按没有反应
**A**: 可能是手势被其他组件拦截。解决方案:
- 确保图表上方没有透明的覆盖层
- 检查是否有其他 GestureDetector 拦截

## 当前实现状态

### 布局结构
```
Column
└── Expanded
    └── RefreshIndicator
        └── SingleChildScrollView
            └── Column
                ├── MarketStatsCard (可滚动)
                ├── TimePeriodSelector (可滚动)
                └── KlineChart (固定高度 400)
                    └── Candlesticks (内置手势)
```

### 手势处理
- **水平拖动**: Candlesticks 内置处理
- **双指缩放**: Candlesticks 内置处理
- **长按**: Candlesticks 内置处理
- **垂直滚动**: SingleChildScrollView 处理

## 优化建议

### 方案 1: 禁用外层滚动
```dart
SingleChildScrollView(
  physics: const NeverScrollableScrollPhysics(), // 禁用滚动
  child: Column(...),
)
```

### 方案 2: 使用 CustomScrollView
```dart
CustomScrollView(
  slivers: [
    SliverToBoxAdapter(child: MarketStatsCard()),
    SliverToBoxAdapter(child: TimePeriodSelector()),
    SliverToBoxAdapter(
      child: SizedBox(
        height: 400,
        child: KlineChart(), // 独立手势区域
      ),
    ),
  ],
)
```

### 方案 3: 分离布局
```dart
Column(
  children: [
    Expanded(
      child: SingleChildScrollView(
        child: Column([
          MarketStatsCard(),
          TimePeriodSelector(),
        ]),
      ),
    ),
    SizedBox(
      height: 400,
      child: KlineChart(), // 不在滚动视图中
    ),
  ],
)
```

## 下一步

如果手势仍然不生效,请尝试:
1. 热重启应用 (按 `R` 键)
2. 检查 candlesticks 库版本
3. 查看库的官方示例
4. 考虑更换其他K线图表库

