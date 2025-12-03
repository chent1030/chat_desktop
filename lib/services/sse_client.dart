import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// SSE事件类型
enum SSEEventType {
  open,
  message,
  error,
  done,
}

/// SSE事件数据
class SSEEvent {
  final SSEEventType type;
  final String? event;
  final String? data;
  final String? id;
  final dynamic error;

  SSEEvent({
    required this.type,
    this.event,
    this.data,
    this.id,
    this.error,
  });

  @override
  String toString() {
    return 'SSEEvent(type: $type, event: $event, data: $data, id: $id)';
  }
}

/// SSE客户端工具类
/// 用于处理Server-Sent Events连接
class SSEClient {
  final String url;
  final Map<String, String>? headers;
  final Duration? timeout;
  final bool autoReconnect;
  final Duration reconnectDelay;
  final int maxReconnectAttempts;

  StreamController<SSEEvent>? _controller;
  CancelToken? _cancelToken;
  int _reconnectCount = 0;
  bool _isConnected = false;
  bool _isClosed = false;
  String? _lastEventId;

  SSEClient({
    required this.url,
    this.headers,
    this.timeout,
    this.autoReconnect = true,
    this.reconnectDelay = const Duration(seconds: 3),
    this.maxReconnectAttempts = 5,
  });

  /// 获取事件流
  Stream<SSEEvent> get stream {
    if (_controller == null || _controller!.isClosed) {
      _controller = StreamController<SSEEvent>.broadcast(
        onListen: _connect,
        onCancel: () {
          if (!autoReconnect) {
            close();
          }
        },
      );
    }
    return _controller!.stream;
  }

  /// 是否已连接
  bool get isConnected => _isConnected;

  /// 是否已关闭
  bool get isClosed => _isClosed;

  /// 连接SSE
  void _connect() async {
    if (_isClosed) {
      print('⚠️ SSE客户端已关闭，无法重新连接');
      return;
    }

    if (_isConnected) {
      print('⚠️ SSE客户端已连接');
      return;
    }

    try {
      print('🔌 [SSE] 正在连接: $url');

      _cancelToken = CancelToken();

      // 准备headers
      final requestHeaders = <String, String>{
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
        ...?headers,
      };

      // 添加Last-Event-ID用于断点续传
      if (_lastEventId != null) {
        requestHeaders['Last-Event-ID'] = _lastEventId!;
      }

      // 添加认证token（如果需要）
      final token = dotenv.env['API_TOKEN'];
      if (token != null && token.isNotEmpty) {
        requestHeaders['Authorization'] = 'Bearer $token';
      }

      final dio = Dio();
      final response = await dio.get<ResponseBody>(
        url,
        options: Options(
          headers: requestHeaders,
          responseType: ResponseType.stream,
          receiveTimeout: timeout,
        ),
        cancelToken: _cancelToken,
      );

      if (response.statusCode == 200) {
        _isConnected = true;
        _reconnectCount = 0;

        _controller?.add(SSEEvent(type: SSEEventType.open));
        print('✅ [SSE] 连接成功: $url');

        // 处理流数据
        await _handleStream(response.data!.stream);
      } else {
        throw SSEException(
          message: 'SSE连接失败: HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      _isConnected = false;

      print('❌ [SSE] 连接失败: $e');
      _controller?.add(SSEEvent(type: SSEEventType.error, error: e));

      // 自动重连
      if (autoReconnect &&
          !_isClosed &&
          _reconnectCount < maxReconnectAttempts) {
        _reconnectCount++;
        print('🔄 [SSE] 将在 ${reconnectDelay.inSeconds} 秒后重连 (第 $_reconnectCount 次)');
        await Future.delayed(reconnectDelay);
        _connect();
      } else if (_reconnectCount >= maxReconnectAttempts) {
        print('❌ [SSE] 已达到最大重连次数 ($maxReconnectAttempts)');
        _controller?.addError(SSEException(
          message: '已达到最大重连次数',
          statusCode: 0,
        ));
      }
    }
  }

  /// 处理SSE流数据
  Future<void> _handleStream(Stream<List<int>> stream) async {
    final buffer = StringBuffer();

    try {
      await for (final chunk in stream) {
        if (_isClosed) break;

        final text = utf8.decode(chunk);
        buffer.write(text);

        // 处理完整的事件（以双换行符分隔）
        final lines = buffer.toString().split('\n');
        buffer.clear();

        String? eventType;
        String? eventData;
        String? eventId;

        for (var i = 0; i < lines.length; i++) {
          final line = lines[i].trim();

          // 保留未完成的行
          if (i == lines.length - 1 && !line.isEmpty) {
            buffer.write(line);
            continue;
          }

          // 空行表示事件结束
          if (line.isEmpty) {
            if (eventData != null) {
              // 发送事件
              _controller?.add(SSEEvent(
                type: SSEEventType.message,
                event: eventType,
                data: eventData,
                id: eventId,
              ));

              // 保存eventId用于断点续传
              if (eventId != null) {
                _lastEventId = eventId;
              }
            }

            // 重置事件数据
            eventType = null;
            eventData = null;
            eventId = null;
            continue;
          }

          // 注释行（以冒号开头）
          if (line.startsWith(':')) {
            continue;
          }

          // 解析字段
          final colonIndex = line.indexOf(':');
          if (colonIndex == -1) continue;

          final field = line.substring(0, colonIndex);
          var value = line.substring(colonIndex + 1);

          // 去除值开头的空格
          if (value.startsWith(' ')) {
            value = value.substring(1);
          }

          switch (field) {
            case 'event':
              eventType = value;
              break;
            case 'data':
              if (eventData == null) {
                eventData = value;
              } else {
                eventData += '\n$value';
              }
              break;
            case 'id':
              eventId = value;
              break;
            case 'retry':
              // 可以设置重连延迟
              final retryMs = int.tryParse(value);
              if (retryMs != null) {
                // 可选：动态调整重连延迟
              }
              break;
          }
        }
      }

      // 流结束
      _isConnected = false;
      _controller?.add(SSEEvent(type: SSEEventType.done));
      print('✓ [SSE] 连接正常关闭');
    } catch (e) {
      _isConnected = false;
      print('❌ [SSE] 流处理错误: $e');
      _controller?.add(SSEEvent(type: SSEEventType.error, error: e));

      // 自动重连
      if (autoReconnect && !_isClosed) {
        await Future.delayed(reconnectDelay);
        _connect();
      }
    }
  }

  /// 关闭连接
  void close() {
    if (_isClosed) return;

    print('🔌 [SSE] 关闭连接: $url');
    _isClosed = true;
    _isConnected = false;
    _cancelToken?.cancel('SSE连接已关闭');
    _controller?.close();
  }

  /// 重置并重新连接
  void reconnect() {
    if (_isClosed) {
      print('⚠️ SSE客户端已关闭，无法重连');
      return;
    }

    print('🔄 [SSE] 手动重连: $url');
    _isConnected = false;
    _reconnectCount = 0;
    _cancelToken?.cancel('手动重连');
    _connect();
  }
}

/// SSE异常类
class SSEException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic error;

  SSEException({
    required this.message,
    this.statusCode,
    this.error,
  });

  @override
  String toString() {
    return 'SSEException(message: $message, statusCode: $statusCode)';
  }
}

/// SSE客户端管理器
/// 用于管理多个SSE连接
class SSEManager {
  static SSEManager? _instance;
  final Map<String, SSEClient> _clients = {};

  SSEManager._();

  static SSEManager get instance {
    _instance ??= SSEManager._();
    return _instance!;
  }

  /// 创建或获取SSE客户端
  SSEClient getClient(
    String key,
    String url, {
    Map<String, String>? headers,
    Duration? timeout,
    bool autoReconnect = true,
    Duration reconnectDelay = const Duration(seconds: 3),
    int maxReconnectAttempts = 5,
  }) {
    if (_clients.containsKey(key)) {
      return _clients[key]!;
    }

    final client = SSEClient(
      url: url,
      headers: headers,
      timeout: timeout,
      autoReconnect: autoReconnect,
      reconnectDelay: reconnectDelay,
      maxReconnectAttempts: maxReconnectAttempts,
    );

    _clients[key] = client;
    return client;
  }

  /// 关闭指定的SSE客户端
  void closeClient(String key) {
    final client = _clients[key];
    if (client != null) {
      client.close();
      _clients.remove(key);
      print('✓ 已关闭SSE客户端: $key');
    }
  }

  /// 关闭所有SSE客户端
  void closeAll() {
    for (final client in _clients.values) {
      client.close();
    }
    _clients.clear();
    print('✓ 已关闭所有SSE客户端');
  }

  /// 重连指定的SSE客户端
  void reconnectClient(String key) {
    final client = _clients[key];
    if (client != null) {
      client.reconnect();
    }
  }

  /// 获取所有客户端的连接状态
  Map<String, bool> getConnectionStatus() {
    return _clients.map((key, client) => MapEntry(key, client.isConnected));
  }
}
