import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/chart_theme.dart';

/// SharedPreferences Provider (延迟初始化)
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// 图表主题Provider
final chartThemeProvider = StateNotifierProvider<ChartThemeNotifier, ChartTheme>((ref) {
  return ChartThemeNotifier();
});

/// 图表主题状态管理器
class ChartThemeNotifier extends StateNotifier<ChartTheme> {
  static const String _themeKey = 'chart_theme';

  ChartThemeNotifier() : super(ChartThemes.classic) {
    _loadTheme();
  }

  /// 加载主题
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeJson = prefs.getString(_themeKey);
      if (themeJson != null) {
        final json = jsonDecode(themeJson) as Map<String, dynamic>;
        state = ChartTheme.fromJson(json);
      }
    } catch (e) {
      // Failed to load chart theme, use default
      state = ChartThemes.classic;
    }
  }

  /// 保存主题
  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeJson = jsonEncode(state.toJson());
      await prefs.setString(_themeKey, themeJson);
    } catch (e) {
      // Failed to save chart theme
    }
  }

  /// 设置主题
  Future<void> setTheme(ChartTheme theme) async {
    state = theme;
    await _saveTheme();
  }

  /// 更新主题颜色
  Future<void> updateColor({
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
  }) async {
    state = state.copyWith(
      name: name,
      backgroundColor: backgroundColor,
      gridColor: gridColor,
      textColor: textColor,
      upColor: upColor,
      downColor: downColor,
      ma5Color: ma5Color,
      ma10Color: ma10Color,
      ma20Color: ma20Color,
      ma30Color: ma30Color,
      volumeUpColor: volumeUpColor,
      volumeDownColor: volumeDownColor,
      crosshairColor: crosshairColor,
      selectedColor: selectedColor,
    );
    await _saveTheme();
  }

  /// 重置为默认主题
  Future<void> reset() async {
    state = ChartThemes.classic;
    await _saveTheme();
  }

  /// 切换涨跌颜色（绿涨红跌 <-> 红涨绿跌）
  Future<void> toggleUpDownColors() async {
    state = state.copyWith(
      upColor: state.downColor,
      downColor: state.upColor,
      volumeUpColor: state.volumeDownColor,
      volumeDownColor: state.volumeUpColor,
    );
    await _saveTheme();
  }
}

/// 当前是否为暗黑主题
final isDarkThemeProvider = Provider<bool>((ref) {
  final theme = ref.watch(chartThemeProvider);
  // 简单判断：背景色亮度低于0.5为暗黑主题
  final brightness = theme.backgroundColor.computeLuminance();
  return brightness < 0.5;
});

