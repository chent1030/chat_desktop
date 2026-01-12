import 'package:dio/dio.dart';
import '../models/dispatch_candidate.dart';
import 'http_client.dart';
import '../utils/env_config.dart';

/// 派发候选列表 API
///
/// 返回示例：[{empName, empNo, workGroup, access_group}, ...]
class DispatchCandidateApiService {
  static DispatchCandidateApiService? _instance;
  final Dio _dio;

  DispatchCandidateApiService._() : _dio = Dio(_baseOptions()) {
    _dio.interceptors.addAll(HttpClient.instance.dio.interceptors);
  }

  static DispatchCandidateApiService get instance {
    _instance ??= DispatchCandidateApiService._();
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

  Future<List<DispatchCandidate>> fetchCandidates() async {
    final path = EnvConfig.unifyDispatchCandidatesPath.trim();
    if (path.isEmpty) {
      throw HttpException(
        message: '未配置派发候选列表 API PATH，请在 .env 设置 UNIFY_API_DISPATCH_CANDIDATES_PATH',
        statusCode: 0,
      );
    }

    final response = await _dio.get(path);
    final data = response.data;
    if (data is! List) {
      throw HttpException(
        message: '派发候选列表响应格式无效（期望数组）',
        statusCode: response.statusCode ?? 0,
        data: data,
      );
    }

    return data
        .whereType<Map>()
        .map((e) => DispatchCandidate.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
