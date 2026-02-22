import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/market_filter.dart';
import '../models/market_ticker.dart';
import '../providers/market_detail_provider.dart';
import '../providers/markets_provider.dart';
import '../providers/order_book_provider.dart';
import '../widgets/market_stats_card.dart';
import '../widgets/time_period_selector.dart';
import '../widgets/custom_kline_chart.dart';
import '../widgets/timeline_chart.dart';
import '../widgets/market_info_tab.dart';
import '../widgets/indicator_selector.dart';
import '../widgets/sub_chart_container.dart';
import '../widgets/order_book_widget.dart';
import '../widgets/depth_chart_widget.dart';
import '../widgets/trades_widget.dart';
import '../models/kline_interval.dart';
import 'chart_theme_settings_screen.dart';
import 'multi_chart_screen.dart';

/// 行情详情页面
class MarketDetailScreen extends ConsumerStatefulWidget {
  final String symbol;
  final MarketType marketType;

  const MarketDetailScreen({
    super.key,
    required this.symbol,
    required this.marketType,
  });

  @override
  ConsumerState<MarketDetailScreen> createState() =>
      _MarketDetailScreenState();
}

class _MarketDetailScreenState extends ConsumerState<MarketDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pageController = PageController();
    _tabController.addListener(_onTabChanged);

    // 设置当前选中的交易对
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedSymbolProvider.notifier).state = widget.symbol;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _pageController.animateToPage(
        _tabController.index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    _tabController.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: _buildAppBar(l10n),
      body: Column(
        children: [
          // Tab切换区域 (固定在顶部)
          _buildTabBar(l10n),
          
          // Tab内容区域 (可滚动)
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                _buildPriceTab(),
                _buildTradeTab(),
                _buildInfoTab(),
              ],
            ),
          ),
          
          // 底部操作栏
          _buildBottomBar(),
        ],
      ),
    );
  }
  
  /// 构建底部操作栏
  Widget _buildBottomBar() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 更多按钮
            Expanded(
              child: _buildBottomButton(
                icon: Icons.apps,
                label: l10n.more,
                onTap: () {
                  // TODO: 实现更多功能
                },
              ),
            ),
            
            // 通知按钮
            Expanded(
              child: _buildBottomButton(
                icon: Icons.notifications_outlined,
                label: l10n.notifications,
                onTap: () {
                  // TODO: 实现通知功能
                },
              ),
            ),
            
            // 交易按钮 (突出显示)
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: 跳转到交易页面
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    l10n.trade,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建底部按钮
  Widget _buildBottomButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.black),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    return AppBar(
      title: GestureDetector(
        onTap: () => _showSymbolPicker(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                widget.symbol,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 20),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: widget.marketType == MarketType.futures
                    ? Colors.orange.withOpacity(0.2)
                    : Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.marketType == MarketType.futures ? '永续' : '现货',
                style: TextStyle(
                  fontSize: 11,
                  color: widget.marketType == MarketType.futures
                      ? Colors.orange
                      : Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.compare_arrows),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MultiChartScreen(),
              ),
            );
          },
          tooltip: '多图表对比',
        ),
        IconButton(
          icon: const Icon(Icons.palette),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChartThemeSettingsScreen(),
              ),
            );
          },
          tooltip: '主题设置',
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            // TODO: 实现分享功能
          },
        ),
      ],
    );
  }

  Widget _buildTabBar(AppLocalizations l10n) {
    return Container(
      height: 48,
      alignment: Alignment.centerLeft,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorSize: TabBarIndicatorSize.label,
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        tabs: [
          Tab(text: l10n.price),
          Tab(text: l10n.trade),
          Tab(text: l10n.info),
        ],
      ),
    );
  }

  Widget _buildPriceTab() {
    final selectedInterval = ref.watch(selectedIntervalProvider);
    final isTimeline = selectedInterval == KlineInterval.timeline;

    return Column(
      children: [
        // 价格统计卡片
        MarketStatsCard(symbol: widget.symbol),
        
        const SizedBox(height: 10),
        
        // 时间周期选择器和指标选择器
        Row(
          children: [
            const Expanded(child: TimePeriodSelector()),
            // 分时图不显示指标选择器
            if (!isTimeline) const IndicatorSelector(),
            const SizedBox(width: 8),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // 根据选择显示K线图或分时图
        Expanded(
          child: isTimeline
              ? TimelineChart(symbol: widget.symbol)
              : Column(
                  children: [
                    // 主图 - K线图表
                    Expanded(
                      flex: 7,
                      child: CustomKlineChart(symbol: widget.symbol),
                    ),
                    // 副图 - 技术指标
                    Expanded(
                      flex: 3,
                      child: SubChartContainer(symbol: widget.symbol),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildInfoTab() {
    return MarketInfoTab(symbol: widget.symbol);
  }

  /// 构建交易Tab
  Widget _buildTradeTab() {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // 子Tab栏
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: TabBar(
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey[600],
              indicatorSize: TabBarIndicatorSize.label,
              tabs: [
                Tab(text: l10n.orderBook),
                Tab(text: l10n.depthChart),
                Tab(text: l10n.latestTrades),
              ],
            ),
          ),
          // 子Tab内容
          Expanded(
            child: TabBarView(
              children: [
                OrderBookWidget(symbol: widget.symbol),
                _buildDepthChartTab(),
                TradesWidget(symbol: widget.symbol),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建深度图Tab
  Widget _buildDepthChartTab() {
    final l10n = AppLocalizations.of(context)!;
    final orderBookState = ref.watch(orderBookProvider(widget.symbol));

    if (orderBookState.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 8),
            Text(l10n.loading),
          ],
        ),
      );
    }

    if (orderBookState.error != null) {
      return Center(
        child: Text(
          '${l10n.loadingFailed}: ${orderBookState.error}',
          style: TextStyle(color: Colors.red[300]),
        ),
      );
    }

    final orderBook = orderBookState.orderBook;
    if (orderBook == null) {
      return Center(child: Text(l10n.noData));
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          // 深度图
          DepthChartWidget(orderBook: orderBook, height: 250),
          const SizedBox(height: 24),
          // 订单薄摘要
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.orderBookSummary,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow(l10n.bestBid, orderBook.bestBid?.toStringAsFixed(2) ?? '-', Colors.green),
                _buildSummaryRow(l10n.bestAsk, orderBook.bestAsk?.toStringAsFixed(2) ?? '-', Colors.red),
                _buildSummaryRow(l10n.spread, orderBook.spread?.toStringAsFixed(2) ?? '-', Colors.grey[600]!),
                _buildSummaryRow(l10n.midPrice, orderBook.midPrice?.toStringAsFixed(2) ?? '-', Colors.grey[800]!),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// 构建摘要行
  Widget _buildSummaryRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 显示交易对选择器
  void _showSymbolPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SymbolPickerSheet(
        currentSymbol: widget.symbol,
        marketType: widget.marketType,
        onSymbolSelected: (symbol) {
          Navigator.pop(context);
          // 跳转到新的交易对详情页
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MarketDetailScreen(
                symbol: symbol,
                marketType: widget.marketType,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 交易对选择器弹窗
class _SymbolPickerSheet extends ConsumerStatefulWidget {
  final String currentSymbol;
  final MarketType marketType;
  final ValueChanged<String> onSymbolSelected;

  const _SymbolPickerSheet({
    required this.currentSymbol,
    required this.marketType,
    required this.onSymbolSelected,
  });

  @override
  ConsumerState<_SymbolPickerSheet> createState() => _SymbolPickerSheetState();
}

class _SymbolPickerSheetState extends ConsumerState<_SymbolPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tickersAsync = ref.watch(rawTickersProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 顶部拖动条
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

    

          // 搜索框
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16,vertical: 5),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchTradingPair,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toUpperCase());
              },
            ),
          ),

          // const SizedBox(height: 16),

          // 交易对列表
          Expanded(
            child: tickersAsync.when(
              data: (tickers) {
                // 过滤交易对
                final filteredTickers = tickers.where((t) {
                  if (_searchQuery.isEmpty) return true;
                  final ticker = t as MarketTicker;
                  return ticker.symbol.contains(_searchQuery);
                }).toList();

                if (filteredTickers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noMatchingPairs,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredTickers.length,
                  itemBuilder: (context, index) {
                    final ticker = filteredTickers[index] as MarketTicker;
                    final isSelected = ticker.symbol == widget.currentSymbol;
                    final isPositive = ticker.isPositive;
                    final changeColor = isPositive ? Colors.green : Colors.red;

                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: Colors.blue[50],
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            ticker.symbol.substring(0, 1),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Text(
                            ticker.symbol,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.check_circle, size: 16, color: Colors.blue[700]),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        '${l10n.volume24hLabel}: ${ticker.formatVolume()}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            ticker.formatPrice(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: changeColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ticker.formattedChange,
                            style: TextStyle(
                              fontSize: 12,
                              color: changeColor,
                            ),
                          ),
                        ],
                      ),
                      onTap: () => widget.onSymbolSelected(ticker.symbol),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('${l10n.loadingFailed}: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

