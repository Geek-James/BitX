import 'package:flutter/material.dart';
import '../models/order_book.dart';
import '../models/order_book_entry.dart';

/// 深度图组件
class DepthChartWidget extends StatelessWidget {
  final OrderBook orderBook;
  final double height;

  const DepthChartWidget({
    super.key,
    required this.orderBook,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      child: CustomPaint(
        painter: DepthChartPainter(orderBook: orderBook),
        child: Container(),
      ),
    );
  }
}

/// 深度图绘制器
class DepthChartPainter extends CustomPainter {
  final OrderBook orderBook;

  DepthChartPainter({required this.orderBook});

  @override
  void paint(Canvas canvas, Size size) {
    final bids = orderBook.bids;
    final asks = orderBook.asks;

    if (bids.isEmpty || asks.isEmpty) {
      _drawNoData(canvas, size);
      return;
    }

    // 计算价格范围
    final minPrice = bids.last.price;
    final maxPrice = asks.last.price;
    final priceRange = maxPrice - minPrice;

    if (priceRange <= 0) return;

    // 计算最大累计量
    final maxBidTotal = bids.last.total;
    final maxAskTotal = asks.last.total;
    final maxTotal = maxBidTotal > maxAskTotal ? maxBidTotal : maxAskTotal;

    if (maxTotal <= 0) return;

    // 计算中间价位置
    final midPrice = orderBook.midPrice ?? (minPrice + maxPrice) / 2;
    final midX = ((midPrice - minPrice) / priceRange) * size.width;

    // 绘制买单深度
    _drawBidDepth(canvas, size, bids, minPrice, priceRange, maxTotal, midX);

    // 绘制卖单深度
    _drawAskDepth(canvas, size, asks, minPrice, priceRange, maxTotal, midX);

    // 绘制中间线
    _drawMidLine(canvas, size, midX);

    // 绘制坐标轴
    _drawAxes(canvas, size, minPrice, maxPrice, maxTotal);
  }

  /// 绘制买单深度
  void _drawBidDepth(
    Canvas canvas,
    Size size,
    List<OrderBookEntry> bids,
    double minPrice,
    double priceRange,
    double maxTotal,
    double midX,
  ) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    for (final bid in bids.reversed) {
      final x = ((bid.price - minPrice) / priceRange) * size.width;
      final y = size.height - (bid.total / maxTotal) * size.height;

      if (x <= midX) {
        path.lineTo(x, y);
      }
    }

    path.lineTo(midX, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // 绘制边线
    final linePaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final linePath = Path();
    bool first = true;

    for (final bid in bids.reversed) {
      final x = ((bid.price - minPrice) / priceRange) * size.width;
      final y = size.height - (bid.total / maxTotal) * size.height;

      if (x <= midX) {
        if (first) {
          linePath.moveTo(x, y);
          first = false;
        } else {
          linePath.lineTo(x, y);
        }
      }
    }

    canvas.drawPath(linePath, linePaint);
  }

  /// 绘制卖单深度
  void _drawAskDepth(
    Canvas canvas,
    Size size,
    List<OrderBookEntry> asks,
    double minPrice,
    double priceRange,
    double maxTotal,
    double midX,
  ) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(midX, size.height);

    for (final ask in asks) {
      final x = ((ask.price - minPrice) / priceRange) * size.width;
      final y = size.height - (ask.total / maxTotal) * size.height;

      if (x >= midX) {
        path.lineTo(x, y);
      }
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // 绘制边线
    final linePaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final linePath = Path();
    bool first = true;

    for (final ask in asks) {
      final x = ((ask.price - minPrice) / priceRange) * size.width;
      final y = size.height - (ask.total / maxTotal) * size.height;

      if (x >= midX) {
        if (first) {
          linePath.moveTo(x, y);
          first = false;
        } else {
          linePath.lineTo(x, y);
        }
      }
    }

    canvas.drawPath(linePath, linePaint);
  }

  /// 绘制中间线
  void _drawMidLine(Canvas canvas, Size size, double midX) {
    final paint = Paint()
      ..color = Colors.grey[600]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    // 绘制虚线
    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(midX, startY),
        Offset(midX, startY + dashWidth),
        paint,
      );
      startY += dashWidth + dashSpace;
    }
  }

  /// 绘制坐标轴
  void _drawAxes(
    Canvas canvas,
    Size size,
    double minPrice,
    double maxPrice,
    double maxTotal,
  ) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // 绘制价格标签
    final priceLabels = [minPrice, (minPrice + maxPrice) / 2, maxPrice];
    for (int i = 0; i < priceLabels.length; i++) {
      final price = priceLabels[i];
      final x = (i / (priceLabels.length - 1)) * size.width;

      textPainter.text = TextSpan(
        text: price.toStringAsFixed(0),
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height + 4),
      );
    }

    // 绘制数量标签
    final volumeLabels = [0.0, maxTotal / 2, maxTotal];
    for (int i = 0; i < volumeLabels.length; i++) {
      final volume = volumeLabels[i];
      final y = size.height - (i / (volumeLabels.length - 1)) * size.height;

      textPainter.text = TextSpan(
        text: volume.toStringAsFixed(1),
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width - 4, y - textPainter.height / 2),
      );
    }
  }

  /// 绘制无数据提示
  void _drawNoData(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '暂无数据',
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(DepthChartPainter oldDelegate) {
    return oldDelegate.orderBook != orderBook;
  }
}

