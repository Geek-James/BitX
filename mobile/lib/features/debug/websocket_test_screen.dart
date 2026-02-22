import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/network/config.dart';
import '../../shared/network/websocket_service.dart';

/// WebSocket 测试页面
class WebSocketTestScreen extends ConsumerStatefulWidget {
  const WebSocketTestScreen({super.key});

  @override
  ConsumerState<WebSocketTestScreen> createState() => _WebSocketTestScreenState();
}

class _WebSocketTestScreenState extends ConsumerState<WebSocketTestScreen> {
  final _service = WebSocketService();
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    // 监听连接状态
    _service.connectionStateStream.listen((state) {
      setState(() {
        _logs.add('📡 Connection: ${state.status}');
      });
    });

    // 监听数据
    _service.tickersStream.listen((tickers) {
      setState(() {
        _logs.add('📊 Received ${tickers.length} tickers');
      });
    });
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket 测试'),
      ),
      body: Column(
        children: [
          // 配置信息
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WebSocket URL: ${NetworkConfig.wsUrl}'),
                Text('API URL: ${NetworkConfig.apiUrl}'),
                const SizedBox(height: 8),
                Text('状态: ${_service.connectionState.status}'),
              ],
            ),
          ),

          // 操作按钮
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    _service.connect();
                    setState(() {
                      _logs.add('🔌 Connecting...');
                    });
                  },
                  child: const Text('连接'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _service.disconnect();
                    setState(() {
                      _logs.add('👋 Disconnected');
                    });
                  },
                  child: const Text('断开'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _logs.clear();
                    });
                  },
                  child: const Text('清空日志'),
                ),
              ],
            ),
          ),

          // 日志列表
          Expanded(
            child: ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  dense: true,
                  title: Text(
                    _logs[_logs.length - 1 - index],
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

