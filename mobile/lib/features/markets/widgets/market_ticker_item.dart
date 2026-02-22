import 'package:flutter/material.dart';
import '../models/market_ticker.dart';
import '../models/market_filter.dart';
import '../screens/market_detail_screen.dart';

/// 行情列表项组件
class MarketTickerItem extends StatelessWidget {
  final MarketTicker ticker;
  final VoidCallback? onTap;

  const MarketTickerItem({
    super.key,
    required this.ticker,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = ticker.isPositive;
    final changeColor = isPositive ? Colors.green : Colors.red;
    final backgroundColor = isPositive 
        ? Colors.green.withOpacity(0.1) 
        : Colors.red.withOpacity(0.1);

    // 获取交易对首字母
    String getInitial() {
      final symbol = ticker.symbol.replaceAll('/', '').replaceAll('USDT', '');
      return symbol.isNotEmpty ? symbol[0] : '?';
    }

    return InkWell(
      onTap: onTap ?? () {
        
        // 默认跳转到详情页
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MarketDetailScreen(
              symbol: ticker.symbol,
              marketType: ticker.symbol.contains('/') 
                  ? MarketType.spot 
                  : MarketType.futures,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // 圆形图标
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  getInitial(),
                  style: TextStyle(
                    color: changeColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            
            // 交易对名称和成交量
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticker.symbol,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Vol ${ticker.formatVolume()}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 8),
            
            // 价格列（竖向排列）
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 实际价格
                Text(
                  ticker.formatPrice(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                // 美元价格
                Text(
                  '\$${ticker.formatPrice()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            
            const SizedBox(width: 8),
            
            // 涨跌幅（带背景容器）
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: changeColor,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                ticker.formattedChange,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

