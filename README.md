# BitX Mobile App

BitX CEX 移动端应用，模拟真实加密货币交易功能，包括实时行情、K线图表、订单簿、交易记录，跟单等核心功能。

## 📱 项目简介

BitX Mobile 是一款基于 Flutter 开发的跨平台加密货币交易应用，支持 iOS 和 Android 平台。应用采用现代化的架构设计，提供流畅的用户体验和实时的市场数据。

### 核心功能

- **实时行情**：支持多币种行情展示，实时价格更新
- **专业图表**：集成 K线图、深度图、多种技术指标（MACD、KDJ、RSI等）
- **订单簿**：实时买卖盘数据展示
- **跟单**：自动复制他人交易策略
- **交易记录**：最新成交记录实时更新
- **多图表视图**：支持同时查看多个交易对
- **主题定制**：支持自定义图表主题和配色
- **国际化**：支持中文和英文

## 🛠 技术栈

- **框架**：Flutter 3.22.3
- **语言**：Dart 3.4.4
- **状态管理**：Riverpod 2.6.1
- **网络通信**：WebSocket (web_socket_channel)
- **图表库**：Candlesticks 2.1.0
- **本地存储**：SharedPreferences 2.3.3
- **国际化**：flutter_localizations + intl

## 📁 项目结构

```
mobile/
├── lib/
│   ├── features/              # 功能模块
│   │   ├── markets/           # 行情模块
│   │   │   ├── models/        # 数据模型
│   │   │   ├── providers/     # 状态管理
│   │   │   ├── screens/       # 页面
│   │   │   ├── services/      # 业务服务
│   │   │   ├── utils/         # 工具类
│   │   │   └── widgets/       # UI组件
│   │   └── debug/             # 调试工具
│   ├── shared/                # 共享模块
│   │   ├── l10n/              # 国际化资源
│   │   ├── network/           # 网络层
│   │   └── ui/                # 通用UI组件
│   └── main.dart              # 应用入口
├── android/                   # Android 平台配置
├── ios/                       # iOS 平台配置
├── assets/                    # 资源文件
│   └── icons/                 # 应用图标
├── test/                      # 测试文件
├── pubspec.yaml               # 依赖配置
└── README.md                  # 项目文档
```

## 🚀 快速开始

### 环境要求

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android Studio / Xcode（用于模拟器）
- VS Code 或 Android Studio（推荐安装 Flutter 插件）

### 安装步骤

1. **克隆项目**
```bash
cd mobile
```

2. **安装依赖**
```bash
flutter pub get
```

3. **运行应用**
```bash
# 查看可用设备
flutter devices

# 运行到指定设备
flutter run

# 运行到 Android 设备
flutter run -d android

# 运行到 iOS 设备（需要 macOS）
flutter run -d ios
```

### 配置后端服务

编辑 `lib/shared/network/config.dart` 文件，配置 API 地址：

```dart
class ApiConfig {
  static const String baseUrl = 'https://api.bitx.com';
  static const String wsUrl = 'wss://api.bitx.com/ws';
}
```

## 🧪 测试

```bash
# 运行所有测试
flutter test

# 运行指定测试文件
flutter test test/features/markets/utils/indicator_calculator_test.dart

# 生成测试覆盖率报告
flutter test --coverage
```

## 📦 构建发布

### Android

```bash
# 构建 APK（调试版）
flutter build apk --debug

# 构建 APK（发布版）
flutter build apk --release

# 构建 App Bundle（推荐用于 Google Play）
flutter build appbundle --release
```

发布版本需要配置签名，编辑 `android/app/build.gradle` 添加签名配置。

### iOS

```bash
# 构建 iOS 应用（需要 macOS）
flutter build ios --release

# 使用 Xcode 打开项目
open ios/Runner.xcworkspace
```

在 Xcode 中配置签名和证书后即可发布到 App Store。

## 🎨 应用图标

应用图标位于 `assets/icons/icon.png`，修改图标后运行以下命令重新生成：

```bash
flutter pub run flutter_launcher_icons
```

或使用 PowerShell 脚本手动生成各尺寸图标（已配置）。

## 🌍 国际化

当前支持语言：
- 简体中文（zh）
- 英语（en）

### 添加新的翻译

1. 编辑 `lib/shared/l10n/app_zh.arb` 和 `app_en.arb`
2. 添加新的键值对
3. 运行 `flutter gen-l10n` 生成代码
4. 在代码中使用：
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Text(AppLocalizations.of(context)!.yourKey)
```

## 🔧 开发规范

### 代码风格

- 遵循 Dart 官方代码规范
- 使用 `flutter_lints` 进行代码检查
- 提交前运行 `flutter analyze` 确保无警告

```bash
# 代码分析
flutter analyze

# 代码格式化
dart format lib/ test/
```

### 状态管理

使用 Riverpod 进行状态管理：

```dart
// 定义 Provider
final counterProvider = StateProvider<int>((ref) => 0);

// 使用 Provider
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    return Text('$count');
  }
}
```

### 网络请求

使用 WebSocket 进行实时数据通信：

```dart
final wsService = WebSocketService();
await wsService.connect();
wsService.subscribe('market.ticker', (data) {
  // 处理数据
});
```

## 📊 性能优化

- 使用 `const` 构造函数减少重建
- 合理使用 Riverpod 的 `select` 避免不必要的刷新
- 图表数据使用分页加载
- WebSocket 连接复用和自动重连
- 图片资源使用适当的分辨率

## 🐛 调试工具

应用内置 WebSocket 调试工具，可在开发模式下访问：

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => WebSocketTestScreen()),
);
```

### 工具链

本项目使用 Speckit 工具链进行开发：

- `/speckit.constitution` - 更新项目宪章
- `/speckit.specify` - 编写功能规格
- `/speckit.plan` - 生成实现计划
- `/speckit.tasks` - 生成任务列表

## 📝 版本历史

### v0.1.0 (当前版本)
- ✅ 实时行情列表
- ✅ K线图表（支持多种时间周期）
- ✅ 技术指标（MACD、KDJ、RSI）
- ✅ 订单簿和交易记录
- ✅ 多图表视图
- ✅ 主题定制
- ✅ 中英文国际化

### 计划功能
- 🔲 交易功能
- 🔲 资产管理
- 🔲 用户认证
- 🔲 推送通知
- 🔲 价格提醒

## 🤝 贡献指南

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

## 📄 许可证

本项目采用 MIT 许可证。


---

**注意**：本项目仅用于学习和研究目的，不构成任何投资建议。加密货币交易存在风险，请谨慎投资。
