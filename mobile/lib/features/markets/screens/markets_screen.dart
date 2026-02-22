import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/market_filter.dart';
import '../models/websocket_connection_state.dart';
import '../providers/markets_provider.dart';
import '../widgets/market_ticker_item.dart';
import '../../../shared/ui/skeleton_loader.dart';

/// 行情页面
class MarketsScreen extends ConsumerStatefulWidget {
  const MarketsScreen({super.key});

  @override
  ConsumerState<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends ConsumerState<MarketsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pageController = PageController();
    _tabController.addListener(_onTabChanged);

    // 连接 WebSocket
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(webSocketServiceProvider).connect();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      // Tab 点击时同步 PageView
      _pageController.animateToPage(
        _tabController.index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _updateMarketType(_tabController.index);
    }
  }

  void _onPageChanged(int index) {
    // PageView 滑动时同步 TabBar
    _tabController.animateTo(index);
    _updateMarketType(index);
  }

  void _updateMarketType(int index) {
    final marketType = index == 0 ? MarketType.futures : MarketType.spot;
    ref.read(marketFilterProvider.notifier).updateMarketType(marketType);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final connectionState = ref.watch(connectionStateProvider);
    final filter = ref.watch(marketFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.markets),
      ),
      body: Column(
        children: [
          // 连接状态提示
          _buildConnectionStatus(connectionState, l10n),

          // 自定义 TabBar - 居左且可滑动
          _buildCustomTabBar(l10n),

          // 搜索框
          // _buildSearchBar(filter, l10n),

          // 筛选按钮
          // _buildFilterButtons(filter, l10n),

          // 可滑动的行情列表
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                // 永续合约页面
                _buildMarketListPage(MarketType.futures, l10n),
                // 现货页面
                _buildMarketListPage(MarketType.spot, l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建自定义 TabBar
  Widget _buildCustomTabBar(AppLocalizations l10n) {
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
          Tab(text: l10n.futures),
          Tab(text: l10n.spot),
        ],
      ),
    );
  }

  /// 构建行情列表页面
  Widget _buildMarketListPage(MarketType marketType, AppLocalizations l10n) {
    final filteredTickers = ref.watch(filteredTickersProvider);
    
    return _buildMarketList(filteredTickers, l10n);
  }

  /// 构建连接状态提示
  Widget _buildConnectionStatus(
      AsyncValue<WebSocketConnectionState> state, AppLocalizations l10n) {
    return state.when(
      data: (connectionState) {
        if (connectionState.status == ConnectionStatus.connecting) {
          return Container(
            padding: const EdgeInsets.all(8),
            color: Colors.orange.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(l10n.connecting),
              ],
            ),
          );
        } else if (connectionState.status == ConnectionStatus.error) {
          return Container(
            padding: const EdgeInsets.all(8),
            color: Colors.red.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 16, color: Colors.red),
                const SizedBox(width: 8),
                Text(l10n.networkError),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    ref.read(webSocketServiceProvider).retry();
                  },
                  child: Text(l10n.retry),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// 构建搜索框
  Widget _buildSearchBar(MarketFilter filter, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: l10n.searchHint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: filter.hasSearch
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(marketFilterProvider.notifier).clearSearch();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: (value) {
          ref.read(marketFilterProvider.notifier).updateSearchQuery(value);
        },
      ),
    );
  }

  /// 构建筛选按钮
  Widget _buildFilterButtons(MarketFilter filter, AppLocalizations l10n) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip(l10n.defaultLabel, SortType.default_, filter.sortBy),
          const SizedBox(width: 8),
          _buildFilterChip(l10n.topGainers, SortType.topGainers, filter.sortBy),
          const SizedBox(width: 8),
          _buildFilterChip(l10n.topLosers, SortType.topLosers, filter.sortBy),
          const SizedBox(width: 8),
          _buildFilterChip(l10n.volumeRank, SortType.volume, filter.sortBy),
        ],
      ),
    );
  }

  /// 构建筛选芯片
  Widget _buildFilterChip(String label, SortType sortType, SortType current) {
    final isSelected = sortType == current;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        ref.read(marketFilterProvider.notifier).updateSortBy(sortType);
      },
    );
  }

  /// 构建行情列表
  Widget _buildMarketList(
      AsyncValue<List<dynamic>> tickers, AppLocalizations l10n) {
    return tickers.when(
      data: (data) {
        if (data.isEmpty) {
          return Center(
            child: Text(l10n.noData),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // 重新连接 WebSocket
            ref.read(webSocketServiceProvider).disconnect();
            await ref.read(webSocketServiceProvider).connect();
          },
          child: ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final ticker = data[index];
              return MarketTickerItem(
                ticker: ticker,
                // 不传 onTap,使用默认的跳转逻辑
              );
            },
          ),
        );
      },
      loading: () => const MarketListSkeleton(),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('${l10n.loading}: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(webSocketServiceProvider).retry();
              },
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

