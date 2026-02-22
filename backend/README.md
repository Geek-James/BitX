# CybitX Backend Service

CybitX CEX 应用的 Node.js 后端服务，负责核心业务逻辑、数据持久化与 API 接口实现。

## 技术栈

- **运行时**：Node.js (推荐 LTS 版本)
- **框架**：NestJS / Express（待确定）
- **语言**：TypeScript
- **数据库**：待定（例如 PostgreSQL、MongoDB 等）
- **缓存**：待定（例如 Redis）
- **消息队列**：待定（例如 RabbitMQ、Kafka 等）

## 目录结构

```
backend/
├── src/
│   ├── modules/          # 业务模块（用户、订单、资产、行情、跟单等）
│   ├── common/           # 共享工具、中间件、装饰器、守卫等
│   └── main.ts           # 应用入口
├── tests/
│   ├── unit/             # 单元测试
│   ├── integration/      # 集成测试
│   └── e2e/              # 端到端测试
├── docs/
│   └── api/              # API 契约文档（OpenAPI/Swagger、WebSocket 规范）
├── package.json          # 依赖管理
└── README.md             # 本文件
```

## 环境变量要求

创建 `.env` 文件（不要提交到代码仓库），包含以下配置：

```env
# 应用配置
NODE_ENV=development
PORT=3000

# 数据库配置
DATABASE_URL=postgresql://user:password@localhost:5432/cybitx

# Redis 配置
REDIS_HOST=localhost
REDIS_PORT=6379

# JWT 配置
JWT_SECRET=your-secret-key
JWT_EXPIRES_IN=7d

# WebSocket 配置
WS_PORT=3001

# 其他配置...
```

## 本地开发指引

### 前置要求

- Node.js >= 16.x
- npm 或 yarn
- 数据库（PostgreSQL / MongoDB 等）
- Redis（可选，用于缓存）

### 安装依赖

```bash
cd backend
npm install
# 或
yarn install
```

### 启动开发服务器

```bash
npm run dev
# 或
yarn dev
```

后端服务将在 `http://localhost:3000` 启动。

### 运行测试

```bash
# 单元测试
npm run test

# 集成测试
npm run test:integration

# 端到端测试
npm run test:e2e

# 测试覆盖率
npm run test:cov
```

### 数据库迁移

```bash
# 创建迁移
npm run migration:create

# 运行迁移
npm run migration:run

# 回滚迁移
npm run migration:revert
```

## API 文档

- **RESTful API**：启动服务后访问 `http://localhost:3000/api/docs`（Swagger UI）
- **WebSocket**：参考 `docs/api/websocket.md`

## 健康检查

- **HTTP**：`GET /health` 或 `GET /api/health`
- **响应示例**：
  ```json
  {
    "status": "ok",
    "timestamp": "2026-02-12T10:00:00.000Z",
    "uptime": 12345
  }
  ```

## 部署

### 构建生产版本

```bash
npm run build
```

### 启动生产服务器

```bash
npm run start:prod
```

## 开发规范

- 遵循 [CybitX 项目宪章](../.specify/memory/constitution.md)
- 所有 API 变更必须先更新契约文档（`docs/api/`）
- 提交前运行 `npm run lint` 和 `npm run test`
- 使用 `/speckit.specify`、`/speckit.plan`、`/speckit.tasks` 工具链进行功能开发

## 联系方式

如有问题，请联系后端团队或查阅项目文档。

