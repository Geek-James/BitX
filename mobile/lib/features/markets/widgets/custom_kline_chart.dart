import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kline_data.dart';
import '../models/chart_theme.dart';
import '../models/indicator_config.dart';
import '../providers/market_detail_provider.dart';
import '../providers/chart_theme_provider.dart';
import '../providers/indicator_provider.dart';
import 'dart:math' as math;

/// 自定义K线图表组件（支持主图指标和缩放）
class CustomKlineChart extends ConsumerStatefulWidget {
  final String symbol;

  const CustomKlineChart({
    super.key,
    required this.symbol,
  });

  @override
  ConsumerState<CustomKlineChart> createState() => _CustomKlineChartState();
}

class _CustomKlineChartState extends ConsumerState<CustomKlineChart> {
  double _scale = 1.0; // 缩放比例（X轴）
  int _visibleCount = 50; // 可见K线数量
  double _lastScaleValue = 1.0; // 上次缩放值
  double _priceScale = 1.0; // 价格缩放比例（Y轴）
  Offset? _crosshairPosition; // 十字光标位置
  int? _selectedIndex; // 选中的K线索引
  DateTime? _crosshairHideTime; // 十字光标隐藏时间
  Offset? _lastPanPosition; // 上次拖动位置

  @override
  Widget build(BuildContext context) {
    final selectedInterval = ref.watch(selectedIntervalProvider);
    final klineDataState = ref.watch(klineDataProvider((widget.symbol, selectedInterval)));
    final theme = ref.watch(chartThemeProvider);
    final mainIndicators = ref.watch(mainIndicatorsProvider);
    final indicatorData = ref.watch(mainIndicatorDataProvider((widget.symbol, selectedInterval)));

    if (klineDataState.isLoading && klineDataState.data.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (klineDataState.data.isEmpty) {
      return Center(
        child: Text(
          '暂无K线数据',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    // 计算显示的数据范围
    final totalCount = klineDataState.data.length;
    final endIndex = totalCount;
    final startIndex = math.max(0, endIndex - _visibleCount);
    final visibleData = klineDataState.data.sublist(startIndex, endIndex);

    return GestureDetector(
      // 阻止手势向上传递
      behavior: HitTestBehavior.opaque,
      onScaleStart: (details) {
        _lastScaleValue = 1.0;
        _lastPanPosition = details.focalPoint;
      },
      onScaleUpdate: (details) {
        // 判断是缩放还是拖动
        if (details.pointerCount == 2) {
          // 双指缩放（X轴和Y轴）
          if ((details.scale - 1.0).abs() > 0.01) {
            setState(() {
              // 计算增量缩放
              final scaleDelta = details.scale / _lastScaleValue;
              _lastScaleValue = details.scale;
              
              // 更新X轴缩放比例
              _scale = (_scale * scaleDelta).clamp(0.5, 3.0);
              
              // 根据缩放比例计算可见K线数量
              _visibleCount = (50 / _scale).round().clamp(20, 200);
              
              // 同时更新Y轴缩放
              _priceScale = (_priceScale * scaleDelta).clamp(0.5, 3.0);
            });
          }
        } else if (details.pointerCount == 1 && _lastPanPosition != null) {
          // 单指拖动（上下调整价格区间）
          final dy = details.focalPoint.dy - _lastPanPosition!.dy;
          if (dy.abs() > 2) {
            setState(() {
              // 上下拖动调整价格缩放
              final sensitivity = 0.002;
              _priceScale = (_priceScale * (1 - dy * sensitivity)).clamp(0.5, 3.0);
              _lastPanPosition = details.focalPoint;
            });
          }
        }
      },
      onScaleEnd: (details) {
        _lastScaleValue = 1.0;
        _lastPanPosition = null;
      },
      onLongPressStart: (details) {
        _handleCrosshair(details.localPosition, visibleData, context);
      },
      onLongPressMoveUpdate: (details) {
        _handleCrosshair(details.localPosition, visibleData, context);
      },
      onLongPressEnd: (details) {
        // 3秒后隐藏十字光标
        _crosshairHideTime = DateTime.now().add(const Duration(seconds: 3));
        Future.delayed(const Duration(seconds: 3), () {
          if (_crosshairHideTime != null && 
              DateTime.now().difference(_crosshairHideTime!).inSeconds >= 0) {
            setState(() {
              _crosshairPosition = null;
              _selectedIndex = null;
            });
          }
        });
      },
      child: Stack(
        children: [
          CustomPaint(
            painter: KlineChartPainter(
              klineData: visibleData,
              theme: theme,
              mainIndicators: mainIndicators,
              indicatorData: indicatorData,
              startIndex: startIndex,
              crosshairPosition: _crosshairPosition,
              selectedIndex: _selectedIndex,
              priceScale: _priceScale,
            ),
            child: Container(), // 占位，保持CustomPaint的尺寸
          ),
          _buildCrosshairTooltip(visibleData, context),
        ],
      ),
    );
  }

  void _handleCrosshair(Offset position, List<KlineData> visibleData, BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final candleWidth = size.width / visibleData.length;
    final index = (position.dx / candleWidth).floor().clamp(0, visibleData.length - 1);

    setState(() {
      _crosshairPosition = position;
      _selectedIndex = index;
      _crosshairHideTime = null; // 取消隐藏计时
    });
  }

  Widget _buildCrosshairTooltip(List<KlineData> visibleData, BuildContext context) {
    if (_crosshairPosition == null || _selectedIndex == null) {
      return Container();
    }

    final data = visibleData[_selectedIndex!];
    final change = data.close - data.open;
    final changePercent = (change / data.open * 100);

    // 获取屏幕宽度，判断显示在左侧还是右侧
    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;
    final isLeftSide = _crosshairPosition!.dx > size.width / 2;

    return Positioned(
      left: isLeftSide ? 4 : null,
      right: isLeftSide ? null : 4,
      top: 4,
      child: IgnorePointer(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 110),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[300]?.withOpacity(0.75),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[400]!.withOpacity(0.5), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(data.timestamp),
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              _buildCompactRow('O', data.open.toStringAsFixed(2)),
              _buildCompactRow('H', data.high.toStringAsFixed(2)),
              _buildCompactRow('L', data.low.toStringAsFixed(2)),
              _buildCompactRow('C', data.close.toStringAsFixed(2)),
              const SizedBox(height: 2),
              _buildCompactRow(
                '涨',
                '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
                valueColor: changePercent >= 0 ? Colors.green[700] : Colors.red[700],
              ),
              _buildCompactRow('量', _formatVolume(data.volume)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.grey[900],
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
           '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatVolume(double volume) {
    if (volume >= 1e9) {
      return '${(volume / 1e9).toStringAsFixed(2)}B';
    } else if (volume >= 1e6) {
      return '${(volume / 1e6).toStringAsFixed(2)}M';
    } else if (volume >= 1e3) {
      return '${(volume / 1e3).toStringAsFixed(2)}K';
    }
    return volume.toStringAsFixed(2);
  }
}

/// K线图表绘制器
class KlineChartPainter extends CustomPainter {
  final List<KlineData> klineData;
  final ChartTheme theme;
  final List<IndicatorConfig> mainIndicators;
  final Map<String, IndicatorData> indicatorData;
  final int startIndex;
  final Offset? crosshairPosition;
  final int? selectedIndex;
  final double priceScale;

  KlineChartPainter({
    required this.klineData,
    required this.theme,
    required this.mainIndicators,
    required this.indicatorData,
    this.startIndex = 0,
    this.crosshairPosition,
    this.selectedIndex,
    this.priceScale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (klineData.isEmpty) return;

    // 为右侧价格标签预留空间（60像素）
    const rightPadding = 60.0;
    final chartWidth = size.width - rightPadding;

    // 计算价格范围
    double maxPrice = double.negativeInfinity;
    double minPrice = double.infinity;

    for (final data in klineData) {
      maxPrice = math.max(maxPrice, data.high);
      minPrice = math.min(minPrice, data.low);
    }

    // 考虑指标数据的范围
    for (final entry in indicatorData.entries) {
      final values = entry.value.values;
      for (final valueList in values.values) {
        for (final value in valueList) {
          if (value != null) {
            maxPrice = math.max(maxPrice, value);
            minPrice = math.min(minPrice, value);
          }
        }
      }
    }

    // 应用价格缩放
    final priceRange = maxPrice - minPrice;
    final centerPrice = (maxPrice + minPrice) / 2;
    final scaledRange = priceRange / priceScale;
    maxPrice = centerPrice + scaledRange / 2;
    minPrice = centerPrice - scaledRange / 2;
    
    // 添加边距
    final adjustedRange = maxPrice - minPrice;
    maxPrice += adjustedRange * 0.05;
    minPrice -= adjustedRange * 0.05;

    // 绘制背景
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = theme.backgroundColor,
    );

    // 保存画布状态
    canvas.save();
    
    // 设置裁剪区域（只在图表区域绘制K线和指标）
    canvas.clipRect(Rect.fromLTWH(0, 0, chartWidth, size.height));

    // 绘制网格（只在图表区域）
    _drawGrid(canvas, Size(chartWidth, size.height));

    // 绘制K线（只在图表区域）
    _drawCandles(canvas, Size(chartWidth, size.height), minPrice, maxPrice);

    // 绘制主图指标（只在图表区域）
    _drawMainIndicators(canvas, Size(chartWidth, size.height), minPrice, maxPrice);

    // 绘制十字光标（只在图表区域）
    if (crosshairPosition != null && selectedIndex != null) {
      _drawCrosshair(canvas, Size(chartWidth, size.height), minPrice, maxPrice);
    }
    
    // 恢复画布状态
    canvas.restore();

    // 绘制价格标签（在右侧预留区域，不受裁剪影响）
    _drawPriceLabels(canvas, size, minPrice, maxPrice, chartWidth);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.gridColor
      ..strokeWidth = 0.5;

    // 绘制水平网格线
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // 绘制垂直网格线
    for (int i = 0; i <= 4; i++) {
      final x = size.width * i / 4;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  void _drawCandles(Canvas canvas, Size size, double minPrice, double maxPrice) {
    final candleWidth = size.width / klineData.length * 0.8;
    final spacing = size.width / klineData.length * 0.2;

    for (int i = 0; i < klineData.length; i++) {
      final data = klineData[i];
      final x = i * size.width / klineData.length + spacing / 2;
      final isUp = data.close >= data.open;
      final color = isUp ? theme.upColor : theme.downColor;

      // 计算Y坐标
      final highY = _getY(data.high, minPrice, maxPrice, size.height);
      final lowY = _getY(data.low, minPrice, maxPrice, size.height);
      final openY = _getY(data.open, minPrice, maxPrice, size.height);
      final closeY = _getY(data.close, minPrice, maxPrice, size.height);

      // 绘制影线
      canvas.drawLine(
        Offset(x + candleWidth / 2, highY),
        Offset(x + candleWidth / 2, lowY),
        Paint()
          ..color = color
          ..strokeWidth = 1,
      );

      // 绘制实体
      final rect = Rect.fromLTRB(
        x,
        math.min(openY, closeY),
        x + candleWidth,
        math.max(openY, closeY),
      );

      if (isUp) {
        // 阳线：空心
        canvas.drawRect(
          rect,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      } else {
        // 阴线：实心
        canvas.drawRect(
          rect,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  void _drawMainIndicators(Canvas canvas, Size size, double minPrice, double maxPrice) {
    for (final entry in indicatorData.entries) {
      final indicatorName = entry.key;
      final data = entry.value;

      if (indicatorName.startsWith('MA')) {
        final maValues = data.values['ma'] ?? [];
        final config = mainIndicators.firstWhere(
          (ind) => ind is MAConfig && 'MA${ind.period}' == indicatorName,
          orElse: () => mainIndicators.first,
        );
        if (config is MAConfig && config.enabled) {
          // 截取可见范围的数据
          final visibleValues = _getVisibleValues(maValues);
          _drawLine(canvas, size, visibleValues, minPrice, maxPrice, config.color);
        }
      } else if (indicatorName.startsWith('EMA')) {
        final emaValues = data.values['ema'] ?? [];
        final config = mainIndicators.firstWhere(
          (ind) => ind is EMAConfig && 'EMA${ind.period}' == indicatorName,
          orElse: () => mainIndicators.first,
        );
        if (config is EMAConfig && config.enabled) {
          final visibleValues = _getVisibleValues(emaValues);
          _drawLine(canvas, size, visibleValues, minPrice, maxPrice, config.color);
        }
      } else if (indicatorName == 'BOLL') {
        final upper = data.values['upper'] ?? [];
        final middle = data.values['middle'] ?? [];
        final lower = data.values['lower'] ?? [];
        final config = mainIndicators.firstWhere(
          (ind) => ind is BOLLConfig,
          orElse: () => mainIndicators.first,
        );
        
        if (config is BOLLConfig && config.enabled) {
          final visibleUpper = _getVisibleValues(upper);
          final visibleMiddle = _getVisibleValues(middle);
          final visibleLower = _getVisibleValues(lower);
          
          _drawLine(canvas, size, visibleUpper, minPrice, maxPrice, config.upperColor);
          _drawLine(canvas, size, visibleMiddle, minPrice, maxPrice, config.middleColor);
          _drawLine(canvas, size, visibleLower, minPrice, maxPrice, config.lowerColor);
        }
      }
    }
  }

  List<double?> _getVisibleValues(List<double?> values) {
    if (values.length <= klineData.length) return values;
    final endIndex = startIndex + klineData.length;
    return values.sublist(startIndex, math.min(endIndex, values.length));
  }

  void _drawLine(
    Canvas canvas,
    Size size,
    List<double?> values,
    double minPrice,
    double maxPrice,
    Color color,
  ) {
    if (values.length != klineData.length) return;

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
      final y = _getY(values[i]!, minPrice, maxPrice, size.height);

      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  void _drawPriceLabels(Canvas canvas, Size size, double minPrice, double maxPrice, double chartWidth) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // 计算价格间隔，显示更多价格标签（8个）
    final priceRange = maxPrice - minPrice;
    final labelCount = 8; // 显示8个价格标签
    final priceStep = priceRange / (labelCount - 1);

    for (int i = 0; i < labelCount; i++) {
      final price = maxPrice - (priceStep * i);
      final y = size.height * i / (labelCount - 1);

      // 绘制价格文本
      textPainter.text = TextSpan(
        text: price.toStringAsFixed(2),
        style: TextStyle(
          color: theme.textColor,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      
      // 计算文本Y坐标，确保不超出边界
      double textY = y - textPainter.height / 2;
      
      // 顶部边界检查
      if (textY < 0) {
        textY = 0;
      }
      
      // 底部边界检查（确保文本底部不超出）
      if (textY + textPainter.height > size.height) {
        textY = size.height - textPainter.height;
      }
      
      // 绘制在图表右侧的预留区域
      textPainter.paint(
        canvas,
        Offset(chartWidth + 8, textY),
      );
      
      // 绘制价格线（虚线）
      final linePaint = Paint()
        ..color = theme.gridColor.withOpacity(0.3)
        ..strokeWidth = 0.5;
      
      _drawDashedLine(
        canvas,
        Offset(0, y),
        Offset(chartWidth, y),
        linePaint,
      );
    }
  }

  void _drawCrosshair(Canvas canvas, Size size, double minPrice, double maxPrice) {
    if (selectedIndex == null || selectedIndex! >= klineData.length) return;

    final data = klineData[selectedIndex!];
    final candleWidth = size.width / klineData.length;
    final x = (selectedIndex! + 0.5) * candleWidth;
    final y = _getY(data.close, minPrice, maxPrice, size.height);

    // 绘制虚线样式的十字线
    final dashedPaint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 1.5;

    // 绘制垂直虚线（只在图表区域内）
    _drawDashedLine(canvas, Offset(x, 0), Offset(x, size.height), dashedPaint);

    // 绘制水平虚线（只在图表区域内）
    _drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), dashedPaint);

    // 绘制时间标签（底部）
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final timeText = _formatTime(data.timestamp);
    textPainter.text = TextSpan(
      text: timeText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
    textPainter.layout();

    // 绘制时间标签背景
    final timeBoxRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, size.height - 10),
        width: textPainter.width + 8,
        height: 16,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      timeBoxRect,
      Paint()..color = Colors.black.withOpacity(0.8),
    );

    // 绘制时间文本
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, size.height - 18),
    );

    // 绘制价格标签（左侧，避免遮挡右侧价格）
    final priceText = data.close.toStringAsFixed(2);
    textPainter.text = TextSpan(
      text: priceText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
    textPainter.layout();

    // 绘制价格标签背景（在左侧）
    final priceBoxRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(textPainter.width / 2 + 4, y),
        width: textPainter.width + 8,
        height: 16,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      priceBoxRect,
      Paint()..color = (data.close >= data.open ? theme.upColor : theme.downColor).withOpacity(0.9),
    );

    // 绘制价格文本（在左侧）
    textPainter.paint(
      canvas,
      Offset(8, y - textPainter.height / 2),
    );

    // 绘制中心圆点
    canvas.drawCircle(
      Offset(x, y),
      4,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(x, y),
      4,
      Paint()
        ..color = data.close >= data.open ? theme.upColor : theme.downColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 3.0;
    final distance = (end - start).distance;
    final dashCount = (distance / (dashWidth + dashSpace)).floor();

    final dx = (end.dx - start.dx) / distance;
    final dy = (end.dy - start.dy) / distance;

    for (int i = 0; i < dashCount; i++) {
      final startX = start.dx + (dashWidth + dashSpace) * i * dx;
      final startY = start.dy + (dashWidth + dashSpace) * i * dy;
      final endX = startX + dashWidth * dx;
      final endY = startY + dashWidth * dy;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }
  }

  String _formatTime(DateTime time) {
    return '${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
           '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  double _getY(double value, double minValue, double maxValue, double height) {
    return height - (value - minValue) / (maxValue - minValue) * height;
  }

  @override
  bool shouldRepaint(KlineChartPainter oldDelegate) {
    return oldDelegate.klineData != klineData ||
        oldDelegate.theme != theme ||
        oldDelegate.mainIndicators != mainIndicators ||
        oldDelegate.indicatorData != indicatorData ||
        oldDelegate.startIndex != startIndex ||
        oldDelegate.crosshairPosition != crosshairPosition ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.priceScale != priceScale;
  }
}

