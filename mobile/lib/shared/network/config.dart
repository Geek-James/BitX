/// 网络配置
class NetworkConfig {
  /// WebSocket 地址配置
  /// 
  /// Android 模拟器访问本机:
  /// - 使用 10.0.2.2 代替 localhost
  /// 
  /// iOS 模拟器访问本机:
  /// - 使用 localhost 或 127.0.0.1
  /// 
  /// 真机访问:
  /// - 使用电脑的局域网 IP 地址
  static String get wsUrl {
    // 开发环境
    const isDevelopment = true;
    
    if (isDevelopment) {
      // Android 模拟器
      // return 'ws://10.0.2.2:3001';
      
      // iOS 模拟器使用:
      // return 'ws://localhost:3001';
      
      // 真机调试使用 (替换为你的电脑 IP):
      return 'ws://192.168.0.104:3001';
    }
    
    // 生产环境
    return 'wss://api.bitx.com/ws';
  }
  
  /// HTTP API 地址
  static String get apiUrl {
    const isDevelopment = true;
    
    if (isDevelopment) {
      return 'http://10.0.2.2:3000';
    }
    
    return 'https://api.bitx.com';
  }
}

