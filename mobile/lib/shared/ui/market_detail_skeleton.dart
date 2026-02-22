import 'package:flutter/material.dart';

/// 市场详情页骨架屏
class MarketDetailSkeleton extends StatelessWidget {
  const MarketDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 价格统计区域骨架
          _buildStatsSection(),
          
          const SizedBox(height: 16),
          
          // 时间周期选择器骨架
          _buildTimePeriodSection(),
          
          const SizedBox(height: 16),
          
          // K线图骨架
          _buildChartSection(),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmer(width: 150, height: 32),
                    const SizedBox(height: 8),
                    _buildShimmer(width: 120, height: 16),
                  ],
                ),
              ),
              _buildShimmer(width: 80, height: 28),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmer(width: 80, height: 12),
                    const SizedBox(height: 4),
                    _buildShimmer(width: 100, height: 16),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmer(width: 80, height: 12),
                    const SizedBox(height: 4),
                    _buildShimmer(width: 100, height: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmer(width: 100, height: 12),
                    const SizedBox(height: 4),
                    _buildShimmer(width: 80, height: 16),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShimmer(width: 100, height: 12),
                    const SizedBox(height: 4),
                    _buildShimmer(width: 80, height: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimePeriodSection() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 7,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return _buildShimmer(width: 50, height: 32);
        },
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      height: 400,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: _buildShimmer(width: double.infinity, height: 400),
    );
  }

  Widget _buildShimmer({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

