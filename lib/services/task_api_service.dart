import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'http_client.dart';
import '../utils/env_config.dart';
import '../models/task.dart';
import '../models/task_page_result.dart';
import 'log_service.dart';

/// 任务相关 HTTP API
///
/// 说明：
/// - 创建任务成功返回 HTTP 204
/// - 按需求：创建完成后不写入本地 Isar，完全以 API 为准（通常由后端同步/推送刷新列表）
class TaskApiService {
  static TaskApiService? _instance;
  final Dio _dio;

  TaskApiService._() : _dio = Dio(_baseOptions()) {
    _dio.interceptors.addAll(HttpClient.instance.dio.interceptors);
  }

  static TaskApiService get instance {
    _instance ??= TaskApiService._();
    return _instance!;
  }

  static BaseOptions _baseOptions() {
    return BaseOptions(
      baseUrl: EnvConfig.unifyApiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
  }

  /// 创建任务（HTTP 204 视为成功）
  Future<void> createTask({
    required Task task,
    required String currentEmpNo,
  }) async {
    if (EnvConfig.debug) {
      await LogService.instance.info('UNIFY DEBUG=true：createTask 使用 Mock', tag: 'UNIFY');
      // Mock：模拟网络延迟
      await Future.delayed(const Duration(milliseconds: 250));
      return;
    }

    final path = EnvConfig.unifyCreateTaskPath.trim();
    if (path.isEmpty) {
      throw HttpException(
        message: '未配置创建任务 API PATH，请在 .env 设置 UNIFY_API_CREATE_TASK_PATH',
        statusCode: 0,
      );
    }

    final normalizedEmpNo = currentEmpNo.trim();
    if (normalizedEmpNo.isEmpty) {
      throw HttpException(
        message: '当前登录工号为空，无法创建任务',
        statusCode: 0,
      );
    }

    final normalizedAssignedToType = task.assignedToType?.trim();
    final normalizedAssignedTo = task.assignedTo?.trim();
    final dispatchNow = normalizedAssignedToType != null &&
        normalizedAssignedToType.isNotEmpty &&
        normalizedAssignedTo != null &&
        normalizedAssignedTo.isNotEmpty;

    final payload = <String, dynamic>{
      'title': task.title,
      'description': task.description,
      'dueDate': task.dueDate != null
          ? DateFormat('yyyy-MM-dd HH:mm').format(task.dueDate!)
          : null,
      'priority': task.priority.index,
      'tags': task.tags,
    };

    if (!dispatchNow) {
      // 不派发：要求传 empNo=当前工号
      payload['empNo'] = normalizedEmpNo;
    } else {
      // 派发：
      // - assignedToType=用户 => assignedTo=被派发人工号
      // - assignedToType=团队 => assignedTo=workGroup
      payload['assignedToType'] = normalizedAssignedToType;
      payload['assignedTo'] = normalizedAssignedTo;
      payload['assignedBy'] = normalizedEmpNo;
    }

    // 去掉 null 字段，避免后端对空值敏感
    payload.removeWhere((key, value) => value == null);

    final response = await _dio.post(
      path,
      data: payload,
      options: Options(
        validateStatus: (status) =>
            status == 204 || (status != null && status >= 200 && status < 300),
      ),
    );

    final statusCode = response.statusCode ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      throw HttpException(
        message: '创建任务失败，HTTP $statusCode',
        statusCode: statusCode,
        data: response.data,
      );
    }
  }

  /// 任务已读（HTTP 204 视为成功）
  Future<void> markTaskRead({required String taskUuid}) async {
    if (EnvConfig.debug) {
      await LogService.instance.info('UNIFY DEBUG=true：taskRead 使用 Mock', tag: 'UNIFY');
      await Future.delayed(const Duration(milliseconds: 120));
      return;
    }

    final path = EnvConfig.unifyTaskReadPath.trim();
    if (path.isEmpty) {
      throw HttpException(
        message: '未配置任务已读 API PATH，请在 .env 设置 UNIFY_API_TASK_READ_PATH',
        statusCode: 0,
      );
    }

    final response = await _dio.post(
      path,
      data: {'taskUuid': taskUuid},
      options: Options(
        validateStatus: (status) =>
            status == 204 || (status != null && status >= 200 && status < 300),
      ),
    );

    final statusCode = response.statusCode ?? 0;
    if (statusCode != 204) {
      throw HttpException(
        message: '任务已读失败，HTTP $statusCode',
        statusCode: statusCode,
        data: response.data,
      );
    }
  }

  /// 任务完成（HTTP 204 视为成功）
  Future<void> completeTask({required String taskUuid}) async {
    if (EnvConfig.debug) {
      await LogService.instance.info('UNIFY DEBUG=true：taskCompleted 使用 Mock', tag: 'UNIFY');
      await Future.delayed(const Duration(milliseconds: 120));
      return;
    }

    final path = EnvConfig.unifyTaskCompletePath.trim();
    if (path.isEmpty) {
      throw HttpException(
        message: '未配置任务完成 API PATH，请在 .env 设置 UNIFY_API_TASK_COMPLETE_PATH',
        statusCode: 0,
      );
    }

    final response = await _dio.post(
      path,
      data: {'taskUuid': taskUuid},
      options: Options(
        validateStatus: (status) =>
            status == 204 || (status != null && status >= 200 && status < 300),
      ),
    );

    final statusCode = response.statusCode ?? 0;
    if (statusCode != 204) {
      throw HttpException(
        message: '任务完成失败，HTTP $statusCode',
        statusCode: statusCode,
        data: response.data,
      );
    }
  }

  /// 获取任务分页列表
  ///
  /// 说明：
  /// - `page` 从 0 开始
  /// - `empNo` 用于“我的任务”
  /// - `assignedBy` 用于“我派发的任务”
  /// - `title` 任务名称关键词
  /// - 到期时间区间使用 `dueDateStart` / `dueDateEnd`（格式 `yyyy-MM-dd HH:mm`）
  Future<TaskPageResult> fetchTaskPage({
    required int page,
    required int size,
    String? empNo,
    String? assignedBy,
    String? title,
    DateTime? dueDateStart,
    DateTime? dueDateEnd,
  }) async {
    if (EnvConfig.debug) {
      await LogService.instance.info('UNIFY DEBUG=true：selectTaskPage 使用 Mock', tag: 'UNIFY');
      await Future.delayed(const Duration(milliseconds: 250));
      return _mockTaskPage(
        page: page,
        size: size,
        empNo: empNo,
        assignedBy: assignedBy,
        title: title,
        dueDateStart: dueDateStart,
        dueDateEnd: dueDateEnd,
      );
    }

    final path = EnvConfig.unifyTaskListPath.trim();
    if (path.isEmpty) {
      throw HttpException(
        message: '未配置任务分页 API PATH，请在 .env 设置 UNIFY_API_TASK_LIST_PATH',
        statusCode: 0,
      );
    }

    final query = <String, dynamic>{
      'page': page,
      'size': size,
      'empNo': empNo,
      'assignedBy': assignedBy,
      'title': title,
      'dueDateStart': dueDateStart != null
          ? DateFormat('yyyy-MM-dd HH:mm').format(dueDateStart)
          : null,
      'dueDateEnd': dueDateEnd != null
          ? DateFormat('yyyy-MM-dd HH:mm').format(dueDateEnd)
          : null,
    }..removeWhere((key, value) {
        if (value == null) return true;
        if (value is String && value.trim().isEmpty) return true;
        return false;
      });

    final response = await _dio.get(
      path,
      queryParameters: query,
      options: Options(
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );

    final data = response.data;
    if (data is! Map) {
      throw HttpException(
        message: '任务分页响应格式无效（期望对象）',
        statusCode: response.statusCode ?? 0,
        data: data,
      );
    }

    DateTime? parseDateTime(String? raw) {
      if (raw == null) return null;
      final text = raw.trim();
      if (text.isEmpty) return null;
      try {
        // yyyy-MM-dd HH:mm:ss
        if (text.length >= 19 && text.contains(':')) {
          return DateFormat('yyyy-MM-dd HH:mm:ss').parse(text);
        }
        // yyyy-MM-dd HH:mm
        if (text.length >= 16 && text.contains(':')) {
          return DateFormat('yyyy-MM-dd HH:mm').parse(text);
        }
      } catch (_) {}
      return null;
    }

    Priority parsePriority(dynamic raw) {
      final idx = (raw is int) ? raw : int.tryParse(raw?.toString() ?? '');
      switch (idx) {
        case 0:
          return Priority.low;
        case 2:
          return Priority.high;
        case 1:
        default:
          return Priority.medium;
      }
    }

    final contentRaw = data['content'];
    final List<Task> tasks = (contentRaw is List ? contentRaw : const [])
        .whereType<Map>()
        .map((e) {
          final json = Map<String, dynamic>.from(e);
          final createdAt = parseDateTime(json['createdAt']?.toString()) ?? DateTime.now();
          final updatedAt = parseDateTime(json['updatedAt']?.toString()) ?? createdAt;
          return Task(
            id: (json['id'] is int) ? (json['id'] as int) : 0,
            uuid: json['taskUuid']?.toString(),
            title: (json['title'] ?? '').toString(),
            description: (json['description']?.toString().trim().isEmpty ?? true)
                ? null
                : json['description']?.toString(),
            priority: parsePriority(json['priority']),
            isCompleted: json['isCompleted'] == true,
            isRead: json['isRead'] == true,
            dueDate: parseDateTime(json['dueDate']?.toString()),
            createdAt: createdAt,
            updatedAt: updatedAt,
            source: (json['source']?.toString() == '1') ? TaskSource.ai : TaskSource.manual,
            createdByAgentId: json['createdByAgentId']?.toString(),
            completedAt: parseDateTime(json['completedAt']?.toString()),
            tags: json['tags']?.toString(),
            assignedTo: json['assignedTo']?.toString(),
            assignedToType: json['assignedToType']?.toString(),
            assignedBy: json['assignedBy']?.toString(),
            assignedAt: parseDateTime(json['assignedAt']?.toString()),
            allowDispatch: false,
          );
        })
        .toList(growable: false);

    int parseInt(dynamic v) =>
        (v is int) ? v : int.tryParse(v?.toString() ?? '') ?? 0;

    return TaskPageResult(
      totalPages: parseInt(data['totalPages']),
      totalElements: parseInt(data['totalElements']),
      numberOfElements: parseInt(data['numberOfElements']),
      size: parseInt(data['size']),
      number: parseInt(data['number']),
      content: tasks,
    );
  }

  TaskPageResult _mockTaskPage({
    required int page,
    required int size,
    String? empNo,
    String? assignedBy,
    String? title,
    DateTime? dueDateStart,
    DateTime? dueDateEnd,
  }) {
    final now = DateTime.now();
    final totalPages = 10;
    final totalElements = totalPages * size;

    DateTime? normalize(DateTime? d) =>
        d == null ? null : DateTime(d.year, d.month, d.day, d.hour, d.minute);

    final start = normalize(dueDateStart);
    final end = normalize(dueDateEnd);

    final items = List.generate(size, (i) {
      final index = page * size + i + 1;
      final due = now.add(Duration(hours: index));

      final belongsToMy =
          empNo != null && empNo.trim().isNotEmpty ? true : false;
      final belongsToAssigned =
          assignedBy != null && assignedBy.trim().isNotEmpty ? true : false;

      final mockUuid = 'mock-task-$index';
      final mockTitle = title != null && title.trim().isNotEmpty
          ? '[$title] Mock任务 $index'
          : 'Mock任务 $index';

      final task = Task(
        id: index,
        uuid: mockUuid,
        title: mockTitle,
        description: '## Mock 描述\n- 序号：$index\n- 仅用于 DEBUG=true 调试',
        priority: Priority.values[index % Priority.values.length],
        isCompleted: index % 4 == 0,
        isRead: index % 3 == 0,
        dueDate: due,
        createdAt: now.subtract(Duration(days: index)),
        updatedAt: now.subtract(Duration(days: index - 1)),
        source: TaskSource.manual,
        createdByAgentId: null,
        completedAt: index % 4 == 0 ? now.subtract(Duration(hours: 1)) : null,
        tags: index % 2 == 0 ? 'mock' : '',
        assignedTo: belongsToAssigned ? '运维团队' : '',
        assignedToType: belongsToAssigned ? '团队' : '',
        assignedBy: belongsToAssigned ? (assignedBy ?? '') : '',
        assignedAt: belongsToAssigned ? now.subtract(const Duration(days: 1)) : null,
        allowDispatch: false,
      );

      return task;
    }).where((t) {
      final d = t.dueDate;
      if (d == null) return true;
      if (start != null && d.isBefore(start)) return false;
      if (end != null && d.isAfter(end)) return false;
      return true;
    }).toList(growable: false);

    final numberOfElements = items.length;

    return TaskPageResult(
      totalPages: totalPages,
      totalElements: totalElements,
      numberOfElements: numberOfElements,
      size: size,
      number: page,
      content: items,
    );
  }
}
