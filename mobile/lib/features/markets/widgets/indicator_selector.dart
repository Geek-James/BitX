import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/indicator_config.dart';
import '../providers/indicator_provider.dart';

/// 指标选择器
class IndicatorSelector extends ConsumerWidget {
  const IndicatorSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      icon: const Icon(Icons.show_chart, size: 20),
      onPressed: () {
        _showIndicatorBottomSheet(context, ref);
      },
      tooltip: l10n.technicalIndicator,
    );
  }

  void _showIndicatorBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _IndicatorBottomSheet(),
    );
  }
}

class _IndicatorBottomSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final mainIndicators = ref.watch(mainIndicatorsProvider);
    final subIndicatorType = ref.watch(subIndicatorTypeProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.technicalIndicator,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 主图指标
          Text(
            l10n.mainIndicators,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(mainIndicators.length, (index) {
              final indicator = mainIndicators[index];
              return _buildIndicatorChip(
                context,
                ref,
                label: indicator.displayName,
                isSelected: indicator.enabled,
                color: _getIndicatorColor(indicator),
                onTap: () => toggleMainIndicator(ref, index),
              );
            }),
          ),
          
          const SizedBox(height: 24),
          
          // 副图指标
          Text(
            l10n.subIndicators,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildIndicatorChip(
                context,
                ref,
                label: 'MACD',
                isSelected: subIndicatorType == IndicatorType.macd,
                onTap: () => switchSubIndicator(ref, IndicatorType.macd),
              ),
              _buildIndicatorChip(
                context,
                ref,
                label: 'RSI',
                isSelected: subIndicatorType == IndicatorType.rsi,
                onTap: () => switchSubIndicator(ref, IndicatorType.rsi),
              ),
              _buildIndicatorChip(
                context,
                ref,
                label: 'KDJ',
                isSelected: subIndicatorType == IndicatorType.kdj,
                onTap: () => switchSubIndicator(ref, IndicatorType.kdj),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 底部安全区域
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildIndicatorChip(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required bool isSelected,
    Color? color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: color != null
              ? Border.all(color: color, width: 2)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color? _getIndicatorColor(IndicatorConfig indicator) {
    if (indicator is MAConfig) {
      return indicator.color;
    } else if (indicator is EMAConfig) {
      return indicator.color;
    }
    return null;
  }
}

