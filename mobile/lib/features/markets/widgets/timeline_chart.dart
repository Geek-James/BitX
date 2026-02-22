import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chart_theme.dart';
import '../providers/chart_theme_provider.dart';
import '../providers/market_detail_provider.dart';
import '../../../shared/network/websocket_service.dart';
import 'dart:async';
import 'dart:math' as math;

/// 分时图数据点
class TimelinePoint {
  final DateTime timestamp;
  final double price;
  final double volume;

  TimelinePoint({
    required this.timestamp,
    required this.price,
    required this.volume,
  });
}

/// 分时图组件
class TimelineChart extends ConsumerStatefulWidget {
  final String symbol;

  const TimelineChart({
    super.key,
    required this.symbol,
  });

  @override
  ConsumerState<TimelineChart> createState() => _TimelineChartState();
}

class _TimelineChartState extends ConsumerState<TimelineChart>
    with SingleTickerProviderStateMixin {
  final List<TimelinePoint> _dataPoints = [];
  late AnimationController _rippleController;
  bool _showRipple = false;
  StreamSubscription? _tradeSubscription;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    
    // 初始化水花动画控制器（减慢速度）
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // 监听动画完成
    _rippleController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showRipple = false;
        });
        _rippleController.reset();
      }
    });

    // 延迟初始化，等待 ref 可用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _tradeSubscription?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }

  /// 初始化数据
  void _initializeData() {
    if (!mounted) return;
    
    try {
      final wsService = ref.read(webSocketServiceProvider);
      final coordinator = wsService.coordinator;
      
      // 生成初始历史数据（使用协调器保证价格一致性）
      _generateInitialData(coordinator);

      // 订阅实时成交数据
      _subscribeToTrades(wsService);

      // 每3秒更新一次价格（使用协调器的价格）
      _updateTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (mounted) {
          _addDataPointWithRipple(coordinator);
        }
      });
    } catch (e) {
      // Error initializing timeline chart
    }
  }

  /// 生成初始数据（使用协调器的价格）
  void _generateInitialData(coordinator) {
    if (!mounted) return;
    
    final now = DateTime.now();
    final startTime = DateTime(now.year, now.month, now.day, 9, 30); // 9:30开盘
    final random = math.Random();
    
    // 从协调器获取当前价格
    final currentPrice = coordinator.getCurrentPrice(widget.symbol);
    
    // 生成从开盘到现在的数据点（每分钟一个点）
    final minutesSinceOpen = now.difference(startTime).inMinutes;
    // 确保至少有60个点，最多240个点
    final pointCount = math.max(60, math.min(minutesSinceOpen, 240));
    
    // 开盘价设为当前价格的95%-105%范围
    double basePrice = currentPrice * (0.95 + random.nextDouble() * 0.1);
    
    // 计算实际开始时间（如果在9:30之前，从当前时间往前推）
    final actualStartTime = minutesSinceOpen > 0 
        ? startTime 
        : now.subtract(Duration(minutes: pointCount));
    
    for (int i = 0; i < pointCount; i++) {
      final timestamp = actualStartTime.add(Duration(minutes: i));
      
      // 如果是最后几个点，让价格逐渐接近当前价格
      if (i >= pointCount - 10 && pointCount > 10) {
        final progress = (i - (pointCount - 10)) / 10.0;
        final targetChange = (currentPrice - basePrice) * progress * 0.3;
        final randomChange = (random.nextDouble() - 0.5) * basePrice * 0.001;
        basePrice += targetChange + randomChange;
      } else {
        // 正常波动
        final priceChange = (random.nextDouble() - 0.5) * basePrice * 0.002;
        basePrice += priceChange;
      }
      
      _dataPoints.add(TimelinePoint(
        timestamp: timestamp,
        price: basePrice,
        volume: 100 + random.nextDouble() * 500,
      ));
    }
    
    // 确保最后一个点的价格接近当前价格
    if (_dataPoints.isNotEmpty) {
      final lastPoint = _dataPoints.last;
      _dataPoints[_dataPoints.length - 1] = TimelinePoint(
        timestamp: lastPoint.timestamp,
        price: currentPrice,
        volume: lastPoint.volume,
      );
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  /// 订阅实时成交数据
  void _subscribeToTrades(WebSocketService wsService) {
    try {
      _tradeSubscription = wsService.tradesStream.listen((data) {
        if (!mounted) return;
        
        try {
          final channel = data['channel'] as String?;
          final expectedChannel = 'trades.${widget.symbol}';
          
          if (channel == expectedChannel) {
            // 成交时触发水花动画
            if (mounted) {
              setState(() {
                _showRipple = true;
              });
              
              // 在setState之外启动动画
              if (_rippleController.status != AnimationStatus.forward) {
                _rippleController.forward(from: 0);
              }
            }
          }
        } catch (e) {
          // Error processing trade data
        }
      }, onError: (error) {
        // Trade stream error
      });
      
      // 订阅成交频道
      wsService.subscribeTrades(widget.symbol);
    } catch (e) {
      // Error subscribing to trades
    }
  }

  /// 添加新数据点并触发水花动画（使用协调器的价格）
  void _addDataPointWithRipple(coordinator) {
    if (!mounted) return;

    try {
      // 从协调器获取当前价格（保证与订单薄、成交记录一致）
      final newPrice = coordinator.getCurrentPrice(widget.symbol);
      final random = math.Random();

      if (mounted) {
        setState(() {
          _dataPoints.add(TimelinePoint(
            timestamp: DateTime.now(),
            price: newPrice,
            volume: 100 + random.nextDouble() * 500,
          ));

          // 限制数据点数量
          if (_dataPoints.length > 300) {
            _dataPoints.removeAt(0);
          }

          // 触发水花动画
          _showRipple = true;
        });
        
        // 在setState之外启动动画，避免在build期间修改状态
        if (mounted && _rippleController.status != AnimationStatus.forward) {
          _rippleController.forward(from: 0);
        }
      }
    } catch (e) {
      // Error adding timeline data point
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(chartThemeProvider);

    if (_dataPoints.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomPaint(
      painter: TimelineChartPainter(
        dataPoints: _dataPoints,
        theme: theme,
        showRipple: _showRipple,
        rippleAnimation: _rippleController,
      ),
      child: Container(),
    );
  }
}

/// 分时图绘制器
class TimelineChartPainter extends CustomPainter {
  final List<TimelinePoint> dataPoints;
  final ChartTheme theme;
  final bool showRipple;
  final Animation<double> rippleAnimation;

  TimelineChartPainter({
    required this.dataPoints,
    required this.theme,
    required this.showRipple,
    required this.rippleAnimation,
  }) : super(repaint: rippleAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    // 为右侧价格标签预留空间
    const rightPadding = 60.0;
    final chartWidth = size.width - rightPadding;

    // 计算价格范围
    double maxPrice = double.negativeInfinity;
    double minPrice = double.infinity;

    for (final point in dataPoints) {
      maxPrice = math.max(maxPrice, point.price);
      minPrice = math.min(minPrice, point.price);
    }

    // 添加边距
    final priceRange = maxPrice - minPrice;
    maxPrice += priceRange * 0.1;
    minPrice -= priceRange * 0.1;

    // 计算开盘价（用于涨跌颜色判断）
    final openPrice = dataPoints.first.price;
    final currentPrice = dataPoints.last.price;
    final isUp = currentPrice >= openPrice;

    // 绘制背景
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = theme.backgroundColor,
    );

    // 保存画布状态并设置裁剪区域
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, chartWidth, size.height));

    // 绘制网格
    _drawGrid(canvas, Size(chartWidth, size.height));

    // 绘制均价线（MA）
    _drawAverageLine(canvas, Size(chartWidth, size.height), minPrice, maxPrice);

    // 绘制价格线和渐变填充
    _drawPriceLine(canvas, Size(chartWidth, size.height), minPrice, maxPrice, openPrice);

    // 绘制当前价格点
    _drawCurrentPricePoint(canvas, Size(chartWidth, size.height), minPrice, maxPrice, isUp);

    // 绘制水花动画
    if (showRipple) {
      _drawRippleEffect(canvas, Size(chartWidth, size.height), minPrice, maxPrice, isUp);
    }

    canvas.restore();

    // 绘制价格标签
    _drawPriceLabels(canvas, size, minPrice, maxPrice, chartWidth, openPrice);

    // 绘制时间轴
    _drawTimeAxis(canvas, size, chartWidth);
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
  }

  void _drawAverageLine(Canvas canvas, Size size, double minPrice, double maxPrice) {
    if (dataPoints.length < 2) return;

    final paint = Paint()
      ..color = Colors.yellow[700]!
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    double sum = 0;
    
    // 计算有效绘制宽度（留出10%右侧空间）
    final effectiveWidth = size.width * 0.9;

    for (int i = 0; i < dataPoints.length; i++) {
      sum += dataPoints[i].price;
      final avgPrice = sum / (i + 1);
      
      final x = effectiveWidth * i / (dataPoints.length - 1);
      final y = _getY(avgPrice, minPrice, maxPrice, size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  void _drawPriceLine(Canvas canvas, Size size, double minPrice, double maxPrice, double openPrice) {
    if (dataPoints.length < 2) return;

    final currentPrice = dataPoints.last.price;
    final isUp = currentPrice >= openPrice;
    final lineColor = isUp ? theme.upColor : theme.downColor;

    // 绘制价格线（增加右侧留白，让最新价格点不贴边）
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final linePath = Path();
    
    // 计算有效绘制宽度（留出10%右侧空间）
    final effectiveWidth = size.width * 0.9;

    for (int i = 0; i < dataPoints.length; i++) {
      final x = effectiveWidth * i / (dataPoints.length - 1);
      final y = _getY(dataPoints[i].price, minPrice, maxPrice, size.height);

      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }

    canvas.drawPath(linePath, linePaint);

    // 绘制渐变填充
    final fillPath = Path.from(linePath);
    fillPath.lineTo(effectiveWidth, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        lineColor.withOpacity(0.3),
        lineColor.withOpacity(0.05),
      ],
    );

    final fillPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, effectiveWidth, size.height));

    canvas.drawPath(fillPath, fillPaint);
  }

  void _drawCurrentPricePoint(Canvas canvas, Size size, double minPrice, double maxPrice, bool isUp) {
    final lastPoint = dataPoints.last;
    // 计算有效绘制宽度（留出10%右侧空间）
    final effectiveWidth = size.width * 0.9;
    final x = effectiveWidth * (dataPoints.length - 1) / (dataPoints.length - 1);
    final y = _getY(lastPoint.price, minPrice, maxPrice, size.height);

    final color = isUp ? theme.upColor : theme.downColor;

    // 绘制外圈（白色）
    canvas.drawCircle(
      Offset(x, y),
      6,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // 绘制内圈（涨跌颜色）
    canvas.drawCircle(
      Offset(x, y),
      4,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  void _drawRippleEffect(Canvas canvas, Size size, double minPrice, double maxPrice, bool isUp) {
    final lastPoint = dataPoints.last;
    // 计算有效绘制宽度（留出10%右侧空间）
    final effectiveWidth = size.width * 0.9;
    final x = effectiveWidth * (dataPoints.length - 1) / (dataPoints.length - 1);
    final y = _getY(lastPoint.price, minPrice, maxPrice, size.height);

    final color = isUp ? theme.upColor : theme.downColor;
    final progress = rippleAnimation.value;

    // 绘制3个水花圆圈（减慢扩散速度）
    for (int i = 0; i < 3; i++) {
      final delay = i * 0.2; // 增加延迟，让水花更有层次感
      final rippleProgress = math.max(0.0, math.min(1.0, (progress - delay) / (1 - delay)));
      
      if (rippleProgress > 0) {
        final radius = 6 + rippleProgress * 25; // 增加最大半径
        final opacity = (1 - rippleProgress) * 0.4; // 降低透明度

        canvas.drawCircle(
          Offset(x, y),
          radius,
          Paint()
            ..color = color.withOpacity(opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  void _drawPriceLabels(Canvas canvas, Size size, double minPrice, double maxPrice, double chartWidth, double openPrice) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // 显示5个价格标签
    final labelCount = 5;
    final priceStep = (maxPrice - minPrice) / (labelCount - 1);

    for (int i = 0; i < labelCount; i++) {
      final price = maxPrice - (priceStep * i);
      final y = size.height * i / (labelCount - 1);

      // 计算涨跌幅
      final changePercent = ((price - openPrice) / openPrice) * 100;
      final isUp = changePercent >= 0;

      textPainter.text = TextSpan(
        text: '${price.toStringAsFixed(2)}\n${isUp ? '+' : ''}${changePercent.toStringAsFixed(2)}%',
        style: TextStyle(
          color: isUp ? theme.upColor : theme.downColor,
          fontSize: 9,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
      );
      textPainter.layout();

      // 计算文本Y坐标，确保不超出边界
      double textY = y - textPainter.height / 2;
      if (textY < 0) textY = 0;
      if (textY + textPainter.height > size.height) {
        textY = size.height - textPainter.height;
      }

      textPainter.paint(
        canvas,
        Offset(chartWidth + 8, textY),
      );
    }
  }

  void _drawTimeAxis(Canvas canvas, Size size, double chartWidth) {
    if (dataPoints.isEmpty) return;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // 显示开盘时间、中间时间、当前时间
    final times = [
      dataPoints.first.timestamp,
      dataPoints[dataPoints.length ~/ 2].timestamp,
      dataPoints.last.timestamp,
    ];

    for (int i = 0; i < times.length; i++) {
      final time = times[i];
      final x = chartWidth * i / (times.length - 1);

      textPainter.text = TextSpan(
        text: '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
        style: TextStyle(
          color: theme.textColor,
          fontSize: 10,
        ),
      );
      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - 20),
      );
    }
  }

  double _getY(double value, double minValue, double maxValue, double height) {
    return height - (value - minValue) / (maxValue - minValue) * height;
  }

  @override
  bool shouldRepaint(TimelineChartPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints ||
        oldDelegate.showRipple != showRipple ||
        oldDelegate.rippleAnimation != rippleAnimation;
  }
}

