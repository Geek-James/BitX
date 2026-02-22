import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/indicator_config.dart';
import '../models/chart_theme.dart';
import '../providers/indicator_provider.dart';
import '../providers/market_detail_provider.dart';
import '../providers/chart_theme_provider.dart';
import 'dart:math' as math;

/// MACD副图组件
class MACDChart extends ConsumerWidget {
  final String symbol;

  const MACDChart({
    super.key,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedInterval = ref.watch(selectedIntervalProvider);
    final indicatorData = ref.watch(subIndicatorDataProvider((symbol, selectedInterval)));
    final klineData = ref.watch(klineDataListProvider((symbol, selectedInterval)));
    final config = ref.watch(subIndicatorConfigProvider) as MACDConfig;
    final theme = ref.watch(chartThemeProvider);

    if (indicatorData == null || klineData.isEmpty) {
      return const SizedBox.shrink();
    }

    final dif = indicatorData.values['dif'] ?? [];
    final dea = indicatorData.values['dea'] ?? [];
    final macd = indicatorData.values['macd'] ?? [];

    return Container(
      padding: const EdgeInsets.all(8),
      color: theme.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 指标标题和图例
          _buildLegend(config, dif, dea, macd, theme),
          const SizedBox(height: 8),
          // MACD图表
          Expanded(
            child: _MACDPainter(
              dif: dif,
              dea: dea,
              macd: macd,
              config: config,
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(MACDConfig config, List<double?> dif, List<double?> dea, List<double?> macd, ChartTheme theme) {
    // 获取最后一个有效值
    final lastDif = dif.lastWhere((v) => v != null, orElse: () => null);
    final lastDea = dea.lastWhere((v) => v != null, orElse: () => null);
    final lastMacd = macd.lastWhere((v) => v != null, orElse: () => null);

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'MACD(${config.fastPeriod},${config.slowPeriod},${config.signalPeriod})',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        _buildLegendItem('DIF', lastDif, config.difColor, theme),
        _buildLegendItem('DEA', lastDea, config.deaColor, theme),
        _buildLegendItem('MACD', lastMacd, config.macdColor, theme),
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

/// MACD绘制组件
class _MACDPainter extends StatelessWidget {
  final List<double?> dif;
  final List<double?> dea;
  final List<double?> macd;
  final MACDConfig config;
  final ChartTheme theme;

  const _MACDPainter({
    required this.dif,
    required this.dea,
    required this.macd,
    required this.config,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MACDCustomPainter(
        dif: dif,
        dea: dea,
        macd: macd,
        config: config,
        theme: theme,
      ),
      child: Container(),
    );
  }
}

/// MACD自定义绘制器
class _MACDCustomPainter extends CustomPainter {
  final List<double?> dif;
  final List<double?> dea;
  final List<double?> macd;
  final MACDConfig config;
  final ChartTheme theme;

  _MACDCustomPainter({
    required this.dif,
    required this.dea,
    required this.macd,
    required this.config,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dif.isEmpty || dea.isEmpty || macd.isEmpty) return;

    // 计算数据范围
    double maxValue = double.negativeInfinity;
    double minValue = double.infinity;

    for (int i = 0; i < dif.length; i++) {
      if (dif[i] != null) {
        maxValue = math.max(maxValue, dif[i]!);
        minValue = math.min(minValue, dif[i]!);
      }
      if (dea[i] != null) {
        maxValue = math.max(maxValue, dea[i]!);
        minValue = math.min(minValue, dea[i]!);
      }
      if (macd[i] != null) {
        maxValue = math.max(maxValue, macd[i]!);
        minValue = math.min(minValue, macd[i]!);
      }
    }

    // 添加边距
    final range = maxValue - minValue;
    maxValue += range * 0.1;
    minValue -= range * 0.1;

    if (maxValue == minValue) {
      maxValue = 1;
      minValue = -1;
    }

    // 绘制零轴线
    final zeroY = _getY(0, minValue, maxValue, size.height);
    final zeroPaint = Paint()
      ..color = theme.gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, zeroY),
      Offset(size.width, zeroY),
      zeroPaint,
    );

    // 绘制MACD柱状图
    _drawMACDHistogram(canvas, size, minValue, maxValue);

    // 绘制DIF线
    _drawLine(canvas, size, dif, minValue, maxValue, config.difColor);

    // 绘制DEA线
    _drawLine(canvas, size, dea, minValue, maxValue, config.deaColor);
  }

  void _drawMACDHistogram(Canvas canvas, Size size, double minValue, double maxValue) {
    final barWidth = size.width / macd.length * 0.6;

    for (int i = 0; i < macd.length; i++) {
      if (macd[i] == null) continue;

      final x = (i + 0.5) * size.width / macd.length;
      final zeroY = _getY(0, minValue, maxValue, size.height);
      final valueY = _getY(macd[i]!, minValue, maxValue, size.height);

      final paint = Paint()
        ..color = macd[i]! >= 0 ? theme.upColor : theme.downColor
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTRB(
          x - barWidth / 2,
          math.min(zeroY, valueY),
          x + barWidth / 2,
          math.max(zeroY, valueY),
        ),
        paint,
      );
    }
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
  bool shouldRepaint(_MACDCustomPainter oldDelegate) {
    return oldDelegate.dif != dif ||
        oldDelegate.dea != dea ||
        oldDelegate.macd != macd;
  }
}

