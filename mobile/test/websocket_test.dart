import 'package:flutter_test/flutter_test.dart';
import 'package:bitx_mobile/shared/network/websocket_service.dart';

void main() {
  test('WebSocket mock data generation test', () async {
    final wsService = WebSocketService();
    
    // 订阅订单薄数据
    final orderBookData = <Map<String, dynamic>>[];
    wsService.orderBookStream.listen((data) {
      // print('📊 Received order book: ${data['channel']}');
      orderBookData.add(data);
    });
    
    // 订阅交易数据
    final tradesData = <Map<String, dynamic>>[];
    wsService.tradesStream.listen((data) {
      // print('💰 Received trade: ${data['channel']}');
      tradesData.add(data);
    });
    
    // 连接并订阅
    await wsService.connect();
    wsService.subscribeOrderBook('BTCUSDT');
    wsService.subscribeTrades('BTCUSDT');
    
    // 等待5秒接收数据
    await Future.delayed(const Duration(seconds: 5));
    
    // print('📈 Total order book updates: ${orderBookData.length}');
    // print('📈 Total trades: ${tradesData.length}');
    
    // 验证数据
    expect(orderBookData.length, greaterThan(0), reason: 'Should receive order book data');
    expect(tradesData.length, greaterThan(0), reason: 'Should receive trade data');
    
    wsService.dispose();
  });
}

