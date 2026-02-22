# 图表手势隔离方案

## 问题描述
图表手势和顶部的价格/信息Tab会互相影响,导致手势冲突

## 原因分析

### 之前的布局结构
```
Column
└── TabBar
└── Expanded
    └── PageView (可左右滑动)
        ├── 价格Tab
        │   ├── MarketStatsCard
        │   ├── TimePeriodSelector
        │   └── KlineChart (手势被PageView拦截)
        └── 信息Tab
```

**问题**:
1. K线图表在 PageView 内部
2. PageView 的左右滑动手势会拦截图表的拖动手势
3. Tab切换时图表会重新构建

## 解决方案

### 新的布局结构
```
Column
├── MarketStatsCard (固定顶部)
├── TimePeriodSelector (固定)
├── Expanded (flex: 3)
│   └── KlineChart (独立区域,不受Tab影响)
├── TabBar (价格/信息切换)
└── Expanded (flex: 2)
    └── PageView (禁用滑动)
        ├── 价格详情Tab
        └── 信息详情Tab
```

**优势**:
1. ✅ K线图表完全独立,不在 PageView 中
2. ✅ 图表手势不会被 Tab 切换拦截
3. ✅ Tab 切换不会影响图表状态
4. ✅ 图表始终可见,方便对比查看
5. ✅ PageView 禁用滑动,只能通过点击Tab切换

## 布局比例

### 屏幕空间分配
- **价格统计卡片**: 自适应高度 (~120px)
- **时间周期选择器**: 固定高度 (40px)
- **K线图表**: 60% 剩余空间 (flex: 3)
- **Tab内容**: 40% 剩余空间 (flex: 2)

### 调整建议
如果需要调整比例,修改 flex 值:

```dart
// 图表占更多空间
Expanded(
  flex: 4,  // 增加到4
  child: KlineChart(...),
),

// Tab内容占更少空间
Expanded(
  flex: 1,  // 减少到1
  child: PageView(...),
),
```

## 手势隔离机制

### 1. 图表区域
- **位置**: 独立的 Expanded 容器
- **手势**: 完全由 Candlesticks 库处理
- **不受影响**: Tab切换、PageView滑动

### 2. Tab区域
- **位置**: 底部独立的 Expanded 容器
- **手势**: PageView 滑动已禁用
- **切换方式**: 只能点击 Tab 标签

### 3. 手势优先级
```
用户触摸屏幕
    ↓
在图表区域? 
    ├─ 是 → Candlesticks 处理 (缩放/拖动/长按)
    └─ 否 → 其他组件处理
```

## 代码实现

### 关键配置

#### 1. PageView 禁用滑动
```dart
PageView(
  controller: _pageController,
  physics: const NeverScrollableScrollPhysics(), // 禁用滑动
  children: [...],
)
```

#### 2. 图表独立容器
```dart
Expanded(
  flex: 3,
  child: KlineChart(symbol: widget.symbol), // 不在PageView中
),
```

#### 3. Tab切换逻辑
```dart
void _onTabChanged() {
  if (!_tabController.indexIsChanging) {
    _pageController.animateToPage(
      _tabController.index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
```

## 用户体验

### 优点
1. **图表始终可见**: 切换Tab时图表不会消失
2. **手势流畅**: 图表缩放、拖动不受干扰
3. **状态保持**: 图表的缩放级别和位置不会丢失
4. **清晰分区**: 图表和详情信息分离明确

### 缺点
1. **屏幕空间**: 图表和Tab内容共享屏幕,可能显得拥挤
2. **滚动限制**: Tab内容区域较小,可能需要滚动

### 优化建议
如果屏幕空间不够:
- 可以添加"全屏图表"按钮
- 或者支持隐藏Tab内容区域
- 或者使用底部抽屉(BottomSheet)显示详情

## 测试验证

### 测试步骤
1. 打开详情页,等待图表加载
2. **测试图表手势**:
   - 双指缩放图表
   - 单指拖动图表
   - 长按查看详情
3. **测试Tab切换**:
   - 点击"价格"Tab
   - 点击"信息"Tab
   - 观察图表是否保持状态
4. **测试手势隔离**:
   - 在图表区域滑动,不应触发Tab切换
   - 在Tab区域滑动,不应影响图表

### 预期结果
- ✅ 图表手势流畅,不卡顿
- ✅ Tab切换不影响图表状态
- ✅ 图表缩放级别保持不变
- ✅ 没有手势冲突

## 后续优化

### 方案 1: 可折叠Tab区域
```dart
AnimatedContainer(
  height: _isTabExpanded ? 200 : 0,
  child: PageView(...),
)
```

### 方案 2: 底部抽屉
```dart
DraggableScrollableSheet(
  initialChildSize: 0.3,
  minChildSize: 0.1,
  maxChildSize: 0.7,
  builder: (context, scrollController) {
    return PageView(...);
  },
)
```

### 方案 3: 全屏图表模式
```dart
IconButton(
  icon: Icon(Icons.fullscreen),
  onPressed: () {
    // 隐藏Tab区域,图表占满屏幕
  },
)
```

## 总结

通过将K线图表从 PageView 中独立出来,成功实现了手势隔离:
- 图表手势不受Tab切换影响
- Tab切换不会重建图表
- 用户体验更流畅
- 代码结构更清晰

