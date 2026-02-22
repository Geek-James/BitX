# Tasks: 行情模块 - 实时价格展示

**Feature Branch**: `001-markets-realtime`  
**Created**: 2026-02-18  
**Status**: Ready for Implementation  
**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)

## 概述

本文档将行情模块的实现拆分为可执行的任务列表，按用户故事组织，支持独立实现和测试。

**总任务数**: 35 个任务  
**MVP 范围**: Phase 3 (User Story 1) - 查看实时价格列表

---

## 任务执行策略

### 增量交付策略

1. **MVP First**: 优先完成 User Story 1（查看实时价格列表），实现核心价值
2. **Independent Stories**: 每个用户故事可以独立实现和测试
3. **Parallel Execution**: 标记 [P] 的任务可以并行执行
4. **Dependency Order**: 按 Phase 顺序执行，每个 Phase 完成后进行独立测试

### 并行执行机会

- **Phase 1 (Setup)**: T001-T003 可以并行执行（移动端和后端独立）
- **Phase 2 (Foundational)**: T004-T007 可以并行执行（不同文件）
- **Phase 3 (US1)**: T008-T011 可以并行执行（模型和 Provider）
- **Phase 4 (US2)**: T016-T018 可以并行执行（不同组件）
- **Phase 5 (US3)**: T021-T023 可以并行执行（不同组件）
- **Phase 6 (US4)**: T026-T028 可以并行执行（不同文件）

---

## Phase 1: Setup（项目设置）

**目标**: 准备开发环境，确保所有依赖已安装

**任务列表**:

- [ ] T001 [P] 验证移动端依赖已安装 - 检查 mobile/pubspec.yaml 中的 flutter_riverpod, web_socket_channel, intl 是否已添加
- [ ] T002 [P] 验证后端依赖已安装 - 检查 backend/package.json 中的 express, ws, dotenv 是否已添加
- [ ] T003 [P] 创建后端行情模块目录结构 - 创建 backend/src/modules/markets/ 目录及子目录

**完成标准**: 
- 所有依赖包已安装
- 目录结构已创建
- 可以运行 `flutter pub get` 和 `npm install` 无错误

---

## Phase 2: Foundational（基础设施）

**目标**: 实现所有用户故事依赖的共享基础设施

**任务列表**:

- [ ] T004 [P] 完善 WebSocket 服务日志功能 - 在 mobile/lib/shared/network/websocket_service.dart 中添加结构化日志（连接、断开、错误）
- [ ] T005 [P] 验证国际化资源完整性 - 检查 mobile/lib/shared/l10n/app_zh.arb 和 app_en.arb 是否包含所有必需文案
- [ ] T006 [P] 验证骨架屏组件 - 检查 mobile/lib/shared/ui/skeleton_loader.dart 中的 MarketListSkeleton 组件是否完整
- [ ] T007 [P] 创建后端日志工具 - 创建 backend/src/common/logger/logger.ts 实现结构化日志

**完成标准**:
- WebSocket 服务包含完整的日志记录
- 国际化资源包含所有必需文案
- 骨架屏组件可以正常显示
- 后端日志工具可以使用

**独立测试**: 
- 启动移动端，查看日志输出是否正确
- 切换语言，验证所有文案是否正确显示
- 显示骨架屏，验证动画效果

---

## Phase 3: User Story 1 - 查看实时价格列表 (P1)

**用户故事**: 用户打开 App 后，进入行情页面，可以看到主流交易对的实时价格、24小时涨跌幅、24小时成交量等关键信息。价格通过 WebSocket 实时更新，涨跌用颜色标识。

**独立测试标准**: 
- 启动 App，进入行情页面
- 在 2 秒内显示至少 10 个交易对的价格列表
- 价格每秒更新，涨跌颜色正确显示（涨绿跌红）
- 界面保持 60 fps 流畅度

**任务列表**:

### 后端实现

- [ ] T008 [P] [US1] 创建 MarketTicker DTO - 在 backend/src/modules/markets/dto/market-ticker.dto.ts 中定义数据传输对象
- [ ] T009 [P] [US1] 实现 MarketsService - 在 backend/src/modules/markets/markets.service.ts 中实现行情数据生成逻辑（模拟数据）
- [ ] T010 [US1] 实现 MarketsGateway - 在 backend/src/modules/markets/markets.gateway.ts 中实现 WebSocket 网关（订阅、推送、心跳）
- [ ] T011 [US1] 集成 MarketsGateway 到主服务 - 在 backend/src/main.ts 中启动 WebSocket 服务器

### 移动端实现

- [ ] T012 [P] [US1] 验证 MarketTicker 模型 - 检查 mobile/lib/features/markets/models/market_ticker.dart 是否完整实现
- [ ] T013 [P] [US1] 验证 WebSocket 服务 - 检查 mobile/lib/shared/network/websocket_service.dart 是否完整实现连接、订阅、心跳逻辑
- [ ] T014 [US1] 验证 MarketsProvider - 检查 mobile/lib/features/markets/providers/markets_provider.dart 是否正确配置 StreamProvider
- [ ] T015 [US1] 验证行情页面 UI - 检查 mobile/lib/features/markets/screens/markets_screen.dart 是否完整实现价格列表、Tab 切换、骨架屏

**完成标准**:
- 后端 WebSocket 服务可以启动并推送模拟数据
- 移动端可以连接后端并接收数据
- 行情页面显示至少 10 个交易对
- 价格实时更新，涨跌颜色正确
- 首屏加载时间 < 2 秒

**验收测试**:
1. 启动后端: `cd backend && npm run start:dev`
2. 启动移动端: `cd mobile && flutter run`
3. 进入行情页面，验证价格列表显示
4. 观察价格是否每秒更新
5. 验证涨跌颜色（绿色/红色）

---

## Phase 4: User Story 2 - WebSocket 连接管理与重连 (P1)

**用户故事**: 当用户在行情页面时，App 自动建立 WebSocket 连接订阅行情数据。当网络断开或连接异常时，App 自动重连并恢复订阅。

**独立测试标准**:
- 启动 App 进入行情页面，WebSocket 在 3 秒内连接成功
- 手动关闭网络，App 显示"连接中断"提示
- 恢复网络，App 在 5 秒内自动重连成功
- 重连使用指数退避策略（1s、2s、4s、8s）

**任务列表**:

### 移动端实现

- [ ] T016 [P] [US2] 完善 WebSocket 重连逻辑 - 在 mobile/lib/shared/network/websocket_service.dart 中验证指数退避重连逻辑（1s、2s、4s、8s，最多10次）
- [ ] T017 [P] [US2] 完善连接状态 UI - 在 mobile/lib/features/markets/screens/markets_screen.dart 中验证连接状态提示横幅（连接中、错误、重试按钮）
- [ ] T018 [US2] 实现手动重试功能 - 在 WebSocketService 中添加 retry() 方法，重置重连计数器

### 后端实现

- [ ] T019 [P] [US2] 实现连接超时检测 - 在 backend/src/modules/markets/markets.gateway.ts 中添加 90 秒无消息自动断开逻辑
- [ ] T020 [US2] 添加连接日志 - 在 MarketsGateway 中记录客户端连接、断开、订阅、取消订阅日志

**完成标准**:
- WebSocket 连接断开后自动重连
- 使用指数退避策略
- 显示连接状态提示
- 提供手动重试按钮
- 后端记录连接日志

**验收测试**:
1. 启动 App，进入行情页面
2. 关闭后端服务，观察 App 显示"连接中断"
3. 重启后端服务，观察 App 自动重连
4. 验证重连间隔（1s、2s、4s、8s）
5. 点击"重试"按钮，验证立即重连

---

## Phase 5: User Story 3 - 搜索与筛选交易对 (P2)

**用户故事**: 用户可以通过搜索框输入交易对名称快速找到相关交易对，也可以通过筛选条件查看特定排序的交易对列表。

**独立测试标准**:
- 在搜索框输入 "BTC"，实时过滤显示包含 BTC 的交易对
- 点击"涨幅榜"，列表按涨幅从高到低排序
- 点击"跌幅榜"，列表按跌幅从高到低排序
- 点击"成交量榜"，列表按成交量从高到低排序

**任务列表**:

### 移动端实现

- [ ] T021 [P] [US3] 验证 MarketFilter 模型 - 检查 mobile/lib/features/markets/models/market_filter.dart 是否完整实现搜索和排序逻辑
- [ ] T022 [P] [US3] 验证搜索框 UI - 检查 mobile/lib/features/markets/screens/markets_screen.dart 中的搜索框是否完整（输入、清空按钮）
- [ ] T023 [P] [US3] 验证筛选按钮 UI - 检查 markets_screen.dart 中的筛选按钮（默认、涨幅榜、跌幅榜、成交量榜）
- [ ] T024 [US3] 实现筛选逻辑集成 - 在 markets_provider.dart 中验证 filteredTickersProvider 正确应用 MarketFilter
- [ ] T025 [US3] 优化搜索性能 - 添加防抖（debounce）避免频繁过滤

**完成标准**:
- 搜索框可以输入和清空
- 筛选按钮可以切换
- 搜索和筛选实时生效
- 搜索性能良好（无卡顿）

**验收测试**:
1. 在搜索框输入 "BTC"，验证过滤结果
2. 清空搜索框，验证恢复完整列表
3. 点击"涨幅榜"，验证排序正确
4. 点击"跌幅榜"，验证排序正确
5. 点击"成交量榜"，验证排序正确

---

## Phase 6: User Story 4 - 多语言支持 (P2)

**用户故事**: 行情页面的所有文案支持简体中文和英语，根据系统语言自动切换。

**独立测试标准**:
- 系统语言为中文时，所有文案显示中文
- 系统语言为英语时，所有文案显示英语
- 数字格式根据语言规范正确显示

**任务列表**:

### 移动端实现

- [ ] T026 [P] [US4] 完善中文 ARB 文件 - 在 mobile/lib/shared/l10n/app_zh.arb 中添加所有缺失的文案
- [ ] T027 [P] [US4] 完善英文 ARB 文件 - 在 mobile/lib/shared/l10n/app_en.arb 中添加所有缺失的文案
- [ ] T028 [P] [US4] 实现数字格式化工具 - 创建 mobile/lib/shared/utils/number_formatter.dart 实现千分位、小数点格式化
- [ ] T029 [US4] 集成数字格式化 - 在 MarketTicker 模型和 UI 组件中使用数字格式化工具
- [ ] T030 [US4] 验证语言切换 - 在 main.dart 中验证 localizationsDelegates 和 supportedLocales 配置正确

**完成标准**:
- 所有文案都有中英文翻译
- 数字格式根据语言正确显示
- 语言切换后界面立即生效

**验收测试**:
1. 将系统语言设置为中文，启动 App
2. 验证所有文案显示中文
3. 将系统语言设置为英语，重启 App
4. 验证所有文案显示英语
5. 验证数字格式（千分位、小数点）

---

## Phase 7: Polish & Testing（优化与测试）

**目标**: 性能优化、测试覆盖、文档完善

**任务列表**:

### 性能优化

- [ ] T031 [P] 优化 ListView 性能 - 在 markets_screen.dart 中确保使用 ListView.builder 和 const 构造函数
- [ ] T032 [P] 优化 Riverpod 刷新 - 在 markets_provider.dart 中使用 select 精细化订阅，减少不必要的重建
- [ ] T033 验证性能指标 - 使用 Flutter DevTools 验证 60 fps 和首屏加载时间 < 2 秒

### 测试

- [ ] T034 [P] 编写移动端单元测试 - 创建 mobile/test/unit/markets_test.dart 测试 MarketTicker、MarketFilter 模型
- [ ] T035 [P] 编写后端单元测试 - 创建 backend/tests/unit/markets.service.spec.ts 测试 MarketsService

**完成标准**:
- 行情页面保持 60 fps
- 首屏加载时间 < 2 秒
- 单元测试覆盖核心逻辑
- 所有测试通过

**验收测试**:
1. 使用 Flutter DevTools 监控性能
2. 验证 fps 保持在 60 左右
3. 验证首屏加载时间
4. 运行单元测试: `flutter test` 和 `npm test`

---

## 依赖关系图

```
Phase 1 (Setup)
    ↓
Phase 2 (Foundational)
    ↓
    ├─→ Phase 3 (US1: 查看实时价格列表) [P1] ← MVP
    │       ↓
    ├─→ Phase 4 (US2: WebSocket 连接管理) [P1]
    │       ↓
    ├─→ Phase 5 (US3: 搜索与筛选) [P2]
    │       ↓
    └─→ Phase 6 (US4: 多语言支持) [P2]
            ↓
        Phase 7 (Polish & Testing)
```

**说明**:
- Phase 1 和 Phase 2 是所有用户故事的前置依赖
- Phase 3 (US1) 是 MVP，必须优先完成
- Phase 4 (US2) 依赖 Phase 3（需要先有基本的 WebSocket 连接）
- Phase 5 (US3) 和 Phase 6 (US4) 可以在 Phase 3 完成后并行开发
- Phase 7 在所有功能完成后进行

---

## 任务统计

| Phase | 任务数 | 可并行任务数 | 预估时间 |
|-------|--------|--------------|----------|
| Phase 1: Setup | 3 | 3 | 0.5 天 |
| Phase 2: Foundational | 4 | 4 | 1 天 |
| Phase 3: US1 (P1) | 8 | 4 | 2 天 |
| Phase 4: US2 (P1) | 5 | 3 | 1 天 |
| Phase 5: US3 (P2) | 5 | 3 | 1 天 |
| Phase 6: US4 (P2) | 5 | 3 | 1 天 |
| Phase 7: Polish | 5 | 3 | 1 天 |
| **总计** | **35** | **23** | **7.5 天** |

---

## MVP 范围建议

**建议 MVP**: Phase 1 + Phase 2 + Phase 3 (User Story 1)

**理由**:
- User Story 1 是核心功能，提供最大价值
- 完成后可以独立测试和演示
- 其他用户故事可以增量添加

**MVP 任务数**: 15 个任务  
**MVP 预估时间**: 3.5 天

---

## 实施建议

### 第一周

- **Day 1-2**: 完成 Phase 1 (Setup) + Phase 2 (Foundational)
- **Day 3-4**: 完成 Phase 3 (US1) - MVP 交付
- **Day 5**: 完成 Phase 4 (US2) - 增强稳定性

### 第二周

- **Day 1**: 完成 Phase 5 (US3) - 搜索与筛选
- **Day 2**: 完成 Phase 6 (US4) - 多语言支持
- **Day 3-4**: 完成 Phase 7 (Polish & Testing)
- **Day 5**: 代码评审、文档更新、发布准备

---

## 下一步

1. **开始实施**: 按 Phase 顺序执行任务
2. **MVP 优先**: 先完成 Phase 1-3，实现核心价值
3. **增量交付**: 每个 Phase 完成后进行独立测试
4. **持续集成**: 每个任务完成后提交代码

**建议命令**: 
```bash
# 启动后端开发服务器
cd backend && npm run start:dev

# 启动移动端（另一个终端）
cd mobile && flutter run
```

---

**任务列表生成完成！** 🚀

现在可以开始按 Phase 顺序实施任务。建议先完成 MVP（Phase 1-3），然后增量添加其他功能。


