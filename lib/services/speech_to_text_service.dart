import 'dart:io';
import 'package:dio/dio.dart';

/// 语音转文字服务
class SpeechToTextService {
  final Dio _dio;
  static SpeechToTextService? _instance;
  String? token;
  Response? tokenResponse;

  SpeechToTextService._internal() : _dio = Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  static SpeechToTextService get instance {
    _instance ??= SpeechToTextService._internal();
    return _instance!;
  }

  /// 上传音频文件并转换为文字
  ///
  /// [audioFilePath] 音频文件路径
  /// [apiUrl] API接口地址
  Future<String> uploadAndTranscribe(String audioFilePath, String apiUrl) async {
    try {
      final file = File(audioFilePath);
      if (!await file.exists()) {
        throw Exception('音频文件不存在: $audioFilePath');
      }
      tokenResponse = await _dio.post('https://ipaas.catl.com/gateway/outside/ipaas/ipaas/ipaas_getJwtToken', data: {
        "appKey": "TIMES-YL31AR20",
        "appSecret": "585331fc-cca7-4184-97e3-82315993a67d",
        "time": "60"
      }, options: Options(
        headers: {
          'deipaaskeyauth': 'Wc3X579QXQw99925W214iZ38B8w2sr7H',
        },
      ));
      print('✓ 获取Token成功: ${tokenResponse!.data}');
      token = tokenResponse!.data['accessToken'];
      // 准备表单数据
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          audioFilePath,
          filename: audioFilePath.split('/').last,
        ),
      });

      print('正在上传音频文件: $audioFilePath');

      // 发送HTTP POST请求
      final response = await _dio.post(
        apiUrl,
        data: formData,
        options: Options(
          headers: {
            'deipaaskeyauth': 'Wc3X579QXQw99925W214iZ38B8w2sr7H',
            'deipaasjwt': 'Bearer $token'
          },
        )
      );
      print('语音转文字: ${response.data}');
      if (response.statusCode == 200) {
        // 假设API返回格式: {"result": "识别的文字内容"}
        final text = response.data['result'] as String;
        print('✓ 语音转文字成功: ${text.length} 字符');
        return text;
      } else {
        throw Exception('API请求失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('✗ 上传失败: ${e.message}');
      if (e.response != null) {
        print('  响应数据: ${e.response?.data}');
      }
      throw Exception('上传失败: ${e.message}');
    } catch (e) {
      print('✗ 转换失败: $e');
      throw Exception('转换失败: $e');
    }
  }
}
