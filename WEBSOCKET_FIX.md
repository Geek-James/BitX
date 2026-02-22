# 手机端数据连接问题修复说明

## 问题诊断

手机端没有数据的原因:

1. **后端缺少 WebSocket 服务器** - 原来只有 HTTP 服务,没有 WebSocket 支持
2. **手机端连接地址错误** - 尝试连接到不存在的 `wss://api.cybitx.com/ws/markets`
3. **Android 网络权限缺失** - AndroidManifest.xml 没有声明网络权限
4. **没有模拟数据** - 即使连接成功也没有行情数据推送

## 已完成的修复

### 1. 后端修改 (backend/src/main.ts)

- ✅ 添加 WebSocket 服务器 (端口 3001)
- ✅ 实现行情数据订阅协议
- ✅ 添加 10 个模拟币种的实时行情数据
- ✅ 每 2 秒自动推送更新的行情数据
- ✅ 实现心跳机制 (ping/pong)

**模拟币种:**
- BTCUSDT, ETHUSDT, BNBUSDT, SOLUSDT, ADAUSDT
- XRPUSDT, DOGEUSDT, DOTUSDT, MATICUSDT, AVAXUSDT

### 2. 手机端修改

#### 网络配置 (mobile/lib/shared/network/config.dart)
- ✅ 创建统一的网络配置文件
- ✅ 支持开发/生产环境切换
- ✅ Android 模拟器使用 `10.0.2.2` 访问本机
- ✅ 提供 iOS 和真机调试的配置说明

#### WebSocket 服务 (mobile/lib/shared/network/websocket_service.dart)
- ✅ 更新连接地址为本地后端
- ✅ 添加详细的调试日志
- ✅ 使用配置文件管理 URL

#### Android 权限 (mobile/android/app/src/main/AndroidManifest.xml)
- ✅ 添加 INTERNET 权限
- ✅ 添加 ACCESS_NETWORK_STATE 权限

#### 调试工具 (mobile/lib/features/debug/websocket_test_screen.dart)
- ✅ 创建 WebSocket 测试页面
- ✅ 实时显示连接状态和日志
- ✅ 提供手动连接/断开功能

## 如何测试

### 方法 1: 使用行情页面

1. 确保后端服务正在运行 (应该看到 WebSocket 服务器启动日志)
2. 在手机端点击底部导航栏的"行情"标签
3. 应该能看到 10 个币种的实时行情数据
4. 数据每 2 秒自动更新

### 方法 2: 使用调试页面

1. 在手机端主页点击"WebSocket 测试"按钮
2. 查看显示的 WebSocket URL (应该是 `ws://10.0.2.2:3001`)
3. 点击"连接"按钮
4. 观察日志输出,应该看到:
   - 🔌 Connecting...
   - 📡 Connection: connected
   - 📊 Received 10 tickers

## 网络地址说明

### Android 模拟器
- 使用 `10.0.2.2` 代替 `localhost` 访问开发机器
- WebSocket: `ws://10.0.2.2:3001`
- HTTP API: `http://10.0.2.2:3000`

### iOS 模拟器
- 可以直接使用 `localhost`
- WebSocket: `ws://localhost:3001`
- HTTP API: `http://localhost:3000`

### 真机调试
- 需要使用开发机器的局域网 IP
- 例如: `ws://192.168.1.100:3001`
- 确保手机和电脑在同一局域网

## 后端 WebSocket 协议

### 订阅行情数据

**客户端发送:**
```json
{
  "action": "subscribe",
  "channel": "market.all"
}
```

**服务器响应:**
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
  ],
  "timestamp": 1234567890
}
```

### 心跳

**客户端发送:**
```json
{
  "action": "ping"
}
```

**服务器响应:**
```json
{
  "type": "pong",
  "timestamp": 1234567890
}
```

## 常见问题

### Q: 手机端显示"网络错误"
A: 检查:
1. 后端 WebSocket 服务器是否启动 (查看终端日志)
2. 手机是否使用正确的地址 (Android 模拟器用 10.0.2.2)
3. 防火墙是否阻止了 3001 端口

### Q: 连接成功但没有数据
A: 检查:
1. 后端日志是否显示"📱 New WebSocket client connected"
2. 后端日志是否显示"📨 Received: {action: subscribe...}"
3. 手机端日志是否显示"📥 Received message"

### Q: 真机无法连接
A: 
1. 修改 `mobile/lib/shared/network/config.dart`
2. 将 `return 'ws://10.0.2.2:3001'` 改为你的电脑 IP
3. 例如: `return 'ws://192.168.1.100:3001'`
4. 确保手机和电脑在同一网络

## 下一步

- [ ] 添加更多币种
- [ ] 实现单个币种订阅
- [ ] 添加 K 线数据
- [ ] 实现深度数据
- [ ] 添加用户认证
- [ ] 连接真实交易所 API

## 文件清单

### 新增文件
- `mobile/lib/shared/network/config.dart` - 网络配置
- `mobile/lib/features/debug/websocket_test_screen.dart` - 调试页面

### 修改文件
- `backend/src/main.ts` - 添加 WebSocket 服务器
- `mobile/lib/shared/network/websocket_service.dart` - 更新连接地址和日志
- `mobile/lib/main.dart` - 添加调试入口
- `mobile/android/app/src/main/AndroidManifest.xml` - 添加网络权限

