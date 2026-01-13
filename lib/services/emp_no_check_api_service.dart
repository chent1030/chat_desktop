import 'package:dio/dio.dart';

import '../utils/env_config.dart';
import 'http_client.dart';
import 'log_service.dart';

/// 工号检测 API
///
/// 规则：
/// - 返回体“有内容”视为检测成功；空对象/空数组/空字符串视为失败
/// - HTTP 2xx 视为请求成功
class EmpNoCheckApiService {
  static EmpNoCheckApiService? _instance;
  final Dio _dio;

  EmpNoCheckApiService._() : _dio = Dio(_baseOptions()) {
    _dio.interceptors.addAll(HttpClient.instance.dio.interceptors);
  }

  static EmpNoCheckApiService get instance {
    _instance ??= EmpNoCheckApiService._();
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
      responseType: ResponseType.json,
    );
  }

  Future<bool> verifyEmpNo({required String empNo}) async {
    final normalized = empNo.trim();
    if (normalized.isEmpty) return false;

    if (EnvConfig.debug) {
      await LogService.instance.info('UNIFY DEBUG=true：empNo check 使用 Mock', tag: 'UNIFY');
      await Future.delayed(const Duration(milliseconds: 120));
      return normalized.length >= 3;
    }

    final path = EnvConfig.unifyEmpNoCheckPath.trim();
    if (path.isEmpty) {
      throw HttpException(
        message: '未配置工号检测 API PATH，请在 .env 设置 UNIFY_API_EMP_NO_CHECK_PATH',
        statusCode: 0,
      );
    }

    // GET 请求：query 参数为 empNo
    final response = await _dio.get(
      path,
      queryParameters: {'empNo': normalized},
    );

    final data = response.data;
    if (data == null) return false;
    if (data is String) return data.trim().isNotEmpty;
    if (data is List) return data.isNotEmpty;
    if (data is Map) return data.isNotEmpty;
    return true;
  }
}
