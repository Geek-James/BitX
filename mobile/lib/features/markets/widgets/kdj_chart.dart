import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/indicator_config.dart';
import '../models/chart_theme.dart';
import '../providers/indicator_provider.dart';
import '../providers/market_detail_provider.dart';
import '../providers/chart_theme_provider.dart';
import 'dart:math' as math;

/// KDJ副图组件
class KDJChart extends ConsumerWidget {
  final String symbol;

  const KDJChart({
    super.key,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedInterval = ref.watch(selectedIntervalProvider);
    final indicatorData = ref.watch(subIndicatorDataProvider((symbol, selectedInterval)));
    final klineData = ref.watch(klineDataListProvider((symbol, selectedInterval)));
    final subConfig = ref.watch(subIndicatorConfigProvider);
    final theme = ref.watch(chartThemeProvider);

    if (klineData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(8),
        color: theme.backgroundColor,
        child: Center(
          child: Text(
            'Loading KDJ...',
            style: TextStyle(color: theme.textColor.withOpacity(0.5)),
          ),
        ),
      );
    }

    if (indicatorData == null) {
      return Container(
        padding: const EdgeInsets.all(8),
        color: theme.backgroundColor,
        child: Center(
          child: Text(
            'Calculating KDJ...',
            style: TextStyle(color: theme.textColor.withOpacity(0.5)),
          ),
        ),
      );
    }

    if (subConfig is! KDJConfig) {
      return Container(
        padding: const EdgeInsets.all(8),
        color: theme.backgroundColor,
        child: Center(
          child: Text(
            'Wrong indicator type',
            style: TextStyle(color: theme.textColor.withOpacity(0.5)),
          ),
        ),
      );
    }

    final config = subConfig;
    final k = indicatorData.values['k'] ?? [];
    final d = indicatorData.values['d'] ?? [];
    final j = indicatorData.values['j'] ?? [];

    return Container(
      padding: const EdgeInsets.all(8),
      color: theme.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 指标标题和图例
          _buildLegend(config, k, d, j, theme),
          const SizedBox(height: 8),
          // KDJ图表
          Expanded(
            child: _KDJPainter(
              k: k,
              d: d,
              j: j,
              config: config,
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(KDJConfig config, List<double?> k, List<double?> d, List<double?> j, ChartTheme theme) {
    final lastK = k.lastWhere((v) => v != null, orElse: () => null);
    final lastD = d.lastWhere((v) => v != null, orElse: () => null);
    final lastJ = j.lastWhere((v) => v != null, orElse: () => null);

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'KDJ(${config.period})',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        _buildLegendItem('K', lastK, config.kColor, theme),
        _buildLegendItem('D', lastD, config.dColor, theme),
        _buildLegendItem('J', lastJ, config.jColor, theme),
      ],
    );
  }

  Widget _buildLegendItem(String label, double? value, Color color, ChartTheme theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          '$label: ${value?.toStringAsFixed(2) ?? '--'}',
          style: TextStyle(
            fontSize: 10,
            color: theme.textColor.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

/// KDJ绘制组件
class _KDJPainter extends StatelessWidget {
  final List<double?> k;
  final List<double?> d;
  final List<double?> j;
  final KDJConfig config;
  final ChartTheme theme;

  const _KDJPainter({
    required this.k,
    required this.d,
    required this.j,
    required this.config,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _KDJCustomPainter(
        k: k,
        d: d,
        j: j,
        config: config,
        theme: theme,
      ),
      child: Container(),
    );
  }
}

/// KDJ自定义绘制器
class _KDJCustomPainter extends CustomPainter {
  final List<double?> k;
  final List<double?> d;
  final List<double?> j;
  final KDJConfig config;
  final ChartTheme theme;

  _KDJCustomPainter({
    required this.k,
    required this.d,
    required this.j,
    required this.config,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (k.isEmpty || d.isEmpty || j.isEmpty) return;

    // 计算数据范围
    double maxValue = double.negativeInfinity;
    double minValue = double.infinity;

    for (int i = 0; i < k.length; i++) {
      if (k[i] != null) {
        maxValue = math.max(maxValue, k[i]!);
        minValue = math.min(minValue, k[i]!);
      }
      if (d[i] != null) {
        maxValue = math.max(maxValue, d[i]!);
        minValue = math.min(minValue, d[i]!);
      }
      if (j[i] != null) {
        maxValue = math.max(maxValue, j[i]!);
        minValue = math.min(minValue, j[i]!);
      }
    }

    // 确保范围至少包含0-100
    maxValue = math.max(maxValue, 100);
    minValue = math.min(minValue, 0);

    // 添加边距
    final range = maxValue - minValue;
    maxValue += range * 0.1;
    minValue -= range * 0.1;

    // 绘制超买超卖区域
    _drawOverboughtOversoldZones(canvas, size, minValue, maxValue);

    // 绘制参考线
    _drawReferenceLine(canvas, size, 80, minValue, maxValue, theme.upColor.withOpacity(0.3));
    _drawReferenceLine(canvas, size, 50, minValue, maxValue, theme.gridColor);
    _drawReferenceLine(canvas, size, 20, minValue, maxValue, theme.downColor.withOpacity(0.3));

    // 绘制K、D、J线
    _drawLine(canvas, size, k, minValue, maxValue, config.kColor);
    _drawLine(canvas, size, d, minValue, maxValue, config.dColor);
    _drawLine(canvas, size, j, minValue, maxValue, config.jColor);
  }

  void _drawOverboughtOversoldZones(Canvas canvas, Size size, double minValue, double maxValue) {
    // 超买区域 (>80)
    final overboughtPaint = Paint()
      ..color = Colors.red.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    
    final overboughtY = _getY(80, minValue, maxValue, size.height);
    canvas.drawRect(
      Rect.fromLTRB(0, 0, size.width, overboughtY),
      overboughtPaint,
    );

    // 超卖区域 (<20)
    final oversoldPaint = Paint()
      ..color = Colors.green.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    
    final oversoldY = _getY(20, minValue, maxValue, size.height);
    canvas.drawRect(
      Rect.fromLTRB(0, oversoldY, size.width, size.height),
      oversoldPaint,
    );
  }

  void _drawReferenceLine(Canvas canvas, Size size, double value, double minValue, double maxValue, Color color) {
    final y = _getY(value, minValue, maxValue, size.height);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      paint,
    );
  }

  void _drawLine(
    Canvas canvas,
    Size size,
    List<double?> values,
    double minValue,
    double maxValue,
    Color color,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    bool started = false;

    for (int i = 0; i < values.length; i++) {
      if (values[i] == null) {
        started = false;
        continue;
      }

      final x = (i + 0.5) * size.width / values.length;
      final y = _getY(values[i]!, minValue, maxValue, size.height);

      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  double _getY(double value, double minValue, double maxValue, double height) {
    return height - (value - minValue) / (maxValue - minValue) * height;
  }

  @override
  bool shouldRepaint(_KDJCustomPainter oldDelegate) {
    return oldDelegate.k != k ||
        oldDelegate.d != d ||
        oldDelegate.j != j;
  }
}

