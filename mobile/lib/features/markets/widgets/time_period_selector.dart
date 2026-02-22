import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kline_interval.dart';
import '../providers/market_detail_provider.dart';

/// 时间周期选择器
class TimePeriodSelector extends ConsumerWidget {
  const TimePeriodSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedInterval = ref.watch(selectedIntervalProvider);
    final theme = Theme.of(context);

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: KlineInterval.commonIntervals.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final interval = KlineInterval.commonIntervals[index];
          final isSelected = interval == selectedInterval;

          return _buildIntervalChip(
            context,
            theme,
            interval,
            isSelected,
            () {
              ref.read(selectedIntervalProvider.notifier).state = interval;
            },
          );
        },
      ),
    );
  }

  Widget _buildIntervalChip(
    BuildContext context,
    ThemeData theme,
    KlineInterval interval,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          interval.label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

