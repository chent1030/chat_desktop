import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as notifications;
import '../models/task.dart';
import 'task_service.dart';

/// MQTT服务连接状态枚举
enum MqttServiceState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

/// MQTT服务类 - 负责待办事项的MQTT同步
class MqttService {
  static MqttService? _instance;
  MqttServerClient? _client;
  final TaskService _taskService = TaskService.instance;
  final notifications.FlutterLocalNotificationsPlugin _notificationsPlugin =
      notifications.FlutterLocalNotificationsPlugin();

  /// 当前工号
  String? _empNo;

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

  MqttService._();

  static MqttService get instance {
    _instance ??= MqttService._();
    return _instance!;
  }

  /// 初始化通知
  Future<void> _initNotifications() async {
    const androidSettings = notifications.AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = notifications.DarwinInitializationSettings();
    const initSettings = notifications.InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(initSettings);
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

    const notificationDetails = notifications.NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
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
  }

  /// 连接到MQTT Broker
  Future<bool> connect({
    required String broker,
    int port = 1883,
    required String empNo,
    String? username,
    String? password,
  }) async {
    if (_connectionState == MqttServiceState.connected) {
      print('⚠️ [MQTT] 已经连接，无需重复连接');
      return true;
    }

    try {
      _empNo = empNo;
      _updateConnectionState(MqttServiceState.connecting);

      // 初始化通知
      await _initNotifications();

      // 创建客户端 (clientId使用工号)
      _client = MqttServerClient(broker, 'chat_desktop_$empNo');
      _client!.port = port;
      _client!.logging(on: true); // 开启日志以便调试
      _client!.keepAlivePeriod = 60;
      _client!.autoReconnect = false; // 手动控制重连
      _client!.onConnected = _onConnected;
      _client!.onDisconnected = _onDisconnected;
      _client!.onSubscribed = _onSubscribed;

      // 设置连接消息（参考Java示例）
      final connMessage = MqttConnectMessage()
          .withClientIdentifier('chat_desktop_$empNo')
          .startClean() // 对应 cleanSession(true)
          .keepAliveFor(60); // 设置keepAlive

      // 如果有用户名密码
      if (username != null && password != null) {
        connMessage.authenticateAs(username, password);
      } else {
        // 即使不需要密码认证，也使用工号作为username（方便在EMQX中识别）
        // 注意：不要只设置withWillTopic而不设置payload，会导致空指针
        connMessage.authenticateAs(empNo, ''); // 使用工号作为用户名，密码为空
      }

      _client!.connectionMessage = connMessage;

      // 连接
      print('📡 [MQTT] 正在连接到 $broker:$port...');
      await _client!.connect();

      if (_client!.connectionStatus!.state == MqttConnectionState.connected) {
        print('✓ [MQTT] 连接成功');
        _updateConnectionState(MqttServiceState.connected);

        // 订阅Topic
        _subscribeToTopics(empNo);

        // 监听消息
        _client!.updates!.listen(_onMessage);

        return true;
      } else {
        print('✗ [MQTT] 连接失败: ${_client!.connectionStatus}');
        _updateConnectionState(MqttServiceState.error);
        return false;
      }
    } catch (e) {
      print('❌ [MQTT] 连接异常: $e');
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
    _updateConnectionState(MqttServiceState.disconnected);

    // 尝试重连
    if (!_isReconnecting) {
      _scheduleReconnect();
    }
  }

  /// 订阅成功回调
  void _onSubscribed(String topic) {
    print('✓ [MQTT] 订阅成功: $topic');
  }

  /// 计划重连
  void _scheduleReconnect() {
    if (_isReconnecting) return;

    _isReconnecting = true;
    print('🔄 [MQTT] 将在5秒后尝试重连...');

    _reconnectTimer = Timer(const Duration(seconds: 5), () async {
      if (_empNo != null) {
        print('🔄 [MQTT] 正在重连...');
        final success = await connect(
          broker: 'localhost',
          port: 1883,
          empNo: _empNo!,
        );

        if (!success) {
          _isReconnecting = false;
          _scheduleReconnect(); // 继续尝试
        }
      }
    });
  }

  /// 处理接收到的消息
  void _onMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final message in messages) {
      final topic = message.topic;
      final payload = message.payload as MqttPublishMessage;
      final messageStr =
          MqttPublishPayload.bytesToStringAsString(payload.payload.message);

      print('📨 [MQTT] 收到消息');
      print('   Topic: $topic');
      print('   Payload: $messageStr');

      try {
        final json = jsonDecode(messageStr) as Map<String, dynamic>;
        _handleMessage(topic, json);
      } catch (e) {
        print('❌ [MQTT] 消息解析失败: $e');
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

      // UUID去重：检查是否已存在相同UUID的任务
      final existingTasks = await _taskService.getAllTasks();
      final isDuplicate = existingTasks.any((t) => t.uuid == task.uuid);

      if (isDuplicate) {
        print('⚠️ [MQTT] 任务已存在，跳过创建 (UUID: ${task.uuid})');
        return;
      }

      // 直接保存完整的Task对象（包括uuid）
      await _taskService.createTaskDirect(task);

      print('✓ [MQTT] 待办已创建: ${task.title} (UUID: ${task.uuid})');

      // 通知UI刷新 - 使用广播流
      print('📊 [MQTT] 准备发送任务变更通知...');
      _taskChangeController.add(null);
      print('📊 [MQTT] 已发送任务变更通知 (监听器数量: ${_taskChangeController.hasListener})');

      // 显示通知
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

      // 优先使用UUID查找，否则使用taskId
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

      // 应用更改
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

      // 通知UI刷新
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

      // 通知UI刷新
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

        // 通知UI刷新
        _taskChangeController.add(null);

        await _showNotification(
          title: '待办已完成',
          body: task.title,
        );
      } else {
        await _taskService.markTaskAsIncomplete(task.id);
        print('✓ [MQTT] 待办标记为未完成: ${task.title}');

        // 通知UI刷新
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

      final builder = MqttClientPayloadBuilder();
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
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _isReconnecting = false;

    if (_client != null) {
      _updateConnectionState(MqttServiceState.disconnecting);
      _client!.disconnect();
      print('✓ [MQTT] 已断开连接');
    }
  }

  /// 释放资源
  void dispose() {
    disconnect();
    _connectionStateController.close();
    _taskChangeController.close();
  }
}
