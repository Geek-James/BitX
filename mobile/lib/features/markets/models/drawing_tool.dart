import 'package:flutter/material.dart';

/// 画线工具类型
enum DrawingType {
  trendLine,           // 趋势线
  horizontalLine,      // 水平线
  verticalLine,        // 垂直线
  rectangle,           // 矩形
  fibonacciRetracement, // 斐波那契回调
}

/// 画线对象基类
abstract class DrawingObject {
  final String id;
  final DrawingType type;
  final Color color;
  final double strokeWidth;
  final bool isDashed;
  final DateTime createdAt;

  const DrawingObject({
    required this.id,
    required this.type,
    required this.color,
    this.strokeWidth = 2.0,
    this.isDashed = false,
    required this.createdAt,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson();

  /// 从JSON创建
  static DrawingObject? fromJson(Map<String, dynamic> json) {
    final type = DrawingType.values.firstWhere(
      (e) => e.toString() == json['type'],
      orElse: () => DrawingType.trendLine,
    );

    switch (type) {
      case DrawingType.trendLine:
        return TrendLine.fromJson(json);
      case DrawingType.horizontalLine:
        return HorizontalLine.fromJson(json);
      case DrawingType.verticalLine:
        return VerticalLine.fromJson(json);
      case DrawingType.rectangle:
        return RectangleDrawing.fromJson(json);
      case DrawingType.fibonacciRetracement:
        return FibonacciRetracement.fromJson(json);
    }
  }

  /// 复制对象
  DrawingObject copyWith({
    Color? color,
    double? strokeWidth,
    bool? isDashed,
  });
}

/// 趋势线
class TrendLine extends DrawingObject {
  final DateTime startTime;
  final double startPrice;
  final DateTime endTime;
  final double endPrice;
  final bool extendRight; // 是否向右延伸

  const TrendLine({
    required String id,
    required this.startTime,
    required this.startPrice,
    required this.endTime,
    required this.endPrice,
    Color color = Colors.blue,
    double strokeWidth = 2.0,
    bool isDashed = false,
    this.extendRight = false,
    required DateTime createdAt,
  }) : super(
          id: id,
          type: DrawingType.trendLine,
          color: color,
          strokeWidth: strokeWidth,
          isDashed: isDashed,
          createdAt: createdAt,
        );

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'startTime': startTime.toIso8601String(),
      'startPrice': startPrice,
      'endTime': endTime.toIso8601String(),
      'endPrice': endPrice,
      'color': color.value,
      'strokeWidth': strokeWidth,
      'isDashed': isDashed,
      'extendRight': extendRight,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static TrendLine fromJson(Map<String, dynamic> json) {
    return TrendLine(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      startPrice: (json['startPrice'] as num).toDouble(),
      endTime: DateTime.parse(json['endTime'] as String),
      endPrice: (json['endPrice'] as num).toDouble(),
      color: Color(json['color'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      isDashed: json['isDashed'] as bool,
      extendRight: json['extendRight'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  TrendLine copyWith({
    Color? color,
    double? strokeWidth,
    bool? isDashed,
    bool? extendRight,
  }) {
    return TrendLine(
      id: id,
      startTime: startTime,
      startPrice: startPrice,
      endTime: endTime,
      endPrice: endPrice,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isDashed: isDashed ?? this.isDashed,
      extendRight: extendRight ?? this.extendRight,
      createdAt: createdAt,
    );
  }
}

/// 水平线
class HorizontalLine extends DrawingObject {
  final double price;
  final String? label;

  const HorizontalLine({
    required String id,
    required this.price,
    this.label,
    Color color = Colors.orange,
    double strokeWidth = 2.0,
    bool isDashed = false,
    required DateTime createdAt,
  }) : super(
          id: id,
          type: DrawingType.horizontalLine,
          color: color,
          strokeWidth: strokeWidth,
          isDashed: isDashed,
          createdAt: createdAt,
        );

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'price': price,
      'label': label,
      'color': color.value,
      'strokeWidth': strokeWidth,
      'isDashed': isDashed,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static HorizontalLine fromJson(Map<String, dynamic> json) {
    return HorizontalLine(
      id: json['id'] as String,
      price: (json['price'] as num).toDouble(),
      label: json['label'] as String?,
      color: Color(json['color'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      isDashed: json['isDashed'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  HorizontalLine copyWith({
    Color? color,
    double? strokeWidth,
    bool? isDashed,
    String? label,
  }) {
    return HorizontalLine(
      id: id,
      price: price,
      label: label ?? this.label,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isDashed: isDashed ?? this.isDashed,
      createdAt: createdAt,
    );
  }
}

/// 垂直线
class VerticalLine extends DrawingObject {
  final DateTime time;
  final String? label;

  const VerticalLine({
    required String id,
    required this.time,
    this.label,
    Color color = Colors.purple,
    double strokeWidth = 2.0,
    bool isDashed = true,
    required DateTime createdAt,
  }) : super(
          id: id,
          type: DrawingType.verticalLine,
          color: color,
          strokeWidth: strokeWidth,
          isDashed: isDashed,
          createdAt: createdAt,
        );

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'time': time.toIso8601String(),
      'label': label,
      'color': color.value,
      'strokeWidth': strokeWidth,
      'isDashed': isDashed,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static VerticalLine fromJson(Map<String, dynamic> json) {
    return VerticalLine(
      id: json['id'] as String,
      time: DateTime.parse(json['time'] as String),
      label: json['label'] as String?,
      color: Color(json['color'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      isDashed: json['isDashed'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  VerticalLine copyWith({
    Color? color,
    double? strokeWidth,
    bool? isDashed,
    String? label,
  }) {
    return VerticalLine(
      id: id,
      time: time,
      label: label ?? this.label,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isDashed: isDashed ?? this.isDashed,
      createdAt: createdAt,
    );
  }
}

/// 矩形
class RectangleDrawing extends DrawingObject {
  final DateTime startTime;
  final double startPrice;
  final DateTime endTime;
  final double endPrice;
  final bool filled;
  final Color? fillColor;

  const RectangleDrawing({
    required String id,
    required this.startTime,
    required this.startPrice,
    required this.endTime,
    required this.endPrice,
    Color color = Colors.green,
    double strokeWidth = 2.0,
    bool isDashed = false,
    this.filled = false,
    this.fillColor,
    required DateTime createdAt,
  }) : super(
          id: id,
          type: DrawingType.rectangle,
          color: color,
          strokeWidth: strokeWidth,
          isDashed: isDashed,
          createdAt: createdAt,
        );

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'startTime': startTime.toIso8601String(),
      'startPrice': startPrice,
      'endTime': endTime.toIso8601String(),
      'endPrice': endPrice,
      'color': color.value,
      'strokeWidth': strokeWidth,
      'isDashed': isDashed,
      'filled': filled,
      'fillColor': fillColor?.value,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static RectangleDrawing fromJson(Map<String, dynamic> json) {
    return RectangleDrawing(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      startPrice: (json['startPrice'] as num).toDouble(),
      endTime: DateTime.parse(json['endTime'] as String),
      endPrice: (json['endPrice'] as num).toDouble(),
      color: Color(json['color'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      isDashed: json['isDashed'] as bool,
      filled: json['filled'] as bool? ?? false,
      fillColor: json['fillColor'] != null ? Color(json['fillColor'] as int) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  RectangleDrawing copyWith({
    Color? color,
    double? strokeWidth,
    bool? isDashed,
    bool? filled,
    Color? fillColor,
  }) {
    return RectangleDrawing(
      id: id,
      startTime: startTime,
      startPrice: startPrice,
      endTime: endTime,
      endPrice: endPrice,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isDashed: isDashed ?? this.isDashed,
      filled: filled ?? this.filled,
      fillColor: fillColor ?? this.fillColor,
      createdAt: createdAt,
    );
  }
}

/// 斐波那契回调
class FibonacciRetracement extends DrawingObject {
  final DateTime startTime;
  final double startPrice;
  final DateTime endTime;
  final double endPrice;
  final List<double> levels; // 回调比例 [0.236, 0.382, 0.5, 0.618, 0.786]

  const FibonacciRetracement({
    required String id,
    required this.startTime,
    required this.startPrice,
    required this.endTime,
    required this.endPrice,
    this.levels = const [0.236, 0.382, 0.5, 0.618, 0.786],
    Color color = Colors.purple,
    double strokeWidth = 1.0,
    bool isDashed = true,
    required DateTime createdAt,
  }) : super(
          id: id,
          type: DrawingType.fibonacciRetracement,
          color: color,
          strokeWidth: strokeWidth,
          isDashed: isDashed,
          createdAt: createdAt,
        );

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'startTime': startTime.toIso8601String(),
      'startPrice': startPrice,
      'endTime': endTime.toIso8601String(),
      'endPrice': endPrice,
      'levels': levels,
      'color': color.value,
      'strokeWidth': strokeWidth,
      'isDashed': isDashed,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static FibonacciRetracement fromJson(Map<String, dynamic> json) {
    return FibonacciRetracement(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      startPrice: (json['startPrice'] as num).toDouble(),
      endTime: DateTime.parse(json['endTime'] as String),
      endPrice: (json['endPrice'] as num).toDouble(),
      levels: (json['levels'] as List).map((e) => (e as num).toDouble()).toList(),
      color: Color(json['color'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      isDashed: json['isDashed'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  FibonacciRetracement copyWith({
    Color? color,
    double? strokeWidth,
    bool? isDashed,
  }) {
    return FibonacciRetracement(
      id: id,
      startTime: startTime,
      startPrice: startPrice,
      endTime: endTime,
      endPrice: endPrice,
      levels: levels,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isDashed: isDashed ?? this.isDashed,
      createdAt: createdAt,
    );
  }
}

