import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import { WebSocketServer } from 'ws';
import http from 'http';

// 加载环境变量
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;
const WS_PORT = process.env.WS_PORT || 3001;

// 中间件
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 健康检查接口
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

// API 路由（待实现）
app.get('/api', (req, res) => {
  res.json({
    message: 'CybitX Backend API',
    version: '0.1.0',
    documentation: '/api/docs',
  });
});

// 404 处理
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Cannot ${req.method} ${req.path}`,
  });
});

// 错误处理
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('Error:', err);
  res.status(err.status || 500).json({
    error: err.message || 'Internal Server Error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
});

// 启动 HTTP 服务器
app.listen(PORT, () => {
  console.log(`🚀 CybitX Backend Server is running on http://localhost:${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log(`📚 API docs: http://localhost:${PORT}/api/docs`);
  console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
});

// 创建 WebSocket 服务器
const server = http.createServer();
const wss = new WebSocketServer({ server });

// 生成1000+个模拟交易对 (永续合约) - 参考币安真实数据
function generateMockFuturesMarkets() {
  const markets = [];
  
  // 主流币种 (100个) - 永续合约，使用真实价格范围
  const mainCoins = [
    { symbol: 'BTC', basePrice: 45000, volatility: 200 },
    { symbol: 'ETH', basePrice: 2500, volatility: 50 },
    { symbol: 'BNB', basePrice: 350, volatility: 10 },
    { symbol: 'SOL', basePrice: 100, volatility: 5 },
    { symbol: 'ADA', basePrice: 0.5, volatility: 0.02 },
    { symbol: 'XRP', basePrice: 0.6, volatility: 0.03 },
    { symbol: 'DOGE', basePrice: 0.08, volatility: 0.005 },
    { symbol: 'DOT', basePrice: 7, volatility: 0.3 },
    { symbol: 'MATIC', basePrice: 0.9, volatility: 0.05 },
    { symbol: 'AVAX', basePrice: 35, volatility: 2 },
    { symbol: 'LINK', basePrice: 15, volatility: 0.8 },
    { symbol: 'UNI', basePrice: 8, volatility: 0.4 },
    { symbol: 'ATOM', basePrice: 10, volatility: 0.5 },
    { symbol: 'LTC', basePrice: 80, volatility: 4 },
    { symbol: 'ETC', basePrice: 25, volatility: 1.5 },
    { symbol: 'XLM', basePrice: 0.12, volatility: 0.008 },
    { symbol: 'ALGO', basePrice: 0.18, volatility: 0.01 },
    { symbol: 'VET', basePrice: 0.03, volatility: 0.002 },
    { symbol: 'ICP', basePrice: 12, volatility: 0.6 },
    { symbol: 'FIL', basePrice: 6, volatility: 0.3 },
    { symbol: 'TRX', basePrice: 0.1, volatility: 0.005 },
    { symbol: 'EOS', basePrice: 1.2, volatility: 0.06 },
    { symbol: 'AAVE', basePrice: 90, volatility: 5 },
    { symbol: 'GRT', basePrice: 0.15, volatility: 0.01 },
    { symbol: 'SAND', basePrice: 0.5, volatility: 0.03 },
    { symbol: 'MANA', basePrice: 0.6, volatility: 0.04 },
    { symbol: 'AXS', basePrice: 8, volatility: 0.5 },
    { symbol: 'THETA', basePrice: 1.5, volatility: 0.08 },
    { symbol: 'XTZ', basePrice: 1.1, volatility: 0.06 },
    { symbol: 'EGLD', basePrice: 45, volatility: 3 },
    { symbol: 'FTM', basePrice: 0.4, volatility: 0.02 },
    { symbol: 'HBAR', basePrice: 0.08, volatility: 0.005 },
    { symbol: 'NEAR', basePrice: 3, volatility: 0.2 },
    { symbol: 'FLOW', basePrice: 1.5, volatility: 0.08 },
    { symbol: 'APE', basePrice: 2, volatility: 0.1 },
    { symbol: 'CHZ', basePrice: 0.1, volatility: 0.008 },
    { symbol: 'MINA', basePrice: 0.8, volatility: 0.05 },
    { symbol: 'ROSE', basePrice: 0.08, volatility: 0.005 },
    { symbol: 'ONE', basePrice: 0.02, volatility: 0.001 },
    { symbol: 'ZIL', basePrice: 0.03, volatility: 0.002 },
  ];

  // 为每个币种生成 USDT 永续合约
  mainCoins.forEach(coin => {
    markets.push({
      symbol: `${coin.symbol}USDT`,
      basePrice: coin.basePrice,
      volatility: coin.volatility,
      type: 'futures'
    });
  });

  // 生成更多随机永续合约达到1000+
  const prefixes = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'];
  const suffixes = ['X', 'Y', 'Z', 'A', 'B', 'C', 'D', 'E', 'F', 'G'];
  
  for (let i = 0; i < 960; i++) {
    const prefix = prefixes[Math.floor(Math.random() * prefixes.length)];
    const suffix = suffixes[Math.floor(Math.random() * suffixes.length)];
    const num = Math.floor(Math.random() * 999) + 1;
    const symbol = `${prefix}${suffix}${num}USDT`;
    // 随机价格范围：0.001 到 100
    const basePrice = Math.random() < 0.3 ? Math.random() * 0.1 + 0.001 : Math.random() * 100 + 0.1;
    
    markets.push({
      symbol: symbol,
      basePrice: basePrice,
      volatility: basePrice * 0.02,
      type: 'futures'
    });
  }

  console.log(`📊 Generated ${markets.length} futures trading pairs`);
  return markets;
}

// 生成1000+个模拟交易对 (现货) - 参考币安真实数据
function generateMockSpotMarkets() {
  const markets = [];
  
  // 主流币种 (100个) - 现货，使用真实价格范围
  const mainCoins = [
    { symbol: 'BTC', basePrice: 45000, volatility: 200 },
    { symbol: 'ETH', basePrice: 2500, volatility: 50 },
    { symbol: 'BNB', basePrice: 350, volatility: 10 },
    { symbol: 'SOL', basePrice: 100, volatility: 5 },
    { symbol: 'ADA', basePrice: 0.5, volatility: 0.02 },
    { symbol: 'XRP', basePrice: 0.6, volatility: 0.03 },
    { symbol: 'DOGE', basePrice: 0.08, volatility: 0.005 },
    { symbol: 'DOT', basePrice: 7, volatility: 0.3 },
    { symbol: 'MATIC', basePrice: 0.9, volatility: 0.05 },
    { symbol: 'AVAX', basePrice: 35, volatility: 2 },
    { symbol: 'LINK', basePrice: 15, volatility: 0.8 },
    { symbol: 'UNI', basePrice: 8, volatility: 0.4 },
    { symbol: 'ATOM', basePrice: 10, volatility: 0.5 },
    { symbol: 'LTC', basePrice: 80, volatility: 4 },
    { symbol: 'ETC', basePrice: 25, volatility: 1.5 },
    { symbol: 'XLM', basePrice: 0.12, volatility: 0.008 },
    { symbol: 'ALGO', basePrice: 0.18, volatility: 0.01 },
    { symbol: 'VET', basePrice: 0.03, volatility: 0.002 },
    { symbol: 'ICP', basePrice: 12, volatility: 0.6 },
    { symbol: 'FIL', basePrice: 6, volatility: 0.3 },
    { symbol: 'TRX', basePrice: 0.1, volatility: 0.005 },
    { symbol: 'EOS', basePrice: 1.2, volatility: 0.06 },
    { symbol: 'AAVE', basePrice: 90, volatility: 5 },
    { symbol: 'GRT', basePrice: 0.15, volatility: 0.01 },
    { symbol: 'SAND', basePrice: 0.5, volatility: 0.03 },
    { symbol: 'MANA', basePrice: 0.6, volatility: 0.04 },
    { symbol: 'AXS', basePrice: 8, volatility: 0.5 },
    { symbol: 'THETA', basePrice: 1.5, volatility: 0.08 },
    { symbol: 'XTZ', basePrice: 1.1, volatility: 0.06 },
    { symbol: 'EGLD', basePrice: 45, volatility: 3 },
    { symbol: 'FTM', basePrice: 0.4, volatility: 0.02 },
    { symbol: 'HBAR', basePrice: 0.08, volatility: 0.005 },
    { symbol: 'NEAR', basePrice: 3, volatility: 0.2 },
    { symbol: 'FLOW', basePrice: 1.5, volatility: 0.08 },
    { symbol: 'APE', basePrice: 2, volatility: 0.1 },
    { symbol: 'CHZ', basePrice: 0.1, volatility: 0.008 },
    { symbol: 'MINA', basePrice: 0.8, volatility: 0.05 },
    { symbol: 'ROSE', basePrice: 0.08, volatility: 0.005 },
    { symbol: 'ONE', basePrice: 0.02, volatility: 0.001 },
    { symbol: 'ZIL', basePrice: 0.03, volatility: 0.002 },
  ];

  // 为每个币种生成 USDT 现货
  mainCoins.forEach(coin => {
    markets.push({
      symbol: `${coin.symbol}/USDT`,
      basePrice: coin.basePrice,
      volatility: coin.volatility,
      type: 'spot'
    });
  });

  // 生成更多随机现货达到1000+
  const prefixes = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'];
  const suffixes = ['X', 'Y', 'Z', 'A', 'B', 'C', 'D', 'E', 'F', 'G'];
  
  for (let i = 0; i < 960; i++) {
    const prefix = prefixes[Math.floor(Math.random() * prefixes.length)];
    const suffix = suffixes[Math.floor(Math.random() * suffixes.length)];
    const num = Math.floor(Math.random() * 999) + 1;
    const symbol = `${prefix}${suffix}${num}/USDT`;
    // 随机价格范围：0.001 到 100
    const basePrice = Math.random() < 0.3 ? Math.random() * 0.1 + 0.001 : Math.random() * 100 + 0.1;
    
    markets.push({
      symbol: symbol,
      basePrice: basePrice,
      volatility: basePrice * 0.02,
      type: 'spot'
    });
  }

  console.log(`📊 Generated ${markets.length} spot trading pairs`);
  return markets;
}

const mockFuturesMarkets = generateMockFuturesMarkets();
const mockSpotMarkets = generateMockSpotMarkets();
const allMarkets = [...mockFuturesMarkets, ...mockSpotMarkets];

console.log(`📊 Total trading pairs: ${allMarkets.length} (${mockFuturesMarkets.length} futures + ${mockSpotMarkets.length} spot)`);

// 生成随机行情数据
function generateMarketData() {
  return allMarkets.map(market => {
    const price = market.basePrice + (Math.random() - 0.5) * market.volatility * 2;
    const change24h = (Math.random() - 0.5) * 10;
    const volume24h = Math.random() * 1000000000;
    const high24h = price * (1 + Math.random() * 0.05);
    const low24h = price * (1 - Math.random() * 0.05);

    // 根据价格决定小数位数
    let decimals = 2;
    if (price < 0.01) decimals = 6;
    else if (price < 0.1) decimals = 5;
    else if (price < 1) decimals = 4;
    else if (price < 10) decimals = 3;

    return {
      symbol: market.symbol,
      price: price.toFixed(decimals),
      change24h: change24h.toFixed(2),
      volume24h: volume24h.toFixed(2),
      high24h: high24h.toFixed(decimals),
      low24h: low24h.toFixed(decimals),
      timestamp: Date.now(),
    };
  });
}

// WebSocket 连接处理
wss.on('connection', (ws) => {
  console.log('📱 New WebSocket client connected');
  
  let dataInterval: NodeJS.Timeout | null = null;
  let heartbeatInterval: NodeJS.Timeout | null = null;

  // 处理客户端消息
  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message.toString());
      console.log('📨 Received:', data);

      if (data.action === 'subscribe') {
        // 订阅行情数据
        if (data.channel === 'market.all') {
          // 立即发送一次数据
          const marketData = generateMarketData();
          ws.send(JSON.stringify({
            type: 'data',
            channel: 'market.all',
            data: marketData,
            timestamp: Date.now(),
          }));

          // 每2秒推送一次更新
          dataInterval = setInterval(() => {
            if (ws.readyState === ws.OPEN) {
              const marketData = generateMarketData();
              ws.send(JSON.stringify({
                type: 'data',
                channel: 'market.all',
                data: marketData,
                timestamp: Date.now(),
              }));
            }
          }, 2000);

          console.log('✅ Subscribed to market.all');
        }
      } else if (data.action === 'ping') {
        // 心跳响应
        ws.send(JSON.stringify({
          type: 'pong',
          timestamp: Date.now(),
        }));
      }
    } catch (error) {
      console.error('❌ Error parsing message:', error);
    }
  });

  // 连接关闭处理
  ws.on('close', () => {
    console.log('👋 Client disconnected');
    if (dataInterval) clearInterval(dataInterval);
    if (heartbeatInterval) clearInterval(heartbeatInterval);
  });

  // 错误处理
  ws.on('error', (error) => {
    console.error('❌ WebSocket error:', error);
  });
});

// 启动 WebSocket 服务器
server.listen(WS_PORT, () => {
  console.log(`🔌 WebSocket Server is running on ws://localhost:${WS_PORT}`);
  console.log(`📡 Clients can connect to: ws://localhost:${WS_PORT}`);
});

export default app;

