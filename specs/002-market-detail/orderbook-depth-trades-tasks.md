# 行情详情页 - 订单簿、深度图、最新成交 - 任务清单

## 概述

**功能名称**: 订单簿、深度图、最新成交  
**所属模块**: 行情详情页 (Market Detail)  
**优先级**: P1 (重要功能)  
**预计工期**: 4-5 个工作日  
**创建日期**: 2026-02-20

## 用户故事

### 用户故事 1 (P1): 订单簿展示
作为交易用户，我希望在行情详情页看到实时订单簿（买卖盘口），包括价格、数量和累计量，以便我了解当前市场的买卖力量分布。

**验收标准**:
- 显示买单（绿色）和卖单（红色）
- 每侧显示至少10档深度
- 实时更新订单簿数据
- 显示价格、数量、累计量
- 支持档位数量切换（10/20/50档）
- 点击价格可快速填充到交易表单

### 用户故事 2 (P1): 深度图展示
作为交易用户，我希望看到市场深度图，直观展示买卖盘的分布情况，以便我快速判断市场流动性和支撑/阻力位。

**验收标准**:
- 显示买卖深度曲线
- 买单绿色区域，卖单红色区域
- X轴显示价格，Y轴显示累计数量
- 支持缩放和拖动
- 鼠标悬停显示详细信息
- 与订单簿数据同步

### 用户故事 3 (P1): 最新成交展示
作为交易用户，我希望看到最新成交记录，包括成交价格、数量和时间，以便我了解市场的实时交易活跃度。

**验收标准**:
- 显示最近50笔成交记录
- 显示成交价格、数量、时间
- 买入成交绿色，卖出成交红色
- 实时更新成交数据
- 支持滚动查看历史成交
- 新成交记录有动画提示

---

## Phase 1: 项目设置

### 任务清单

- [ ] T001 创建订单簿、深度图、最新成交的数据模型 `mobile/lib/features/markets/models/orderbook.dart`, `mobile/lib/features/markets/models/depth_data.dart`, `mobile/lib/features/markets/models/trade.dart`
- [ ] T002 创建订单簿服务 `mobile/lib/features/markets/services/orderbook_service.dart`
- [ ] T003 扩展WebSocket服务支持订单簿和成交订阅 `mobile/lib/shared/network/websocket_service.dart`
- [ ] T004 添加国际化文案（订单簿、深度图、最新成交相关） `mobile/lib/shared/l10n/app_zh.arb`, `mobile/lib/shared/l10n/app_en.arb`

---

## Phase 2: 基础组件开发

### 任务清单

- [ ] T005 [P] 创建订单簿Provider `mobile/lib/features/markets/providers/orderbook_provider.dart`
- [ ] T006 [P] 创建最新成交Provider `mobile/lib/features/markets/providers/trades_provider.dart`
- [ ] T007 [P] 创建深度图数据处理工具 `mobile/lib/features/markets/utils/depth_calculator.dart`

---

## Phase 3: 用户故事 1 - 订单簿展示

**目标**: 实现实时订单簿展示功能

**独立测试标准**:
- 订单簿正确显示买卖盘数据
- 实时更新正常
- 档位切换功能正常
- 点击价格交互正常

### 任务清单

- [ ] T008 [US1] 创建订单簿数据模型 `mobile/lib/features/markets/models/orderbook.dart`
  - OrderbookLevel (单个档位: 价格、数量、累计量)
  - Orderbook (完整订单簿: 买单列表、卖单列表、时间戳)
  - 实现 fromJson 和 toJson 方法

- [ ] T009 [US1] 实现订单簿Provider `mobile/lib/features/markets/providers/orderbook_provider.dart`
  - 订阅WebSocket订单簿数据
  - 实时更新订单簿状态
  - 计算累计量
  - 支持档位数量配置

- [ ] T010 [US1] 创建订单簿组件 `mobile/lib/features/markets/widgets/orderbook_widget.dart`
  - 显示买单列表（绿色）
  - 显示卖单列表（红色）
  - 显示价格、数量、累计量列
  - 背景条显示数量占比
  - 响应式布局

- [ ] T011 [US1] 实现档位切换功能 `mobile/lib/features/markets/widgets/orderbook_widget.dart`
  - 添加档位选择器（10/20/50档）
  - 切换时重新渲染订单簿
  - 保存用户选择

- [ ] T012 [US1] 实现价格点击交互 `mobile/lib/features/markets/widgets/orderbook_widget.dart`
  - 点击价格触发回调
  - 传递价格和数量信息
  - 预留交易表单集成接口

- [ ] T013 [US1] 集成订单簿到详情页 `mobile/lib/features/markets/screens/market_detail_screen.dart`
  - 在价格Tab添加订单簿区域
  - 调整布局结构
  - 处理加载和错误状态

---

## Phase 4: 用户故事 2 - 深度图展示

**目标**: 实现市场深度图可视化

**独立测试标准**:
- 深度图正确显示买卖深度
- 曲线平滑流畅
- 缩放和拖动正常
- 悬停提示正常

### 任务清单

- [ ] T014 [US2] 创建深度图数据模型 `mobile/lib/features/markets/models/depth_data.dart`
  - DepthPoint (深度点: 价格、累计数量)
  - DepthData (完整深度: 买单深度、卖单深度)

- [ ] T015 [US2] 实现深度数据计算工具 `mobile/lib/features/markets/utils/depth_calculator.dart`
  - 从订单簿计算深度数据
  - 数据聚合和平滑处理
  - 计算最大深度值

- [ ] T016 [US2] 创建深度图组件 `mobile/lib/features/markets/widgets/depth_chart_widget.dart`
  - 使用CustomPainter绘制深度图
  - 绘制买单区域（绿色填充）
  - 绘制卖单区域（红色填充）
  - 绘制坐标轴和网格线

- [ ] T017 [US2] 实现深度图交互功能 `mobile/lib/features/markets/widgets/depth_chart_widget.dart`
  - 支持缩放（双指缩放）
  - 支持拖动查看
  - 鼠标/触摸悬停显示详情
  - 十字线跟随

- [ ] T018 [US2] 优化深度图性能 `mobile/lib/features/markets/widgets/depth_chart_widget.dart`
  - 使用RepaintBoundary隔离重绘
  - 限制数据点数量
  - 缓存绘制路径

- [ ] T019 [US2] 集成深度图到详情页 `mobile/lib/features/markets/screens/market_detail_screen.dart`
  - 在价格Tab添加深度图区域
  - 与订单簿数据联动
  - 处理加载和错误状态

---

## Phase 5: 用户故事 3 - 最新成交展示

**目标**: 实现最新成交记录展示

**独立测试标准**:
- 成交记录正确显示
- 实时更新正常
- 买卖方向颜色正确
- 滚动查看正常

### 任务清单

- [ ] T020 [US3] 创建成交数据模型 `mobile/lib/features/markets/models/trade.dart`
  - Trade (成交记录: 价格、数量、时间、方向)
  - 实现 fromJson 方法
  - 添加格式化方法

- [ ] T021 [US3] 实现最新成交Provider `mobile/lib/features/markets/providers/trades_provider.dart`
  - 订阅WebSocket成交数据
  - 维护成交记录列表（最多50条）
  - 实时添加新成交
  - 自动移除旧记录

- [ ] T022 [US3] 创建最新成交组件 `mobile/lib/features/markets/widgets/trades_widget.dart`
  - 显示成交列表
  - 显示价格、数量、时间列
  - 买入绿色，卖出红色
  - 支持滚动查看

- [ ] T023 [US3] 实现新成交动画效果 `mobile/lib/features/markets/widgets/trades_widget.dart`
  - 新成交记录闪烁提示
  - 列表项插入动画
  - 平滑滚动效果

- [ ] T024 [US3] 优化成交列表性能 `mobile/lib/features/markets/widgets/trades_widget.dart`
  - 使用ListView.builder
  - 虚拟滚动优化
  - 防抖更新

- [ ] T025 [US3] 集成最新成交到详情页 `mobile/lib/features/markets/screens/market_detail_screen.dart`
  - 在价格Tab添加成交记录区域
  - 调整布局结构
  - 处理加载和错误状态

---

## Phase 6: 布局整合与优化

### 任务清单

- [ ] T026 重新设计价格Tab布局 `mobile/lib/features/markets/screens/market_detail_screen.dart`
  - 调整K线图、订单簿、深度图、成交记录的布局
  - 支持Tab切换（K线/深度图）
  - 支持分屏显示（订单簿+成交）
  - 响应式适配不同屏幕

- [ ] T027 实现布局配置功能 `mobile/lib/features/markets/providers/layout_provider.dart`
  - 支持用户自定义布局
  - 保存布局配置
  - 提供预设布局模板

- [ ] T028 优化WebSocket订阅管理 `mobile/lib/shared/network/websocket_service.dart`
  - 统一管理订单簿、成交、K线订阅
  - 避免重复订阅
  - 页面切换时智能订阅/取消订阅

- [ ] T029 实现数据同步机制 `mobile/lib/features/markets/providers/market_detail_provider.dart`
  - 确保订单簿、深度图、成交数据一致
  - 处理数据延迟和乱序
  - 实现数据快照和增量更新

---

## Phase 7: 后端API开发

### 任务清单

- [ ] T030 [P] 实现订单簿REST API `backend/src/routes/orderbook.ts`
  - GET /api/orderbook/:symbol - 获取订单簿快照
  - 支持depth参数（10/20/50档）
  - 返回买单和卖单列表

- [ ] T031 [P] 实现成交记录REST API `backend/src/routes/trades.ts`
  - GET /api/trades/:symbol - 获取最新成交
  - 支持limit参数（默认50条）
  - 返回成交记录列表

- [ ] T032 [P] 实现订单簿WebSocket推送 `backend/src/websocket/orderbook.ts`
  - 支持订阅 orderbook.{symbol}
  - 推送增量更新数据
  - 定期推送完整快照

- [ ] T033 [P] 实现成交WebSocket推送 `backend/src/websocket/trades.ts`
  - 支持订阅 trades.{symbol}
  - 实时推送新成交记录
  - 包含价格、数量、时间、方向

- [ ] T034 生成模拟订单簿数据 `backend/src/services/orderbook-generator.ts`
  - 生成合理的买卖盘数据
  - 模拟订单簿变化
  - 确保价格连续性

- [ ] T035 生成模拟成交数据 `backend/src/services/trade-generator.ts`
  - 生成随机成交记录
  - 成交价格在合理范围内
  - 模拟买卖方向分布

---

## Phase 8: 测试与优化

### 任务清单

- [ ] T036 编写订单簿单元测试 `mobile/test/features/markets/models/orderbook_test.dart`
  - 测试数据模型序列化
  - 测试累计量计算
  - 测试数据合并逻辑

- [ ] T037 编写深度计算单元测试 `mobile/test/features/markets/utils/depth_calculator_test.dart`
  - 测试深度数据计算
  - 测试数据聚合
  - 测试边界情况

- [ ] T038 编写组件Widget测试 `mobile/test/features/markets/widgets/orderbook_widget_test.dart`
  - 测试订单簿组件渲染
  - 测试深度图组件渲染
  - 测试成交列表组件渲染

- [ ] T039 性能优化 - 订单簿
  - 优化列表渲染性能
  - 减少不必要的重建
  - 使用const构造函数

- [ ] T040 性能优化 - 深度图
  - 优化Canvas绘制
  - 缓存绘制路径
  - 限制重绘频率

- [ ] T041 性能优化 - 成交列表
  - 优化列表滚动性能
  - 虚拟滚动实现
  - 防抖更新机制

- [ ] T042 内存优化
  - 限制数据缓存大小
  - 及时释放资源
  - 检测内存泄漏

- [ ] T043 手动测试
  - 测试所有功能正常
  - 测试不同屏幕尺寸
  - 测试网络异常情况
  - 测试性能指标

---

## Phase 9: 文档与交付

### 任务清单

- [ ] T044 更新功能规格文档 `specs/002-market-detail/spec.md`
  - 添加订单簿功能说明
  - 添加深度图功能说明
  - 添加最新成交功能说明

- [ ] T045 更新技术实现文档 `specs/002-market-detail/plan.md`
  - 添加数据模型说明
  - 添加组件设计说明
  - 添加API接口说明

- [ ] T046 编写组件使用文档 `docs/components/orderbook.md`
  - 订单簿组件使用说明
  - 深度图组件使用说明
  - 成交列表组件使用说明

- [ ] T047 更新API文档 `backend/docs/api/orderbook.md`
  - REST API接口文档
  - WebSocket订阅文档
  - 数据格式说明

- [ ] T048 创建功能演示视频
  - 录制功能演示
  - 展示交互效果
  - 说明使用方法

---

## 依赖关系

### 用户故事完成顺序

```
Phase 1 (Setup) → Phase 2 (Foundation)
                ↓
Phase 3 (US1: 订单簿) → Phase 6 (Integration)
                ↓              ↓
Phase 4 (US2: 深度图) → Phase 7 (Backend)
                ↓              ↓
Phase 5 (US3: 最新成交) → Phase 8 (Testing)
                                ↓
                         Phase 9 (Documentation)
```

### 任务依赖

- T008-T013 (US1) 可以独立完成
- T014-T019 (US2) 依赖 T008-T009 (订单簿数据)
- T020-T025 (US3) 可以独立完成
- T026-T029 (Integration) 依赖 US1, US2, US3 完成
- T030-T035 (Backend) 可以并行开发
- T036-T043 (Testing) 依赖对应功能完成

### 并行执行机会

**Phase 3 并行任务**:
- T008 (数据模型) 和 T010 (UI组件) 可以并行
- T009 (Provider) 和 T011 (档位切换) 可以并行

**Phase 4 并行任务**:
- T014 (数据模型) 和 T016 (UI组件) 可以并行
- T015 (计算工具) 和 T017 (交互功能) 可以并行

**Phase 5 并行任务**:
- T020 (数据模型) 和 T022 (UI组件) 可以并行
- T021 (Provider) 和 T023 (动画效果) 可以并行

**Phase 7 并行任务**:
- T030-T035 所有后端任务可以并行开发

---

## 实施策略

### MVP范围 (最小可行产品)

**第一阶段** (2天):
- 完成 Phase 1-2 (Setup + Foundation)
- 完成 Phase 3 (US1: 订单簿基础功能)
- 完成 Phase 7 部分 (T030, T032, T034 - 订单簿后端)

**第二阶段** (1.5天):
- 完成 Phase 4 (US2: 深度图)
- 完成 Phase 5 (US3: 最新成交)
- 完成 Phase 7 剩余 (T031, T033, T035 - 成交后端)

**第三阶段** (1.5天):
- 完成 Phase 6 (布局整合)
- 完成 Phase 8 (测试优化)
- 完成 Phase 9 (文档)

### 增量交付

- **Sprint 1**: 订单簿基础展示 (可独立测试和演示)
- **Sprint 2**: 深度图和最新成交 (可独立测试和演示)
- **Sprint 3**: 布局整合和优化 (完整功能交付)

---

## 验收标准

### 功能验收

- [ ] 订单簿正确显示买卖盘数据
- [ ] 订单簿实时更新正常
- [ ] 档位切换功能正常
- [ ] 深度图正确显示买卖深度
- [ ] 深度图缩放和拖动正常
- [ ] 深度图悬停提示正常
- [ ] 最新成交记录正确显示
- [ ] 成交记录实时更新正常
- [ ] 成交记录颜色区分正确
- [ ] 布局整合合理美观
- [ ] 所有交互功能正常

### 性能验收

- [ ] 订单簿更新延迟 < 100ms
- [ ] 深度图渲染流畅 60fps
- [ ] 成交列表滚动流畅
- [ ] 内存占用稳定
- [ ] 无内存泄漏

### UI/UX验收

- [ ] 布局清晰易读
- [ ] 颜色区分明显
- [ ] 响应式适配正常
- [ ] 加载状态友好
- [ ] 错误提示清晰

### 代码质量验收

- [ ] 代码分析 0 error
- [ ] 单元测试覆盖率 > 80%
- [ ] 组件模块化设计
- [ ] 注释清晰完整

---

## 风险与缓解

### 风险1: 订单簿数据量大导致性能问题

**风险等级**: 高  
**缓解措施**:
- 限制显示档位数量
- 使用虚拟滚动
- 优化列表渲染
- 防抖更新机制

### 风险2: 深度图绘制性能问题

**风险等级**: 中  
**缓解措施**:
- 使用RepaintBoundary
- 缓存绘制路径
- 限制数据点数量
- 优化Canvas绘制

### 风险3: WebSocket数据乱序

**风险等级**: 中  
**缓解措施**:
- 使用序列号排序
- 定期请求快照
- 实现数据校验
- 错误自动恢复

### 风险4: 布局复杂度高

**风险等级**: 中  
**缓解措施**:
- 提前设计布局方案
- 使用灵活的布局组件
- 支持用户自定义
- 充分测试不同屏幕

---

## 技术栈

### 前端
- Flutter 3.38.1
- Riverpod (状态管理)
- CustomPainter (深度图绘制)
- WebSocket (实时数据)

### 后端
- Node.js + TypeScript
- WebSocket (数据推送)
- REST API (快照数据)

---

## 总结

**总任务数**: 48个  
**预计工期**: 4-5个工作日  
**并行机会**: 15+个任务可并行  
**MVP范围**: Phase 1-3 + 部分Phase 7 (约2天)

**关键里程碑**:
1. Day 2: 订单簿基础功能完成
2. Day 3.5: 深度图和成交记录完成
3. Day 5: 完整功能交付

---

**文档版本**: v1.0  
**创建日期**: 2026-02-20  
**状态**: ✅ 任务清单已生成

