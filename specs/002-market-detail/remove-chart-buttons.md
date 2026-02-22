# K线图表按钮移除方案

## 问题
candlesticks 库显示了放大缩小按钮,无法通过配置完全移除

## 已尝试的方案

### 方案 1: actions 参数
```dart
Candlesticks(
  candles: candles,
  actions: const [], // 传空数组
)
```
**结果**: 待测试

### 方案 2: Stack 覆盖
```dart
Stack(
  children: [
    Candlesticks(...),
    Positioned(top: 0, child: Container(...)), // 覆盖按钮
  ],
)
```
**结果**: ❌ 会留下空白区域

## 备选图表库

如果 candlesticks 无法移除按钮,可以考虑以下替代方案:

### 方案 A: interactive_chart
```yaml
dependencies:
  interactive_chart: ^2.0.0
```

**优点**:
- 更灵活的配置
- 可以完全自定义UI
- 没有默认按钮

**缺点**:
- 需要更多代码实现
- 文档较少

**示例**:
```dart
InteractiveChart(
  candles: candles,
  style: ChartStyle(
    // 完全自定义样式
  ),
)
```

### 方案 B: fl_chart
```yaml
dependencies:
  fl_chart: ^0.66.0
```

**优点**:
- 功能强大
- 高度可定制
- 社区活跃

**缺点**:
- 需要手动实现K线逻辑
- 代码量较大

**示例**:
```dart
LineChart(
  LineChartData(
    // 手动绘制K线
  ),
)
```

### 方案 C: 自定义 CustomPainter
```dart
class KlineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 完全自定义绘制K线
  }
}
```

**优点**:
- 完全控制
- 性能最优
- 无第三方依赖

**缺点**:
- 开发工作量大
- 需要处理所有手势
- 需要实现所有功能

## 推荐方案

### 短期方案
继续使用 candlesticks,接受按钮的存在:
- 按钮不影响核心功能
- 用户可以选择使用或不使用
- 节省开发时间

### 长期方案
如果必须移除按钮,建议:
1. **优先**: 尝试联系 candlesticks 库作者,提交 PR 添加配置选项
2. **备选**: 切换到 interactive_chart (配置更灵活)
3. **最后**: 使用 CustomPainter 自己实现

## 当前状态

已添加 `actions: const []` 参数,等待测试结果。

如果仍然显示按钮,说明这个参数不是用来控制工具栏按钮的,可能需要:
- 查看库的源码
- 寻找其他配置参数
- 或者接受按钮的存在

## 测试步骤

1. 热重载应用 (按 `r` 键)
2. 进入详情页查看图表
3. 检查顶部是否还有按钮
4. 如果还有,考虑备选方案

## 决策建议

**如果按钮不影响使用**:
- 保持现状,专注于核心功能开发
- 按钮可以作为额外的交互方式

**如果必须移除**:
- 评估切换图表库的成本
- 考虑开发时间 vs 用户体验
- 可以在后续版本中优化

