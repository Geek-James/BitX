# K线图价格显示优化 - 实施总结

## 优化时间
2026-02-22

## 一、优化需求

1. **右侧价格标签优化**：给右边价格留出空间，避免被遮挡
2. **显示更多价格**：每条网格线上都显示价格标签
3. **支持Y轴缩放**：上下滑动可以压缩或放大价格区间
4. **K线图联动**：价格区间变化时，K线图也要相应变化

## 二、核心改进

### 2.1 预留右侧空间

**修改前**：
- 价格标签直接绘制在图表右边缘
- 容易被K线或指标线遮挡
- 显示空间不足

**修改后**：
```dart
// 为右侧价格标签预留60像素空间
const rightPadding = 60.0;
final chartWidth = size.width - rightPadding;

// K线和指标只在图表区域绘制
_drawCandles(canvas, Size(chartWidth, size.height), ...);
_drawMainIndicators(canvas, Size(chartWidth, size.height), ...);

// 价格标签绘制在预留区域
textPainter.paint(
  canvas,
  Offset(chartWidth + 8, y - textPainter.height / 2),
);
```

**效果**：
- ✅ 价格标签有独立的显示区域
- ✅ 不会被K线遮挡
- ✅ 显示更清晰

### 2.2 显示更多价格标签

**修改前**：
- 只显示3个价格（最高、中间、最低）
- 价格间隔太大，不够精细

**修改后**：
```dart
// 显示8个价格标签，覆盖整个价格区间
final labelCount = 8;
final priceStep = priceRange / (labelCount - 1);

for (int i = 0; i < labelCount; i++) {
  final price = maxPrice - (priceStep * i);
  final y = size.height * i / (labelCount - 1);
  
  // 绘制价格文本
  textPainter.text = TextSpan(text: price.toStringAsFixed(2), ...);
  textPainter.paint(canvas, Offset(chartWidth + 8, y - ...));
  
  // 绘制对应的价格线（虚线）
  _drawDashedLine(canvas, Offset(0, y), Offset(chartWidth, y), ...);
}
```

**效果**：
- ✅ 显示8个价格标签（可调整）
- ✅ 每个价格标签对应一条网格线
- ✅ 价格分布更均匀

### 2.3 支持Y轴缩放（价格区间调整）

**新增功能**：
```dart
// 添加价格缩放状态
double _priceScale = 1.0; // 价格缩放比例（Y轴）
Offset? _lastPanPosition; // 上次拖动位置

// 手势处理
onScaleUpdate: (details) {
  if (details.pointerCount == 2) {
    // 双指缩放：同时缩放X轴和Y轴
    _scale = (_scale * scaleDelta).clamp(0.5, 3.0);
    _priceScale = (_priceScale * scaleDelta).clamp(0.5, 3.0);
  } else if (details.pointerCount == 1) {
    // 单指上下拖动：调整价格缩放
    final dy = details.focalPoint.dy - _lastPanPosition!.dy;
    final sensitivity = 0.002;
    _priceScale = (_priceScale * (1 - dy * sensitivity)).clamp(0.5, 3.0);
  }
}
```

**价格区间计算**：
```dart
// 应用价格缩放
final priceRange = maxPrice - minPrice;
final centerPrice = (maxPrice + minPrice) / 2;
final scaledRange = priceRange / priceScale;

// 以中心价格为基准进行缩放
maxPrice = centerPrice + scaledRange / 2;
minPrice = centerPrice - scaledRange / 2;
```

**效果**：
- ✅ 单指上下滑动：调整价格区间
- ✅ 向上滑动：放大价格区间（看到更多价格范围）
- ✅ 向下滑动：压缩价格区间（聚焦当前价格）
- ✅ 双指缩放：同时缩放X轴和Y轴
- ✅ 缩放范围：0.5x - 3.0x

### 2.4 十字光标价格标签优化

**修改前**：
- 十字光标的价格标签显示在右侧
- 可能遮挡右侧的价格标签

**修改后**：
```dart
// 十字光标的价格标签显示在左侧
final priceBoxRect = RRect.fromRectAndRadius(
  Rect.fromCenter(
    center: Offset(textPainter.width / 2 + 4, y),
    width: textPainter.width + 8,
    height: 16,
  ),
  const Radius.circular(4),
);

// 绘制在左侧
textPainter.paint(canvas, Offset(8, y - textPainter.height / 2));
```

**效果**：
- ✅ 十字光标价格标签在左侧
- ✅ 不遮挡右侧的价格标签
- ✅ 信息显示更清晰

## 三、使用说明

### 3.1 基本操作

**查看价格**：
- 右侧显示8个价格标签
- 每个价格对应一条网格线
- 价格均匀分布在整个区间

**调整价格区间**：
- 单指上下滑动：调整Y轴缩放
- 向上滑动：放大价格区间
- 向下滑动：压缩价格区间

**缩放K线图**：
- 双指捏合/拉伸：同时缩放X轴和Y轴
- X轴：调整可见K线数量（20-200根）
- Y轴：调整价格区间（0.5x-3.0x）

**查看详细信息**：
- 长按K线：显示十字光标
- 左侧显示当前价格
- 顶部显示详细信息（OHLC、涨跌幅、成交量）

### 3.2 手势说明

| 手势 | 功能 | 效果 |
|------|------|------|
| 单指上下滑动 | 调整价格区间 | 放大/压缩Y轴 |
| 双指捏合 | 缩小 | X轴和Y轴同时缩小 |
| 双指拉伸 | 放大 | X轴和Y轴同时放大 |
| 长按 | 显示十字光标 | 查看详细信息 |
| 长按移动 | 移动十字光标 | 查看不同K线 |

## 四、技术细节

### 4.1 布局结构

```
┌─────────────────────────────────────────────┐
│                                             │
│  ┌──────────────────────┐  ┌──────────┐   │
│  │                      │  │ 50025.00 │   │
│  │                      │  ├──────────┤   │
│  │                      │  │ 50020.00 │   │
│  │    K线图表区域       │  ├──────────┤   │
│  │   (chartWidth)       │  │ 50015.00 │   │
│  │                      │  ├──────────┤   │
│  │                      │  │ 50010.00 │   │
│  │                      │  ├──────────┤   │
│  │                      │  │ 50005.00 │   │
│  └──────────────────────┘  └──────────┘   │
│                                             │
│  图表区域              价格标签区域(60px)   │
└─────────────────────────────────────────────┘
```

### 4.2 价格缩放算法

```dart
// 1. 计算原始价格范围
final priceRange = maxPrice - minPrice;

// 2. 计算中心价格
final centerPrice = (maxPrice + minPrice) / 2;

// 3. 应用缩放（以中心为基准）
final scaledRange = priceRange / priceScale;
maxPrice = centerPrice + scaledRange / 2;
minPrice = centerPrice - scaledRange / 2;

// 4. 添加边距（5%）
final adjustedRange = maxPrice - minPrice;
maxPrice += adjustedRange * 0.05;
minPrice -= adjustedRange * 0.05;
```

**原理**：
- 以价格区间的中心点为基准进行缩放
- 保持中心价格不变
- 上下边界等比例调整
- 避免价格偏移

### 4.3 价格标签分布

```dart
// 计算价格间隔
final labelCount = 8;
final priceStep = priceRange / (labelCount - 1);

// 从最高价到最低价均匀分布
for (int i = 0; i < labelCount; i++) {
  final price = maxPrice - (priceStep * i);
  final y = size.height * i / (labelCount - 1);
  // 绘制价格标签和网格线
}
```

**特点**：
- 价格标签数量可配置（当前8个）
- 均匀分布在整个高度
- 每个价格对应一条网格线

### 4.4 手势灵敏度

```dart
// 单指拖动灵敏度
final sensitivity = 0.002;
_priceScale = (_priceScale * (1 - dy * sensitivity)).clamp(0.5, 3.0);

// 双指缩放灵敏度
final scaleDelta = details.scale / _lastScaleValue;
_priceScale = (_priceScale * scaleDelta).clamp(0.5, 3.0);
```

**调整建议**：
- `sensitivity`：控制单指拖动的灵敏度（0.001-0.005）
- 值越大，拖动效果越明显
- 值越小，拖动更精细

## 五、优化效果

### 5.1 视觉效果

**修改前**：
- ❌ 只有3个价格标签
- ❌ 价格标签可能被遮挡
- ❌ 价格区间固定，无法调整

**修改后**：
- ✅ 显示8个价格标签
- ✅ 价格标签有独立区域，不被遮挡
- ✅ 支持上下滑动调整价格区间
- ✅ K线图随价格区间变化

### 5.2 交互体验

| 功能 | 修改前 | 修改后 |
|------|--------|--------|
| 价格标签数量 | 3个 | 8个 |
| 价格标签位置 | 图表内 | 独立区域 |
| 价格区间调整 | ❌ 不支持 | ✅ 支持 |
| Y轴缩放 | ❌ 不支持 | ✅ 0.5x-3.0x |
| 手势操作 | 仅双指缩放 | 单指+双指 |

### 5.3 实用性提升

1. **价格查看更方便**
   - 8个价格标签覆盖整个区间
   - 快速定位价格位置
   - 不需要估算

2. **价格区间可调整**
   - 聚焦当前价格：压缩价格区间
   - 查看更大范围：放大价格区间
   - 灵活适应不同需求

3. **显示更清晰**
   - 价格标签不被遮挡
   - 独立的显示区域
   - 视觉效果更好

## 六、后续优化方向

### 6.1 功能增强

1. **自适应价格标签数量**
   - 根据图表高度自动调整
   - 小屏幕：5-6个标签
   - 大屏幕：8-10个标签

2. **智能价格格式化**
   - 根据价格大小调整小数位数
   - BTC：2位小数
   - 小币：4-6位小数

3. **价格区间记忆**
   - 记住用户的缩放偏好
   - 切换交易对时保持缩放比例

### 6.2 交互优化

1. **双击重置**
   - 双击图表重置缩放
   - 恢复默认价格区间

2. **缩放指示器**
   - 显示当前缩放比例
   - 例如："1.5x"

3. **价格区间提示**
   - 显示当前价格区间
   - 例如："49500 - 50500"

## 七、总结

通过本次优化，成功实现了：

✅ **右侧价格显示优化**：预留60像素空间，价格标签不被遮挡  
✅ **显示更多价格**：从3个增加到8个，覆盖整个价格区间  
✅ **支持Y轴缩放**：单指上下滑动调整价格区间（0.5x-3.0x）  
✅ **K线图联动**：价格区间变化时，K线图自动调整  
✅ **交互体验提升**：支持单指和双指手势，操作更灵活  

### 核心改进

1. **布局优化**：图表区域和价格标签区域分离
2. **价格缩放**：支持Y轴独立缩放，以中心为基准
3. **价格标签**：显示8个均匀分布的价格标签
4. **手势增强**：单指调整Y轴，双指同时缩放X/Y轴

现在K线图的价格显示更清晰，用户可以灵活调整价格区间，查看不同范围的价格变化！

---

**优化完成**: ✅  
**测试验证**: 待进行  
**文档更新**: ✅

