# 行情详情页面 - 技术实现计划

## 概述

**功能**: 行情详情页面  
**规格文档**: `specs/002-market-detail/spec.md`  
**所属模块**: 行情 (Markets)  
**预计工期**: 5-7 个工作日  
**创建日期**: 2026-02-19

## 宪章检查

### 核心原则对照

#### I. 安全与合规优先 ✅
- 本功能为只读展示页面,不涉及交易操作
- WebSocket 连接复用现有安全机制
- 无敏感数据存储需求

#### II. 交易体验与性能 ✅
- **加载体验**: 实现 Skeleton Screen 占位动画
- **性能目标**: 首屏加载 < 2秒,K线图 60fps 渲染
- **下拉刷新**: 支持下拉刷新功能
- **流畅交互**: K线图支持缩放和拖动,响应流畅

#### III. 领域边界 ✅
- 代码放置在 `lib/features/markets/` 模块
- 复用 `lib/shared/network/` 的 WebSocket 服务
- 复用 `lib/shared/ui/` 的通用组件

#### IV. 可靠性与可观测性 ✅
- WebSocket 断线自动重连
- 错误场景提供友好提示和重试
- 关键操作记录日志

#### V. 规格驱动 ✅
- 已完成功能规格文档
- 本文档为技术实现计划
- 后续生成任务清单

#### VI. 国际化 ✅
- 所有文案通过 `lib/shared/l10n/` 管理
- 支持中英文切换
- 数字和时间格式本地化

### 平台与技术约束 ✅
- Flutter 3.38.1
- 使用 Riverpod 状态管理
- 遵循现有项目结构

## 架构设计

### 1. 目录结构

```
lib/features/markets/
├── screens/
│   ├── markets_screen.dart          # 现有:行情列表
│   └── market_detail_screen.dart    # 新增:行情详情
├── widgets/
│   ├── market_ticker_item.dart      # 现有:行情列表项
│   ├── market_detail_header.dart    # 新增:详情页头部
│   ├── market_stats_card.dart       # 新增:价格统计卡片
│   ├── kline_chart.dart             # 新增:K线图表
│   ├── time_period_selector.dart    # 新增:时间周期选择器
│   └── technical_indicators.dart    # 新增:技术指标
├── models/
│   ├── market_ticker.dart           # 现有:行情数据模型
│   ├── kline_data.dart              # 新增:K线数据模型
│   └── market_detail_info.dart      # 新增:详情信息模型
├── providers/
│   ├── markets_provider.dart        # 现有:行情列表状态
│   ├── market_detail_provider.dart  # 新增:详情页状态
│   └── kline_provider.dart          # 新增:K线数据状态
└── services/
    └── kline_service.dart           # 新增:K线数据服务

lib/shared/ui/
├── skeleton_loader.dart             # 现有:骨架屏
└── chart_loading.dart               # 新增:图表加载动画
```

### 2. 数据模型

#### 2.1 K线数据模型

```dart
class KlineData {
  final DateTime openTime;
  final DateTime closeTime;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  
  KlineData({
    required this.openTime,
    required this.closeTime,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });
  
  factory KlineData.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

#### 2.2 市场详情信息模型

```dart
class MarketDetailInfo {
  final String symbol;
  final String baseCurrency;
  final String quoteCurrency;
  final double minOrderSize;
  final int priceScale;
  final int quantityScale;
  final String? description;
  final String? website;
  final String? whitepaper;
  
  MarketDetailInfo({
    required this.symbol,
    required this.baseCurrency,
    required this.quoteCurrency,
    required this.minOrderSize,
    required this.priceScale,
    required this.quantityScale,
    this.description,
    this.website,
    this.whitepaper,
  });
  
  factory MarketDetailInfo.fromJson(Map<String, dynamic> json);
}
```

#### 2.3 时间周期枚举

```dart
enum KlineInterval {
  min1('1m', '1分'),
  min5('5m', '5分'),
  min15('15m', '15分'),
  min30('30m', '30分'),
  hour1('1h', '1时'),
  hour4('4h', '4时'),
  day1('1d', '1天'),
  week1('1w', '1周');
  
  final String value;
  final String label;
  
  const KlineInterval(this.value, this.label);
}
```

### 3. 状态管理

#### 3.1 市场详情状态

```dart
// 当前选中的交易对
final selectedSymbolProvider = StateProvider<String?>((ref) => null);

// 当前选中的时间周期
final selectedIntervalProvider = StateProvider<KlineInterval>(
  (ref) => KlineInterval.min15,
);

// 市场详情信息
final marketDetailInfoProvider = FutureProvider.family<MarketDetailInfo, String>(
  (ref, symbol) async {
    // 从 API 获取交易对详情信息
    final response = await http.get('/api/market/$symbol');
    return MarketDetailInfo.fromJson(response.data);
  },
);

// 实时价格数据 (复用现有 WebSocket)
final marketTickerProvider = StreamProvider.family<MarketTicker, String>(
  (ref, symbol) {
    final service = ref.watch(webSocketServiceProvider);
    // 订阅单个交易对的实时数据
    return service.subscribeToSymbol(symbol);
  },
);
```

#### 3.2 K线数据状态

```dart
// K线历史数据
final klineHistoryProvider = FutureProvider.family<List<KlineData>, KlineParams>(
  (ref, params) async {
    final service = ref.watch(klineServiceProvider);
    return service.getKlineHistory(
      symbol: params.symbol,
      interval: params.interval,
      limit: 500,
    );
  },
);

// K线实时更新
final klineStreamProvider = StreamProvider.family<KlineData, KlineParams>(
  (ref, params) {
    final service = ref.watch(webSocketServiceProvider);
    return service.subscribeToKline(
      symbol: params.symbol,
      interval: params.interval,
    );
  },
);

// 合并历史和实时数据
final klineDataProvider = Provider.family<AsyncValue<List<KlineData>>, KlineParams>(
  (ref, params) {
    final history = ref.watch(klineHistoryProvider(params));
    final stream = ref.watch(klineStreamProvider(params));
    
    return history.when(
      data: (historyData) {
        return stream.when(
          data: (newKline) {
            // 更新最后一根K线或添加新K线
            final updatedData = [...historyData];
            if (updatedData.isNotEmpty && 
                updatedData.last.openTime == newKline.openTime) {
              updatedData[updatedData.length - 1] = newKline;
            } else {
              updatedData.add(newKline);
            }
            return AsyncValue.data(updatedData);
          },
          loading: () => AsyncValue.data(historyData),
          error: (e, s) => AsyncValue.data(historyData),
        );
      },
      loading: () => const AsyncValue.loading(),
      error: (e, s) => AsyncValue.error(e, s),
    );
  },
);
```

### 4. K线图表实现

#### 4.1 图表库选型

**推荐方案**: 使用 `k_chart` 或 `flutter_candlesticks`

**评估标准**:
- 性能: 支持大量数据点流畅渲染
- 功能: 支持缩放、拖动、指标显示
- 自定义: 可自定义样式和颜色
- 维护: 活跃维护,社区支持好

**备选方案**: 如果第三方库不满足需求,使用 CustomPaint 自绘

#### 4.2 图表组件设计

```dart
class KlineChart extends ConsumerWidget {
  final String symbol;
  final KlineInterval interval;
  
  const KlineChart({
    required this.symbol,
    required this.interval,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final klineData = ref.watch(klineDataProvider(
      KlineParams(symbol: symbol, interval: interval),
    ));
    
    return klineData.when(
      data: (data) => _buildChart(data),
      loading: () => const ChartLoadingWidget(),
      error: (e, s) => _buildError(e),
    );
  }
  
  Widget _buildChart(List<KlineData> data) {
    return InteractiveChart(
      candles: data,
      style: ChartStyle(
        priceGainColor: Colors.green,
        priceLossColor: Colors.red,
        // ... 更多样式配置
      ),
    );
  }
}
```

### 5. WebSocket 扩展

#### 5.1 新增订阅方法

在 `WebSocketService` 中添加:

```dart
// 订阅单个交易对
Stream<MarketTicker> subscribeToSymbol(String symbol) {
  final controller = StreamController<MarketTicker>.broadcast();
  
  // 发送订阅消息
  _channel?.sink.add(jsonEncode({
    'action': 'subscribe',
    'channel': 'market.$symbol',
  }));
  
  // 监听该交易对的数据
  _messageStream
      .where((msg) => msg['channel'] == 'market.$symbol')
      .map((msg) => MarketTicker.fromJson(msg['data']))
      .listen(controller.add);
  
  return controller.stream;
}

// 订阅K线数据
Stream<KlineData> subscribeToKline(String symbol, KlineInterval interval) {
  final controller = StreamController<KlineData>.broadcast();
  
  // 发送订阅消息
  _channel?.sink.add(jsonEncode({
    'action': 'subscribe',
    'channel': 'kline.$symbol.${interval.value}',
  }));
  
  // 监听K线数据
  _messageStream
      .where((msg) => msg['channel'] == 'kline.$symbol.${interval.value}')
      .map((msg) => KlineData.fromJson(msg['data']))
      .listen(controller.add);
  
  return controller.stream;
}

// 取消订阅
void unsubscribe(String channel) {
  _channel?.sink.add(jsonEncode({
    'action': 'unsubscribe',
    'channel': channel,
  }));
}
```

### 6. 页面布局

#### 6.1 整体结构

```dart
class MarketDetailScreen extends ConsumerStatefulWidget {
  final String symbol;
  final MarketType marketType;
  
  const MarketDetailScreen({
    required this.symbol,
    required this.marketType,
  });
  
  @override
  ConsumerState<MarketDetailScreen> createState() => _MarketDetailScreenState();
}

class _MarketDetailScreenState extends ConsumerState<MarketDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pageController = PageController();
    
    // 设置当前选中的交易对
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedSymbolProvider.notifier).state = widget.symbol;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => _tabController.animateTo(index),
              children: [
                _buildPriceTab(),
                _buildInfoTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

#### 6.2 价格 Tab 布局

```dart
Widget _buildPriceTab() {
  return RefreshIndicator(
    onRefresh: _onRefresh,
    child: SingleChildScrollView(
      child: Column(
        children: [
          // 价格统计卡片
          MarketStatsCard(symbol: widget.symbol),
          
          // 时间周期选择器
          TimePeriodSelector(
            selected: ref.watch(selectedIntervalProvider),
            onChanged: (interval) {
              ref.read(selectedIntervalProvider.notifier).state = interval;
            },
          ),
          
          // K线图表
          SizedBox(
            height: 400,
            child: KlineChart(
              symbol: widget.symbol,
              interval: ref.watch(selectedIntervalProvider),
            ),
          ),
          
          // 技术指标
          TechnicalIndicators(
            symbol: widget.symbol,
            interval: ref.watch(selectedIntervalProvider),
          ),
        ],
      ),
    ),
  );
}
```

### 7. 性能优化

#### 7.1 K线图优化

- 使用 `RepaintBoundary` 隔离图表重绘
- 限制可见数据点数量 (例如最多显示 500 根K线)
- 使用 `CustomPaint` 时避免在 `paint` 方法中创建对象
- 缓存计算结果 (如均线、指标等)

#### 7.2 WebSocket 优化

- 页面销毁时取消订阅,释放资源
- 避免重复订阅同一频道
- 使用 `StreamController.broadcast()` 支持多个监听者

#### 7.3 内存优化

- 及时释放不用的 Controller 和 Stream
- 限制历史数据缓存大小
- 使用 `AutoDispose` 自动清理 Provider

### 8. 国际化

#### 8.1 新增文案

在 `lib/shared/l10n/app_zh.arb` 中添加:

```json
{
  "marketDetail": "行情详情",
  "price": "价格",
  "info": "信息",
  "latestPrice": "最新价格",
  "high24h": "24h最高价",
  "low24h": "24h最低价",
  "volume24h": "24h成交量",
  "amount24h": "24h成交额",
  "change24h": "24h涨跌幅",
  "timePeriod": "时间周期",
  "technicalIndicators": "技术指标",
  "marketInfo": "市场信息",
  "tradingPairInfo": "交易对信息",
  "baseCurrency": "基础货币",
  "quoteCurrency": "计价货币",
  "minOrderSize": "最小下单量",
  "priceScale": "价格精度",
  "quantityScale": "数量精度"
}
```

在 `lib/shared/l10n/app_en.arb` 中添加对应英文:

```json
{
  "marketDetail": "Market Detail",
  "price": "Price",
  "info": "Info",
  "latestPrice": "Latest Price",
  "high24h": "24h High",
  "low24h": "24h Low",
  "volume24h": "24h Volume",
  "amount24h": "24h Amount",
  "change24h": "24h Change",
  "timePeriod": "Time Period",
  "technicalIndicators": "Technical Indicators",
  "marketInfo": "Market Info",
  "tradingPairInfo": "Trading Pair Info",
  "baseCurrency": "Base Currency",
  "quoteCurrency": "Quote Currency",
  "minOrderSize": "Min Order Size",
  "priceScale": "Price Scale",
  "quantityScale": "Quantity Scale"
}
```

## 后端 API 需求

### 1. 交易对详情接口

```
GET /api/market/{symbol}

Response:
{
  "symbol": "BTCUSDT",
  "baseCurrency": "BTC",
  "quoteCurrency": "USDT",
  "minOrderSize": 0.001,
  "priceScale": 2,
  "quantityScale": 6,
  "description": "Bitcoin",
  "website": "https://bitcoin.org",
  "whitepaper": "https://bitcoin.org/bitcoin.pdf"
}
```

### 2. K线历史数据接口

```
GET /api/kline/{symbol}?interval=1m&limit=500

Response:
{
  "symbol": "BTCUSDT",
  "interval": "1m",
  "data": [
    {
      "openTime": 1234567890000,
      "closeTime": 1234567950000,
      "open": "45000.00",
      "high": "45100.00",
      "low": "44950.00",
      "close": "45050.00",
      "volume": "123.45"
    }
  ]
}
```

### 3. WebSocket K线订阅

```
// 订阅
{
  "action": "subscribe",
  "channel": "kline.btcusdt.1m"
}

// 推送
{
  "type": "data",
  "channel": "kline.btcusdt.1m",
  "data": {
    "symbol": "BTCUSDT",
    "interval": "1m",
    "openTime": 1234567890000,
    "closeTime": 1234567950000,
    "open": "45000.00",
    "high": "45100.00",
    "low": "44950.00",
    "close": "45050.00",
    "volume": "123.45"
  },
  "timestamp": 1234567890000
}
```

## 测试策略

### 1. 单元测试

- K线数据模型序列化/反序列化
- 时间周期枚举转换
- 数据计算逻辑 (如均线计算)

### 2. Widget 测试

- 页面导航测试
- Tab 切换测试
- 时间周期选择器测试
- 错误状态显示测试

### 3. 集成测试

- WebSocket 订阅和数据接收
- K线数据实时更新
- 页面刷新功能
- 内存泄漏检测

### 4. 手动测试清单

- [ ] 从行情列表跳转到详情页
- [ ] 实时价格更新正常
- [ ] K线图显示正确
- [ ] 时间周期切换正常
- [ ] K线图缩放和拖动流畅
- [ ] Tab 切换流畅
- [ ] 下拉刷新正常
- [ ] 返回按钮正常
- [ ] 网络错误处理正确
- [ ] 中英文切换正常
- [ ] 不同屏幕尺寸适配正常

## 风险与缓解

### 风险1: K线图性能问题

**风险等级**: 高  
**影响**: 大量数据点导致渲染卡顿  
**缓解措施**:
- 限制可见数据点数量
- 使用 RepaintBoundary 隔离重绘
- 选择性能好的图表库
- 必要时使用 Isolate 进行计算

### 风险2: WebSocket 连接不稳定

**风险等级**: 中  
**影响**: 数据更新中断  
**缓解措施**:
- 实现自动重连机制
- 显示连接状态提示
- 提供手动刷新功能
- 缓存最后一次数据

### 风险3: 图表库不满足需求

**风险等级**: 中  
**影响**: 需要自定义实现  
**缓解措施**:
- 提前进行技术选型和 POC
- 准备备选方案 (CustomPaint)
- 预留额外开发时间

### 风险4: 内存泄漏

**风险等级**: 中  
**影响**: 长时间使用后应用卡顿  
**缓解措施**:
- 及时释放资源
- 使用 AutoDispose
- 进行内存泄漏检测
- Code Review 重点关注

## 实施计划

### 第1天: 基础架构

- [ ] 创建目录结构
- [ ] 定义数据模型
- [ ] 实现基础 Provider
- [ ] 添加国际化文案

### 第2天: 页面框架

- [ ] 实现详情页面框架
- [ ] 实现 Tab 切换
- [ ] 实现页面导航
- [ ] 实现 Skeleton Screen

### 第3天: 价格统计

- [ ] 实现价格统计卡片
- [ ] 接入实时价格数据
- [ ] 实现数据格式化
- [ ] 实现涨跌颜色

### 第4天: K线图表

- [ ] 选型和集成图表库
- [ ] 实现 K线图表组件
- [ ] 实现时间周期选择器
- [ ] 接入 K线数据

### 第5天: 实时更新

- [ ] 扩展 WebSocket 服务
- [ ] 实现 K线实时更新
- [ ] 实现订阅管理
- [ ] 测试数据流

### 第6天: 信息 Tab

- [ ] 实现信息 Tab 布局
- [ ] 接入交易对详情 API
- [ ] 实现数据展示
- [ ] 添加外部链接

### 第7天: 优化和测试

- [ ] 性能优化
- [ ] 错误处理完善
- [ ] 编写测试用例
- [ ] 手动测试
- [ ] Bug 修复

## 交付物

1. **代码**:
   - 详情页面及相关组件
   - 数据模型和 Provider
   - WebSocket 扩展
   - 单元测试和 Widget 测试

2. **文档**:
   - API 接口文档更新
   - 组件使用文档
   - 测试报告

3. **演示**:
   - 功能演示视频
   - 性能测试报告

## 后续优化

1. 添加深度图表
2. 添加最近成交记录
3. 支持更多技术指标
4. 支持图表截图分享
5. 添加价格预警功能
6. 支持横屏查看大图
7. 优化图表交互体验

## 参考资料

- 功能规格: `specs/002-market-detail/spec.md`
- WebSocket API: `backend/docs/api/websocket.md`
- 行情模块实现: `specs/001-markets-realtime/plan.md`
- Flutter K线图表库: https://pub.dev/packages/k_chart

