import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// HTTP客户端工具类
/// 基于Dio，提供统一的HTTP请求处理、拦截器、错误处理等
class HttpClient {
  static HttpClient? _instance;
  late Dio _dio;

  HttpClient._() {
    _dio = Dio(_getBaseOptions());
    _setupInterceptors();
  }

  static HttpClient get instance {
    _instance ??= HttpClient._();
    return _instance!;
  }

  /// 获取Dio实例
  Dio get dio => _dio;

  /// 基础配置
  BaseOptions _getBaseOptions() {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';

    return BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      // 自动格式化响应数据
      responseType: ResponseType.json,
    );
  }

  /// 设置拦截器
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // 请求拦截
          print('🌐 [HTTP Request] ${options.method} ${options.uri}');
          if (options.data != null) {
            print('📦 [Request Data] ${options.data}');
          }

          // 添加认证token（如果需要）
          final token = dotenv.env['API_TOKEN'];
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          // 响应拦截
          print('✅ [HTTP Response] ${response.statusCode} ${response.requestOptions.uri}');
          handler.next(response);
        },
        onError: (error, handler) {
          // 错误拦截
          print('❌ [HTTP Error] ${error.requestOptions.uri}');
          print('   Status: ${error.response?.statusCode}');
          print('   Message: ${error.message}');
          if (error.response?.data != null) {
            print('   Data: ${error.response?.data}');
          }

          handler.next(error);
        },
      ),
    );
  }

  /// GET 请求
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST 请求
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT 请求
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PATCH 请求
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE 请求
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 统一错误处理
  HttpException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return HttpException(
          message: '请求超时，请检查网络连接',
          statusCode: 408,
          originalError: error,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        final message = _getErrorMessage(statusCode, error.response?.data);
        return HttpException(
          message: message,
          statusCode: statusCode,
          originalError: error,
          data: error.response?.data,
        );

      case DioExceptionType.cancel:
        return HttpException(
          message: '请求已取消',
          statusCode: 0,
          originalError: error,
        );

      case DioExceptionType.connectionError:
        return HttpException(
          message: '网络连接失败，请检查网络设置',
          statusCode: 0,
          originalError: error,
        );

      default:
        return HttpException(
          message: error.message ?? '未知错误',
          statusCode: 0,
          originalError: error,
        );
    }
  }

  /// 根据状态码获取错误消息
  String _getErrorMessage(int statusCode, dynamic data) {
    // 尝试从响应数据中提取错误消息
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'] ?? data['msg'];
      if (message != null) return message.toString();
    }

    // 默认错误消息
    switch (statusCode) {
      case 400:
        return '请求参数错误';
      case 401:
        return '未授权，请重新登录';
      case 403:
        return '没有访问权限';
      case 404:
        return '请求的资源不存在';
      case 500:
        return '服务器内部错误';
      case 502:
        return '网关错误';
      case 503:
        return '服务暂时不可用';
      default:
        return '请求失败 (状态码: $statusCode)';
    }
  }

  /// 更新基础URL
  void updateBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
    print('✓ 已更新API基础URL: $baseUrl');
  }

  /// 更新认证token
  void updateToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
    print('✓ 已更新认证Token');
  }

  /// 清除认证token
  void clearToken() {
    _dio.options.headers.remove('Authorization');
    print('✓ 已清除认证Token');
  }

  /// 设置超时时间
  void setTimeout({
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
  }) {
    if (connectTimeout != null) {
      _dio.options.connectTimeout = connectTimeout;
    }
    if (receiveTimeout != null) {
      _dio.options.receiveTimeout = receiveTimeout;
    }
    if (sendTimeout != null) {
      _dio.options.sendTimeout = sendTimeout;
    }
  }
}

/// HTTP异常类
class HttpException implements Exception {
  final String message;
  final int statusCode;
  final DioException? originalError;
  final dynamic data;

  HttpException({
    required this.message,
    required this.statusCode,
    this.originalError,
    this.data,
  });

  @override
  String toString() {
    return 'HttpException(message: $message, statusCode: $statusCode)';
  }

  /// 是否为网络错误
  bool get isNetworkError =>
      statusCode == 0 || statusCode == 408 || statusCode >= 500;

  /// 是否为认证错误
  bool get isAuthError => statusCode == 401 || statusCode == 403;

  /// 是否为客户端错误
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  /// 是否为服务器错误
  bool get isServerError => statusCode >= 500;
}
