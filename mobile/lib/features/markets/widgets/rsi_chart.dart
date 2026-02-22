import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/indicator_config.dart';
import '../models/chart_theme.dart';
import '../providers/indicator_provider.dart';
import '../providers/market_detail_provider.dart';
import '../providers/chart_theme_provider.dart';

/// RSI副图组件
class RSIChart extends ConsumerWidget {
  final String symbol;

  const RSIChart({
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
            'Loading RSI...',
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
            'Calculating RSI...',
            style: TextStyle(color: theme.textColor.withOpacity(0.5)),
          ),
        ),
      );
    }

    if (subConfig is! RSIConfig) {
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
    final rsi = indicatorData.values['rsi'] ?? [];

    return Container(
      padding: const EdgeInsets.all(8),
      color: theme.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 指标标题和图例
          _buildLegend(config, rsi, theme),
          const SizedBox(height: 8),
          // RSI图表
          Expanded(
            child: _RSIPainter(
              rsi: rsi,
              config: config,
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(RSIConfig config, List<double?> rsi, ChartTheme theme) {
    final lastRsi = rsi.lastWhere((v) => v != null, orElse: () => null);

    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'RSI(${config.period})',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: theme.textColor,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: config.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 3),
            Text(
              'RSI: ${lastRsi?.toStringAsFixed(2) ?? '--'}',
              style: TextStyle(
                fontSize: 10,
                color: theme.textColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// RSI绘制组件
class _RSIPainter extends StatelessWidget {
  final List<double?> rsi;
  final RSIConfig config;
  final ChartTheme theme;

  const _RSIPainter({
    required this.rsi,
    required this.config,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RSICustomPainter(
        rsi: rsi,
        config: config,
        theme: theme,
      ),
      child: Container(),
    );
  }
}

/// RSI自定义绘制器
class _RSICustomPainter extends CustomPainter {
  final List<double?> rsi;
  final RSIConfig config;
  final ChartTheme theme;

  _RSICustomPainter({
    required this.rsi,
    required this.config,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (rsi.isEmpty) return;

    // RSI范围固定为0-100
    const minValue = 0.0;
    const maxValue = 100.0;

    // 绘制超买超卖区域
    _drawOverboughtOversoldZones(canvas, size, minValue, maxValue);

    // 绘制参考线
    _drawReferenceLine(canvas, size, config.overbought, minValue, maxValue, theme.upColor.withOpacity(0.3));
    _drawReferenceLine(canvas, size, 50, minValue, maxValue, theme.gridColor);
    _drawReferenceLine(canvas, size, config.oversold, minValue, maxValue, theme.downColor.withOpacity(0.3));

    // 绘制RSI线
    _drawLine(canvas, size, rsi, minValue, maxValue, config.color);
  }

  void _drawOverboughtOversoldZones(Canvas canvas, Size size, double minValue, double maxValue) {
    // 超买区域
    final overboughtPaint = Paint()
      ..color = Colors.red.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    
    final overboughtY = _getY(config.overbought, minValue, maxValue, size.height);
    canvas.drawRect(
      Rect.fromLTRB(0, 0, size.width, overboughtY),
      overboughtPaint,
    );

    // 超卖区域
    final oversoldPaint = Paint()
      ..color = Colors.green.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    
    final oversoldY = _getY(config.oversold, minValue, maxValue, size.height);
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
  bool shouldRepaint(_RSICustomPainter oldDelegate) {
    return oldDelegate.rsi != rsi;
  }
}

