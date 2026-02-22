/// WebSocket 连接状态枚举
enum ConnectionStatus {
  connecting,
  connected,
  disconnected,
  error,
}

/// WebSocket 连接状态模型
class WebSocketConnectionState {
  final ConnectionStatus status;
  final int retryCount;
  final String? lastError;
  final DateTime? connectedAt;

  WebSocketConnectionState({
    required this.status,
    this.retryCount = 0,
    this.lastError,
    this.connectedAt,
  });

  /// 复制并修改部分字段
  WebSocketConnectionState copyWith({
    ConnectionStatus? status,
    int? retryCount,
    String? lastError,
    DateTime? connectedAt,
  }) {
    return WebSocketConnectionState(
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      connectedAt: connectedAt ?? this.connectedAt,
    );
  }

  /// 判断是否已连接
  bool get isConnected => status == ConnectionStatus.connected;

  /// 判断是否可以重连
  bool get canRetry => retryCount < 10;

  /// 获取重连延迟（指数退避）
  Duration getRetryDelay() {
    final seconds = (1 << retryCount).clamp(1, 8);
    return Duration(seconds: seconds);
  }
}

