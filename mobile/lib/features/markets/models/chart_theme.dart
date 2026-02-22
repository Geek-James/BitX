import 'package:flutter/material.dart';

/// 图表主题
class ChartTheme {
  final String name;
  final Color backgroundColor;
  final Color gridColor;
  final Color textColor;
  final Color upColor;      // 涨
  final Color downColor;    // 跌
  final Color ma5Color;
  final Color ma10Color;
  final Color ma20Color;
  final Color ma30Color;
  final Color volumeUpColor;
  final Color volumeDownColor;
  final Color crosshairColor;
  final Color selectedColor;

  const ChartTheme({
    required this.name,
    required this.backgroundColor,
    required this.gridColor,
    required this.textColor,
    required this.upColor,
    required this.downColor,
    required this.ma5Color,
    required this.ma10Color,
    required this.ma20Color,
    required this.ma30Color,
    required this.volumeUpColor,
    required this.volumeDownColor,
    required this.crosshairColor,
    required this.selectedColor,
  });

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'backgroundColor': backgroundColor.value,
      'gridColor': gridColor.value,
      'textColor': textColor.value,
      'upColor': upColor.value,
      'downColor': downColor.value,
      'ma5Color': ma5Color.value,
      'ma10Color': ma10Color.value,
      'ma20Color': ma20Color.value,
      'ma30Color': ma30Color.value,
      'volumeUpColor': volumeUpColor.value,
      'volumeDownColor': volumeDownColor.value,
      'crosshairColor': crosshairColor.value,
      'selectedColor': selectedColor.value,
    };
  }

  /// 从JSON创建
  factory ChartTheme.fromJson(Map<String, dynamic> json) {
    return ChartTheme(
      name: json['name'] as String,
      backgroundColor: Color(json['backgroundColor'] as int),
      gridColor: Color(json['gridColor'] as int),
      textColor: Color(json['textColor'] as int),
      upColor: Color(json['upColor'] as int),
      downColor: Color(json['downColor'] as int),
      ma5Color: Color(json['ma5Color'] as int),
      ma10Color: Color(json['ma10Color'] as int),
      ma20Color: Color(json['ma20Color'] as int),
      ma30Color: Color(json['ma30Color'] as int),
      volumeUpColor: Color(json['volumeUpColor'] as int),
      volumeDownColor: Color(json['volumeDownColor'] as int),
      crosshairColor: Color(json['crosshairColor'] as int),
      selectedColor: Color(json['selectedColor'] as int),
    );
  }

  /// 复制并修改
  ChartTheme copyWith({
    String? name,
    Color? backgroundColor,
    Color? gridColor,
    Color? textColor,
    Color? upColor,
    Color? downColor,
    Color? ma5Color,
    Color? ma10Color,
    Color? ma20Color,
    Color? ma30Color,
    Color? volumeUpColor,
    Color? volumeDownColor,
    Color? crosshairColor,
    Color? selectedColor,
  }) {
    return ChartTheme(
      name: name ?? this.name,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gridColor: gridColor ?? this.gridColor,
      textColor: textColor ?? this.textColor,
      upColor: upColor ?? this.upColor,
      downColor: downColor ?? this.downColor,
      ma5Color: ma5Color ?? this.ma5Color,
      ma10Color: ma10Color ?? this.ma10Color,
      ma20Color: ma20Color ?? this.ma20Color,
      ma30Color: ma30Color ?? this.ma30Color,
      volumeUpColor: volumeUpColor ?? this.volumeUpColor,
      volumeDownColor: volumeDownColor ?? this.volumeDownColor,
      crosshairColor: crosshairColor ?? this.crosshairColor,
      selectedColor: selectedColor ?? this.selectedColor,
    );
  }
}

/// 预设主题
class ChartThemes {
  /// 经典主题（绿涨红跌）
  static const classic = ChartTheme(
    name: '经典',
    backgroundColor: Colors.white,
    gridColor: Color(0xFFE0E0E0),
    textColor: Color(0xFF666666),
    upColor: Color(0xFF00C087),      // 绿色
    downColor: Color(0xFFEF5350),    // 红色
    ma5Color: Color(0xFF1E88E5),
    ma10Color: Color(0xFFFFA726),
    ma20Color: Color(0xFFAB47BC),
    ma30Color: Color(0xFF26A69A),
    volumeUpColor: Color(0xFF00C087),
    volumeDownColor: Color(0xFFEF5350),
    crosshairColor: Color(0xFF9E9E9E),
    selectedColor: Color(0xFF2196F3),
  );

  /// 暗黑主题
  static const dark = ChartTheme(
    name: '暗黑',
    backgroundColor: Color(0xFF1E1E1E),
    gridColor: Color(0xFF2D2D2D),
    textColor: Color(0xFFB0B0B0),
    upColor: Color(0xFF00C087),
    downColor: Color(0xFFEF5350),
    ma5Color: Color(0xFF42A5F5),
    ma10Color: Color(0xFFFFB74D),
    ma20Color: Color(0xFFBA68C8),
    ma30Color: Color(0xFF4DB6AC),
    volumeUpColor: Color(0xFF00C087),
    volumeDownColor: Color(0xFFEF5350),
    crosshairColor: Color(0xFF757575),
    selectedColor: Color(0xFF64B5F6),
  );

  /// 护眼主题
  static const eyeCare = ChartTheme(
    name: '护眼',
    backgroundColor: Color(0xFFF5F5DC),  // 米黄色
    gridColor: Color(0xFFE8E8D0),
    textColor: Color(0xFF5D5D4F),
    upColor: Color(0xFF2E7D32),          // 深绿
    downColor: Color(0xFFC62828),        // 深红
    ma5Color: Color(0xFF1565C0),
    ma10Color: Color(0xFFE65100),
    ma20Color: Color(0xFF6A1B9A),
    ma30Color: Color(0xFF00695C),
    volumeUpColor: Color(0xFF2E7D32),
    volumeDownColor: Color(0xFFC62828),
    crosshairColor: Color(0xFF8D8D7A),
    selectedColor: Color(0xFF1976D2),
  );

  /// 美股风格（红涨绿跌）
  static const usStyle = ChartTheme(
    name: '美股',
    backgroundColor: Colors.white,
    gridColor: Color(0xFFE0E0E0),
    textColor: Color(0xFF666666),
    upColor: Color(0xFFEF5350),      // 红色
    downColor: Color(0xFF00C087),    // 绿色
    ma5Color: Color(0xFF1E88E5),
    ma10Color: Color(0xFFFFA726),
    ma20Color: Color(0xFFAB47BC),
    ma30Color: Color(0xFF26A69A),
    volumeUpColor: Color(0xFFEF5350),
    volumeDownColor: Color(0xFF00C087),
    crosshairColor: Color(0xFF9E9E9E),
    selectedColor: Color(0xFF2196F3),
  );

  /// 极简主题
  static const minimal = ChartTheme(
    name: '极简',
    backgroundColor: Color(0xFFFAFAFA),
    gridColor: Color(0xFFEEEEEE),
    textColor: Color(0xFF424242),
    upColor: Color(0xFF4CAF50),
    downColor: Color(0xFFF44336),
    ma5Color: Color(0xFF2196F3),
    ma10Color: Color(0xFFFF9800),
    ma20Color: Color(0xFF9C27B0),
    ma30Color: Color(0xFF009688),
    volumeUpColor: Color(0xFF4CAF50),
    volumeDownColor: Color(0xFFF44336),
    crosshairColor: Color(0xFFBDBDBD),
    selectedColor: Color(0xFF1976D2),
  );

  /// 所有预设主题
  static const List<ChartTheme> presets = [
    classic,
    dark,
    eyeCare,
    usStyle,
    minimal,
  ];

  /// 根据名称获取主题
  static ChartTheme? getByName(String name) {
    try {
      return presets.firstWhere((theme) => theme.name == name);
    } catch (e) {
      return null;
    }
  }
}

