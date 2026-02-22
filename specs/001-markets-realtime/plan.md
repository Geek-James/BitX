# Implementation Plan: 行情模块 - 实时价格展示

**Branch**: `001-markets-realtime` | **Date**: 2026-02-12 | **Spec**: [spec.md](./spec.md)

## Summary

实现行情模块的实时价格展示功能，包括：通过 WebSocket 接收并展示主流交易对的实时价格、24小时涨跌幅、成交量等数据；支持搜索与筛选交易对；支持简体中文和英语两种语言；确保首屏加载时间 < 2 秒，界面保持 60 fps 流畅度。

技术方案：移动端使用 Flutter + Riverpod 构建行情页面，通过 `web_socket_channel` 包建立 WebSocket 连接订阅行情数据；后端使用 Node.js 提供 WebSocket 服务推送实时行情数据。

## Technical Context

**语言/版本（Language/Version）**: 
- 移动端：Dart / Flutter 3.38.1
- 后端：Node.js（Express + ws 库）

**主要依赖（Primary Dependencies）**: 
- 移动端：
  - flutter_riverpod: ^2.4.0（状态管理）
  - web_socket_channel: ^2.4.0（WebSocket 客户端）
  - intl: ^0.18.0（国际化）
- 后端：
  - express: ^4.18.0（HTTP 服务器）
  - ws: ^8.13.0（WebSocket 服务器）

**存储（Storage）**: 
- 后端：行情数据从第三方行情源（如币安 API）获取，不持久化存储，仅在内存中缓存最新数据
- 移动端：无需本地存储，所有数据通过 WebSocket 实时获取

**测试（Testing）**: 
- 移动端：flutter_test（单元测试）、integration_test（集成测试）
- 后端：Jest（单元测试、集成测试）

**目标平台（Target Platform）**: 移动端（iOS 与 Android，最低版本 iOS 12+、Android 5.0+）+ 后端服务（独立部署）

**项目类型（Project Type）**: mobile + backend（前后端分离）

**性能目标（Performance Goals）**: 
- 行情页面首屏加载时间 < 2 秒
- 行情页面保持 60 fps 流畅度
- WebSocket 消息处理延迟 < 100ms
- 长时间停留（1 小时）内存增长 < 50MB

**约束（Constraints）**: 
- WebSocket 连接必须使用 TLS 加密（wss://）
- 行情数据为公开数据，无需用户认证
- 必须支持自动重连（指数退避策略，最多 10 次）
- 所有文案必须通过本地化资源管理，禁止硬编码中文/英文

**规模/范围（Scale/Scope）**: 
- 支持至少 10 个主流交易对（BTC/USDT、ETH/USDT 等）
- 支持简体中文和英语两种语言
- 预期同时在线用户数：1000+（初期）

## Constitution Check

### ✅ 安全与合规优先（Security & Compliance First）

- **评估结果**：通过
- **说明**：行情数据为公开数据，无需用户认证，不涉及用户资金或敏感信息。WebSocket 连接使用 TLS 加密（wss://），符合安全要求。
- **规格中的体现**：SEC-001 要求 WebSocket 使用 TLS 加密；SEC-002 明确行情数据为公开数据。

### ✅ 交易体验与性能（Trading Experience & Performance）

- **评估结果**：通过
- **说明**：规格中明确定义了性能目标：首屏加载 < 2 秒、保持 60 fps 流畅度、WebSocket 消息处理延迟 < 100ms。
- **规格中的体现**：
  - PERF-001: 首屏加载时间 < 2 秒
  - PERF-002: 保持 60 fps 流畅度
  - PERF-003: WebSocket 消息处理延迟 < 100ms
  - SC-002: 通过 Flutter DevTools 验证 60 fps

### ✅ 领域边界（Domain Boundaries）

- **评估结果**：通过
- **说明**：行情模块属于独立的业务领域，代码将放在 `mobile/lib/features/markets/` 目录下。依赖的共享模块包括：网络层（WebSocket）、国际化（l10n）、UI 组件（shared/ui）。
- **规格中的体现**：明确说明行情模块是独立的业务域，不依赖其他业务模块（合约、现货、跟单、资产）。

### ✅ 可靠性与可观测性（Reliability & Observability）

- **评估结果**：通过
- **说明**：规格中明确定义了错误处理、日志与监控要求。
- **规格中的体现**：
  - FR-010: 记录 WebSocket 连接状态变更日志
  - FR-011: 记录价格更新异常日志
  - FR-012: 向用户显示可理解的错误提示
  - OBS-001/002/003: 详细的可观测性要求

### ✅ 规格驱动与测试优先（Spec-Driven, Test-First Delivery）

- **评估结果**：通过
- **说明**：已完成功能规格文档（spec.md），包含 4 个用户故事、验收标准、功能需求、成功标准。每个用户故事都可以独立测试。
- **规格中的体现**：每个用户故事都包含 "Independent Test" 说明和详细的验收场景。

### ✅ 国际化与多语言体验（Internationalization & Localization）

- **评估结果**：通过
- **说明**：规格中明确要求支持简体中文和英语，所有文案通过本地化资源管理。
- **规格中的体现**：
  - I18N-001: 支持简体中文和英语
  - I18N-002: 文案通过本地化资源管理
  - I18N-003: 禁止硬编码中文/英文字符串
  - I18N-004: 数字格式根据语言规范显示
  - User Story 4: 专门的多语言支持用户故事

### 宪章检查结论

✅ **所有宪章检查项通过，可以进入 Phase 0 研究阶段。**

## Project Structure

### Documentation (this feature)

```text
specs/001-markets-realtime/
├── spec.md              # 功能规格（已完成）
├── plan.md              # 本文件（实现计划）
├── research.md          # Phase 0 输出（技术研究）
├── data-model.md        # Phase 1 输出（数据模型）
├── quickstart.md        # Phase 1 输出（快速开始指南）
├── contracts/           # Phase 1 输出（API 契约）
│   └── websocket.md     # WebSocket 接口定义
└── tasks.md             # Phase 2 输出（任务列表，由 /speckit.tasks 生成）
```

### Source Code (repository root)

```text
backend/
├── src/
│   ├── modules/
│   │   └── markets/          # 行情模块
│   │       ├── markets.service.ts    # 行情服务（获取数据、WebSocket 推送）
│   │       ├── markets.controller.ts # HTTP 接口（可选）
│   │       └── markets.gateway.ts    # WebSocket 网关
│   ├── common/
│   │   ├── websocket/        # WebSocket 基础设施
│   │   └── logger/           # 日志工具
│   └── main.ts
├── tests/
│   ├── unit/
│   │   └── markets.service.spec.ts
│   └── integration/
│       └── markets.gateway.spec.ts
└── docs/api/
    └── websocket.md          # WebSocket API 文档

mobile/
├── lib/
│   ├── features/
│   │   └── markets/          # 行情模块
│   │       ├── models/       # 数据模型（MarketTicker）
│   │       ├── providers/    # Riverpod 状态管理
│   │       ├── widgets/      # UI 组件（价格列表、搜索框等）
│   │       └── screens/      # 页面（行情页面）
│   ├── shared/
│   │   ├── network/          # WebSocket 客户端封装
│   │   ├── l10n/             # 国际化资源
│   │   │   ├── app_zh.arb    # 简体中文
│   │   │   └── app_en.arb    # 英语
│   │   └── ui/               # 共享 UI 组件
│   └── main.dart
└── test/
    ├── unit/
    │   └── markets_test.dart
    └── integration/
        └── markets_integration_test.dart
```

**Structure Decision**: 采用 Mobile + Backend 前后端分离结构。行情模块在移动端和后端都有独立的目录（`features/markets/` 和 `modules/markets/`），符合宪章的领域边界要求。共享模块（网络、国际化、UI）放在 `mobile/lib/shared/` 下。

## Complexity Tracking

无宪章违规，无需填写此表。

---

## Phase 0: Research & Technical Decisions

### 研究任务

1. **WebSocket 库选择（移动端）**
   - 研究 `web_socket_channel` vs `socket_io_client`
   - 决策：使用 `web_socket_channel`（Flutter 官方推荐，轻量级）

2. **WebSocket 库选择（后端）**
   - 研究 `ws` vs `socket.io`
   - 决策：使用 `ws`（轻量级，符合标准 WebSocket 协议）

3. **状态管理方案**
   - 研究 Riverpod 的最佳实践（StreamProvider vs StateNotifierProvider）
   - 决策：使用 `StreamProvider` 监听 WebSocket 数据流

4. **重连策略实现**
   - 研究指数退避算法实现
   - 决策：使用 `Timer` + 指数退避（1s、2s、4s、8s，最多 10 次）

5. **国际化方案**
   - 研究 Flutter 国际化最佳实践（ARB 文件 vs 代码生成）
   - 决策：使用 ARB 文件 + `flutter_localizations`

6. **性能优化**
   - 研究 ListView 性能优化（ListView.builder vs ListView.separated）
   - 研究 Riverpod 精细化刷新策略
   - 决策：使用 `ListView.builder` + `select` 精细化订阅

### 研究输出文档

详见 `research.md`

---

## Phase 1: Design & Contracts

### 数据模型设计

详见 `data-model.md`

**核心实体**：

1. **MarketTicker（行情数据）**
   ```dart
   class MarketTicker {
     final String symbol;        // 交易对符号，如 "BTCUSDT"
     final double price;          // 当前价格
     final double change24h;      // 24小时涨跌幅（百分比）
     final double volume24h;      // 24小时成交量
     final double high24h;        // 24小时最高价
     final double low24h;         // 24小时最低价
     final DateTime timestamp;    // 数据时间戳
   }
   ```

2. **WebSocketConnectionState（连接状态）**
   ```dart
   enum ConnectionStatus {
     connecting,    // 连接中
     connected,     // 已连接
     disconnected,  // 已断开
     error,         // 错误
   }
   
   class WebSocketConnectionState {
     final ConnectionStatus status;
     final int retryCount;
     final String? lastError;
   }
   ```

### API 契约设计

详见 `contracts/websocket.md`

**WebSocket 端点**：`wss://api.cybitx.com/ws/markets`

**订阅消息**：
```json
{
  "action": "subscribe",
  "channel": "market.all"
}
```

**数据推送消息**：
```json
{
  "type": "data",
  "channel": "market.all",
  "data": [
    {
      "symbol": "BTCUSDT",
      "price": "45000.50",
      "change24h": "2.5",
      "volume24h": "1234567890",
      "high24h": "46000.00",
      "low24h": "44000.00",
      "timestamp": 1234567890
    }
  ]
}
```

**心跳消息**：
```json
// 客户端 -> 服务器
{"action": "ping"}

// 服务器 -> 客户端
{"type": "pong", "timestamp": 1234567890}
```

### 快速开始指南

详见 `quickstart.md`

---

## Phase 2: Implementation Planning

实现计划将在 Phase 1 完成后，通过 `/speckit.tasks` 命令生成详细的任务列表（`tasks.md`）。

### 预期任务分组

1. **Phase 1: Setup（项目设置）**
   - 添加依赖包（web_socket_channel、intl 等）
   - 创建目录结构

2. **Phase 2: Foundational（基础设施）**
   - 实现 WebSocket 客户端封装（连接、重连、心跳）
   - 实现国际化资源文件（ARB）
   - 实现日志工具

3. **Phase 3: User Story 1 - 查看实时价格列表（P1）**
   - 实现 MarketTicker 数据模型
   - 实现 Riverpod Provider（WebSocket 数据流）
   - 实现行情页面 UI（价格列表）
   - 实现涨跌颜色标识

4. **Phase 4: User Story 2 - WebSocket 连接管理与重连（P1）**
   - 实现自动重连逻辑（指数退避）
   - 实现连接状态提示 UI
   - 实现重试按钮

5. **Phase 5: User Story 3 - 搜索与筛选交易对（P2）**
   - 实现搜索框 UI
   - 实现搜索过滤逻辑
   - 实现筛选按钮（涨幅榜、跌幅榜、成交量榜）
   - 实现排序逻辑

6. **Phase 6: User Story 4 - 多语言支持（P2）**
   - 完善 ARB 文件（所有文案）
   - 实现语言切换逻辑
   - 实现数字格式化（千分位、小数点）

7. **Phase 7: Polish & Testing（优化与测试）**
   - 性能优化（ListView、Riverpod 精细化刷新）
   - 单元测试
   - 集成测试
   - 文档更新

---

## Next Steps

1. ✅ **Phase 0 完成**：创建 `research.md`，记录技术决策
2. ⏭️ **Phase 1 进行中**：创建 `data-model.md`、`contracts/websocket.md`、`quickstart.md`
3. ⏭️ **Phase 2 待开始**：运行 `/speckit.tasks` 生成任务列表

---

## 附录：关键决策记录

| 决策点 | 选择 | 理由 |
|--------|------|------|
| WebSocket 库（移动端） | web_socket_channel | Flutter 官方推荐，轻量级，符合标准协议 |
| WebSocket 库（后端） | ws | 轻量级，性能好，符合标准协议 |
| 状态管理 | Riverpod StreamProvider | 适合 WebSocket 数据流，支持精细化刷新 |
| 国际化方案 | ARB 文件 + flutter_localizations | Flutter 官方推荐，易于维护 |
| 列表组件 | ListView.builder | 性能好，支持懒加载 |
| 重连策略 | 指数退避（1s、2s、4s、8s） | 平衡重连速度与服务器压力 |

