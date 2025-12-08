import 'dart:async';
import 'dart:convert';
import 'package:mqtt5_client/mqtt5_client.dart';
import 'package:mqtt5_client/mqtt5_server_client.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as notifications;
import '../models/task.dart';
import 'task_service.dart';
import 'log_service.dart';

/// MQTT服务连接状态枚举
enum MqttServiceState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

/// MQTT服务类 - 负责待办事项的MQTT同步（使用MQTT 5.0）
class MqttService {
  static MqttService? _instance;
  MqttServerClient? _client;
  final TaskService _taskService = TaskService.instance;
  final notifications.FlutterLocalNotificationsPlugin _notificationsPlugin =
      notifications.FlutterLocalNotificationsPlugin();

  /// 当前工号
  String? _empNo;

  /// 连接配置（用于重连）
  String? _broker;
  int? _port;
  String? _username;
  String? _password;

  /// 消息监听订阅
  StreamSubscription<List<MqttReceivedMessage>>? _messageSubscription;

  /// 任务变更通知流（用于通知UI刷新）
  final _taskChangeController = StreamController<void>.broadcast();
  Stream<void> get taskChangeStream => _taskChangeController.stream;

  /// 连接状态流
  final _connectionStateController =
      StreamController<MqttServiceState>.broadcast();
  Stream<MqttServiceState> get connectionStateStream =>
      _connectionStateController.stream;

  /// 当前连接状态
  MqttServiceState _connectionState = MqttServiceState.disconnected;
  MqttServiceState get connectionState => _connectionState;

  /// 是否正在重连
  bool _isReconnecting = false;

  /// 重连定时器
  Timer? _reconnectTimer;

  /// 通知是否已初始化
  bool _notificationsInitialized = false;

  MqttService._();

  static MqttService get instance {
    _instance ??= MqttService._();
    return _instance!;
  }

  /// 初始化通知
  Future<void> _initNotifications() async {
    if (_notificationsInitialized) {
      print('ℹ️ [MQTT] 通知已初始化，跳过');
      return;
    }

    const androidSettings = notifications.AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = notifications.DarwinInitializationSettings();
    const linuxSettings = notifications.LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );
    const initSettings = notifications.InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
    _notificationsInitialized = true;
    print('✓ [MQTT] 通知初始化成功');
  }

  /// 显示通知
  Future<void> _showNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = notifications.AndroidNotificationDetails(
      'mqtt_tasks_channel',
      'MQTT待办通知',
      channelDescription: '接收MQTT推送的待办事项通知',
      importance: notifications.Importance.high,
      priority: notifications.Priority.high,
    );

    const darwinDetails = notifications.DarwinNotificationDetails();

    const linuxDetails = notifications.LinuxNotificationDetails();

    const notificationDetails = notifications.NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
      linux: linuxDetails,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      notificationDetails,
    );
  }

  /// 更新连接状态
  void _updateConnectionState(MqttServiceState state) {
    _connectionState = state;
    _connectionStateController.add(state);
    print('📡 [MQTT] 连接状态变更: $state');
    LogService.instance.info('MQTT连接状态变更: $state', tag: 'MQTT');
  }

  /// 连接到MQTT Broker
  Future<bool> connect({
    required String broker,
    int port = 1883,
    required String empNo,
    String? username,
    String? password,
  }) async {
    if (_connectionState == MqttServiceState.connected && _client != null) {
      print('⚠️ [MQTT] 已经连接，无需重复连接');
      return true;
    }

    try {
      _empNo = empNo;
      // 保存连接配置（用于重连）
      _broker = broker;
      _port = port;
      _username = username;
      _password = password;

      _updateConnectionState(MqttServiceState.connecting);

      // 初始化通知（只初始化一次）
      await _initNotifications();

      // 判断是首次连接还是重连
      final bool isFirstConnection = _client == null;

      // ⚠️ 关键：每次连接都创建新的客户端实例，避免sessionTakenOver问题
      if (_client != null) {
        print('🧹 [MQTT] 清理旧客户端实例以避免sessionTakenOver...');
        // 取消旧的消息订阅
        await _messageSubscription?.cancel();
        _messageSubscription = null;
        _client = null;
      }

      print('🆕 [MQTT] 创建新的MQTT 5.0客户端实例...');

      // ⚠️ 关键：使用时间戳确保Client ID唯一，避免sessionTakenOver
      final String clientId = 'chat_desktop_${empNo}_${DateTime.now().millisecondsSinceEpoch}';

      // 创建MQTT 5.0客户端
      _client = MqttServerClient(broker, clientId);
      _client!.port = port;
      _client!.logging(on: false); // 关闭详细日志
      _client!.keepAlivePeriod = 60;
      _client!.autoReconnect = false; // 我们自己处理重连

      print('🔧 [MQTT] 使用协议: MQTT 5.0');
      print('🔧 [MQTT] Client ID: $clientId');
      print('🔧 [MQTT] 客户端配置: keepAlive=${_client!.keepAlivePeriod}s');

      // 设置回调
      _client!.onConnected = _onConnected;
      _client!.onDisconnected = _onDisconnected;
      _client!.onSubscribed = _onSubscribed;

      // 设置连接消息
      final connectionMessage = MqttConnectMessage()
          .withClientIdentifier(clientId) // 使用与client相同的ID
          .startClean() // ⚠️ 始终Clean Start=true，匹配MQTTX行为
          .keepAliveFor(60);

      print('🔧 [MQTT] Clean Start = true');

      // 认证
      if (username != null && username.isNotEmpty) {
        connectionMessage.authenticateAs(username, password ?? '');
      } else {
        connectionMessage.authenticateAs(empNo, '');
      }

      _client!.connectionMessage = connectionMessage;

      // 连接
      print('📡 [MQTT] 正在连接到 $broker:$port...');
      await LogService.instance.info('正在连接到MQTT Broker: $broker:$port', tag: 'MQTT');
      await _client!.connect();

      if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
        print('✓ [MQTT] 连接成功');
        await LogService.instance.info('MQTT连接成功', tag: 'MQTT');
        _updateConnectionState(MqttServiceState.connected);

        // ⚠️ 关键：每次连接成功后都需要订阅消息流（因为每次都是新client）
        if (_client!.updates != null) {
          print('📡 [MQTT] 设置消息监听...');
          _messageSubscription = _client!.updates!.listen(
            _onMessage,
            onDone: () {
              print('⚠️ [MQTT] 消息流结束 (onDone)');
            },
            onError: (error) {
              print('❌ [MQTT] 消息流错误: $error');
            },
            cancelOnError: false,
          );
          print('✓ [MQTT] 消息监听已设置');
        }

        // 订阅Topic
        _subscribeToTopics(empNo);

        return true;
      } else {
        print('✗ [MQTT] 连接失败: ${_client!.connectionStatus}');
        await LogService.instance.error('MQTT连接失败: ${_client!.connectionStatus}', tag: 'MQTT');
        _updateConnectionState(MqttServiceState.error);
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ [MQTT] 连接异常: $e');
      print('Stack trace: $stackTrace');
      await LogService.instance.error('MQTT连接异常: $e', tag: 'MQTT');
      _updateConnectionState(MqttServiceState.error);
      _scheduleReconnect();
      return false;
    }
  }

  /// 订阅Topic
  void _subscribeToTopics(String empNo) {
    // 订阅个人所有待办相关消息 (使用通配符)
    final personalTopic = 'mqtt_app/tasks/$empNo/#';
    _client!.subscribe(personalTopic, MqttQos.atLeastOnce);
    print('📬 [MQTT] 已订阅: $personalTopic');
  }

  /// 连接成功回调
  void _onConnected() {
    print('✓ [MQTT] onConnected 回调触发');
    _updateConnectionState(MqttServiceState.connected);
    _isReconnecting = false;
    _reconnectTimer?.cancel();
  }

  /// 断开连接回调
  void _onDisconnected() {
    print('⚠️ [MQTT] onDisconnected 回调触发');
    LogService.instance.warning('MQTT连接已断开', tag: 'MQTT');
    _updateConnectionState(MqttServiceState.disconnected);

    // 尝试重连（复用现有client实例）
    if (!_isReconnecting) {
      _scheduleReconnect();
    }
  }

  /// 订阅成功回调
  void _onSubscribed(MqttSubscription subscription) {
    print('✓ [MQTT] 订阅成功: ${subscription.topic}');
  }

  /// 计划重连
  void _scheduleReconnect() {
    if (_isReconnecting) return;

    _isReconnecting = true;
    print('🔄 [MQTT] 将在5秒后尝试重连...');

    _reconnectTimer = Timer(const Duration(seconds: 5), () async {
      if (_empNo != null && _broker != null && _port != null) {
        print('🔄 [MQTT] 正在重连...');
        final success = await connect(
          broker: _broker!,
          port: _port!,
          empNo: _empNo!,
          username: _username,
          password: _password,
        );

        if (!success) {
          _isReconnecting = false;
          _scheduleReconnect(); // 继续尝试
        }
      }
    });
  }

  /// 处理接收到的消息
  void _onMessage(List<MqttReceivedMessage> messages) {
    for (final message in messages) {
      final topic = message.topic ?? '';
      final payload = message.payload as MqttPublishMessage;
      // ⚠️ 使用utf8.decode正确解码中文字符，而不是String.fromCharCodes
      final messageStr = utf8.decode(payload.payload.message!);

      print('📨 [MQTT] 收到消息');
      print('   Topic: $topic');
      print('   Payload: $messageStr');

      LogService.instance.info('收到MQTT消息 - Topic: $topic', tag: 'MQTT');

      try {
        final json = jsonDecode(messageStr) as Map<String, dynamic>;
        _handleMessage(topic, json);
      } catch (e) {
        print('❌ [MQTT] 消息解析失败: $e');
        LogService.instance.error('MQTT消息解析失败: $e', tag: 'MQTT');
      }
    }
  }

  /// 处理消息内容
  Future<void> _handleMessage(String topic, Map<String, dynamic> json) async {
    final action = json['action'] as String?;

    if (action == null) {
      print('⚠️ [MQTT] 消息缺少action字段');
      return;
    }

    print('🔧 [MQTT] 处理操作: $action');

    switch (action) {
      case 'create':
        await _handleCreateTask(json);
        break;
      case 'update':
        await _handleUpdateTask(json);
        break;
      case 'delete':
        await _handleDeleteTask(json);
        break;
      case 'complete':
        await _handleCompleteTask(json);
        break;
      default:
        print('⚠️ [MQTT] 未知操作: $action');
    }
  }

  /// 处理创建待办
  Future<void> _handleCreateTask(Map<String, dynamic> json) async {
    try {
      final taskData = json['task'] as Map<String, dynamic>;
      final task = Task.fromJson(taskData);

      // UUID去重
      final existingTasks = await _taskService.getAllTasks();
      final isDuplicate = existingTasks.any((t) => t.uuid == task.uuid);

      if (isDuplicate) {
        print('⚠️ [MQTT] 任务已存在，跳过创建 (UUID: ${task.uuid})');
        return;
      }

      await _taskService.createTaskDirect(task);
      print('✓ [MQTT] 待办已创建: ${task.title} (UUID: ${task.uuid})');
      await LogService.instance.info('MQTT创建待办: ${task.title}', tag: 'MQTT');

      _taskChangeController.add(null);

      await _showNotification(
        title: '新待办事项',
        body: task.title,
      );
    } catch (e) {
      print('❌ [MQTT] 创建待办失败: $e');
    }
  }

  /// 处理更新待办
  Future<void> _handleUpdateTask(Map<String, dynamic> json) async {
    try {
      final taskId = json['taskId'] as int?;
      final uuid = json['uuid'] as String?;
      final changes = json['changes'] as Map<String, dynamic>?;

      if (changes == null) {
        print('⚠️ [MQTT] 更新消息缺少changes字段');
        return;
      }

      Task? task;
      if (uuid != null) {
        final tasks = await _taskService.getAllTasks();
        task = tasks.firstWhere(
          (t) => t.uuid == uuid,
          orElse: () => throw Exception('未找到UUID对应的任务'),
        );
      } else if (taskId != null) {
        task = await _taskService.getTaskById(taskId);
      }

      if (task == null) {
        print('⚠️ [MQTT] 任务不存在');
        return;
      }

      final updatedTask = task.copyWith(
        title: changes['title'] as String? ?? task.title,
        description: changes['description'] as String?,
        priority: changes['priority'] != null
            ? Priority.values[changes['priority'] as int]
            : task.priority,
        dueDate: changes['dueDate'] != null
            ? DateTime.parse(changes['dueDate'] as String)
            : task.dueDate,
        tags: changes['tags'] as String?,
      );

      await _taskService.updateTask(updatedTask);
      print('✓ [MQTT] 待办已更新: ${updatedTask.title}');
      await LogService.instance.info('MQTT更新待办: ${updatedTask.title}', tag: 'MQTT');

      _taskChangeController.add(null);

      await _showNotification(
        title: '待办已更新',
        body: updatedTask.title,
      );
    } catch (e) {
      print('❌ [MQTT] 更新待办失败: $e');
    }
  }

  /// 处理删除待办
  Future<void> _handleDeleteTask(Map<String, dynamic> json) async {
    try {
      final taskId = json['taskId'] as int?;
      final uuid = json['uuid'] as String?;

      Task? task;
      if (uuid != null) {
        final tasks = await _taskService.getAllTasks();
        task = tasks.firstWhere(
          (t) => t.uuid == uuid,
          orElse: () => throw Exception('未找到UUID对应的任务'),
        );
      } else if (taskId != null) {
        task = await _taskService.getTaskById(taskId);
      }

      if (task == null) {
        print('⚠️ [MQTT] 任务不存在');
        return;
      }

      await _taskService.deleteTask(task.id);
      print('✓ [MQTT] 待办已删除');

      _taskChangeController.add(null);

      await _showNotification(
        title: '待办已删除',
        body: task.title,
      );
    } catch (e) {
      print('❌ [MQTT] 删除待办失败: $e');
    }
  }

  /// 处理完成待办
  Future<void> _handleCompleteTask(Map<String, dynamic> json) async {
    try {
      final taskId = json['taskId'] as int?;
      final uuid = json['uuid'] as String?;
      final isCompleted = json['isCompleted'] as bool? ?? true;

      Task? task;
      if (uuid != null) {
        final tasks = await _taskService.getAllTasks();
        task = tasks.firstWhere(
          (t) => t.uuid == uuid,
          orElse: () => throw Exception('未找到UUID对应的任务'),
        );
      } else if (taskId != null) {
        task = await _taskService.getTaskById(taskId);
      }

      if (task == null) {
        print('⚠️ [MQTT] 任务不存在');
        return;
      }

      if (isCompleted) {
        await _taskService.markTaskAsCompleted(task.id);
        print('✓ [MQTT] 待办已完成: ${task.title}');

        _taskChangeController.add(null);

        await _showNotification(
          title: '待办已完成',
          body: task.title,
        );
      } else {
        await _taskService.markTaskAsIncomplete(task.id);
        print('✓ [MQTT] 待办标记为未完成: ${task.title}');

        _taskChangeController.add(null);
      }
    } catch (e) {
      print('❌ [MQTT] 完成待办失败: $e');
    }
  }

  /// 发布待办给其他用户
  Future<bool> publishTask({
    required String targetEmpNo,
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    if (_client == null ||
        _client!.connectionStatus!.state != MqttConnectionState.connected) {
      print('❌ [MQTT] 未连接到Broker，无法发布消息');
      return false;
    }

    try {
      final topic = 'mqtt_app/tasks/$targetEmpNo/$action';
      final message = jsonEncode(payload);

      final builder = MqttPayloadBuilder();
      builder.addString(message);

      _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);

      print('📤 [MQTT] 消息已发布');
      print('   Topic: $topic');
      print('   Payload: $message');

      return true;
    } catch (e) {
      print('❌ [MQTT] 发布消息失败: $e');
      return false;
    }
  }

  /// 发布创建待办消息
  Future<bool> publishCreateTask({
    required String targetEmpNo,
    required Task task,
  }) async {
    return await publishTask(
      targetEmpNo: targetEmpNo,
      action: 'create',
      payload: {
        'action': 'create',
        'timestamp': DateTime.now().toString(),
        'task': task.toJson(),
        'metadata': {
          'sender': _empNo,
        },
      },
    );
  }

  /// 发布更新待办消息
  Future<bool> publishUpdateTask({
    required String targetEmpNo,
    required String uuid,
    required Map<String, dynamic> changes,
  }) async {
    return await publishTask(
      targetEmpNo: targetEmpNo,
      action: 'update',
      payload: {
        'action': 'update',
        'timestamp': DateTime.now().toString(),
        'uuid': uuid,
        'changes': changes,
        'metadata': {
          'sender': _empNo,
        },
      },
    );
  }

  /// 发布删除待办消息
  Future<bool> publishDeleteTask({
    required String targetEmpNo,
    required String uuid,
  }) async {
    return await publishTask(
      targetEmpNo: targetEmpNo,
      action: 'delete',
      payload: {
        'action': 'delete',
        'timestamp': DateTime.now().toString(),
        'uuid': uuid,
        'metadata': {
          'sender': _empNo,
        },
      },
    );
  }

  /// 发布完成待办消息
  Future<bool> publishCompleteTask({
    required String targetEmpNo,
    required String uuid,
    bool isCompleted = true,
  }) async {
    return await publishTask(
      targetEmpNo: targetEmpNo,
      action: 'complete',
      payload: {
        'action': 'complete',
        'timestamp': DateTime.now().toString(),
        'uuid': uuid,
        'isCompleted': isCompleted,
        'metadata': {
          'sender': _empNo,
        },
      },
    );
  }

  /// 断开连接
  Future<void> disconnect({bool destroyClient = false}) async {
    _reconnectTimer?.cancel();
    _isReconnecting = false;

    // 取消消息订阅
    if (destroyClient) {
      await _messageSubscription?.cancel();
      _messageSubscription = null;
    }

    if (_client != null) {
      _updateConnectionState(MqttServiceState.disconnecting);
      _client!.disconnect();
      print('✓ [MQTT] 已断开连接');

      // 如果需要销毁client（比如修改工号时）
      if (destroyClient) {
        _client = null;
        print('🗑️  [MQTT] 已销毁客户端实例');
      }
    }
  }

  /// 释放资源
  void dispose() {
    disconnect();
    _messageSubscription?.cancel();
    _connectionStateController.close();
    _taskChangeController.close();
  }
}
