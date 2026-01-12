import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'http_client.dart';
import '../utils/env_config.dart';

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
    required String title,
    String? description,
    DateTime? dueDate,
    bool dispatchNow = false,
    String? assignedTo,
    String? assignedToType, // 用户 / 团队
    required String assignedBy, // 登录人工号
  }) async {
    final path = EnvConfig.unifyCreateTaskPath.trim();
    if (path.isEmpty) {
      throw HttpException(
        message: '未配置创建任务 API PATH，请在 .env 设置 UNIFY_API_CREATE_TASK_PATH',
        statusCode: 0,
      );
    }

    final payload = <String, dynamic>{
      'title': title,
      'description': description,
      'dueDate': dueDate != null
          ? DateFormat('yyyy-MM-dd HH:mm').format(dueDate)
          : null,
    };

    if (dispatchNow) {
      payload['assignedTo'] = assignedTo;
      payload['assignedToType'] = assignedToType;
      payload['assignedBy'] = assignedBy;
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
}
