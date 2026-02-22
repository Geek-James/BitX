import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/chart_theme.dart';
import '../providers/chart_theme_provider.dart';

/// 图表主题设置页面
class ChartThemeSettingsScreen extends ConsumerWidget {
  const ChartThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentTheme = ref.watch(chartThemeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chartTheme),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(chartThemeProvider.notifier).reset();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.resetToDefault)),
              );
            },
            child: Text(l10n.reset, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        children: [
          // 预设主题
          _buildSection(
            l10n,
            title: l10n.presetThemes,
            child: _buildPresetThemes(context, ref, currentTheme),
          ),

          const Divider(height: 32),

          // 涨跌颜色
          _buildSection(
            l10n,
            title: l10n.upDownColors,
            child: Column(
              children: [
                _buildColorTile(
                  context,
                  ref,
                  l10n,
                  label: l10n.upColor,
                  color: currentTheme.upColor,
                  onColorChanged: (color) {
                    ref.read(chartThemeProvider.notifier).updateColor(upColor: color);
                  },
                ),
                _buildColorTile(
                  context,
                  ref,
                  l10n,
                  label: l10n.downColor,
                  color: currentTheme.downColor,
                  onColorChanged: (color) {
                    ref.read(chartThemeProvider.notifier).updateColor(downColor: color);
                  },
                ),
                ListTile(
                  title: Text(l10n.toggleUpDownColors),
                  subtitle: Text(l10n.greenUpRedDown),
                  trailing: IconButton(
                    icon: const Icon(Icons.swap_horiz),
                    onPressed: () {
                      ref.read(chartThemeProvider.notifier).toggleUpDownColors();
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 32),

          // 背景和网格
          _buildSection(
            l10n,
            title: l10n.backgroundAndGrid,
            child: Column(
              children: [
                _buildColorTile(
                  context,
                  ref,
                  l10n,
                  label: l10n.backgroundColor,
                  color: currentTheme.backgroundColor,
                  onColorChanged: (color) {
                    ref.read(chartThemeProvider.notifier).updateColor(backgroundColor: color);
                  },
                ),
                _buildColorTile(
                  context,
                  ref,
                  l10n,
                  label: l10n.gridColor,
                  color: currentTheme.gridColor,
                  onColorChanged: (color) {
                    ref.read(chartThemeProvider.notifier).updateColor(gridColor: color);
                  },
                ),
                _buildColorTile(
                  context,
                  ref,
                  l10n,
                  label: l10n.textColor,
                  color: currentTheme.textColor,
                  onColorChanged: (color) {
                    ref.read(chartThemeProvider.notifier).updateColor(textColor: color);
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 32),

          // MA均线颜色
          _buildSection(
            l10n,
            title: l10n.maLineColors,
            child: Column(
              children: [
                _buildColorTile(
                  context,
                  ref,
                  l10n,
                  label: 'MA5',
                  color: currentTheme.ma5Color,
                  onColorChanged: (color) {
                    ref.read(chartThemeProvider.notifier).updateColor(ma5Color: color);
                  },
                ),
                _buildColorTile(
                  context,
                  ref,
                  l10n,
                  label: 'MA10',
                  color: currentTheme.ma10Color,
                  onColorChanged: (color) {
                    ref.read(chartThemeProvider.notifier).updateColor(ma10Color: color);
                  },
                ),
                _buildColorTile(
                  context,
                  ref,
                  l10n,
                  label: 'MA20',
                  color: currentTheme.ma20Color,
                  onColorChanged: (color) {
                    ref.read(chartThemeProvider.notifier).updateColor(ma20Color: color);
                  },
                ),
                _buildColorTile(
                  context,
                  ref,
                  l10n,
                  label: 'MA30',
                  color: currentTheme.ma30Color,
                  onColorChanged: (color) {
                    ref.read(chartThemeProvider.notifier).updateColor(ma30Color: color);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(AppLocalizations l10n, {required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildPresetThemes(BuildContext context, WidgetRef ref, ChartTheme currentTheme) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ChartThemes.presets.length,
        itemBuilder: (context, index) {
          final theme = ChartThemes.presets[index];
          final isSelected = theme.name == currentTheme.name;

          return GestureDetector(
            onTap: () {
              ref.read(chartThemeProvider.notifier).setTheme(theme);
            },
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: theme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey[300]!,
                  width: isSelected ? 3 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 颜色预览
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: theme.upColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: theme.downColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    theme.name,
                    style: TextStyle(
                      color: theme.textColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, color: Colors.blue, size: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildColorTile(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n, {
    required String label,
    required Color color,
    required ValueChanged<Color> onColorChanged,
  }) {
    return ListTile(
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _showColorPicker(context, l10n, color, onColorChanged);
            },
          ),
        ],
      ),
    );
  }

  void _showColorPicker(
    BuildContext context,
    AppLocalizations l10n,
    Color currentColor,
    ValueChanged<Color> onColorChanged,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectColor),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // 预设颜色
              ...Colors.primaries.map((color) {
                return GestureDetector(
                  onTap: () {
                    onColorChanged(color);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: color == currentColor ? Colors.black : Colors.grey[300]!,
                        width: color == currentColor ? 3 : 1,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}

