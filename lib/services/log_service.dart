import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// 日志级别
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// 日志服务 - 管理应用日志的写入和清理
class LogService {
  static LogService? _instance;
  static LogService get instance {
    _instance ??= LogService._();
    return _instance!;
  }

  LogService._();

  /// 日志目录
  Directory? _logDir;

  /// 当前日志文件
  File? _currentLogFile;

  /// 崩溃日志文件
  File? _crashLogFile;

  /// 日志保留天数
  static const int logRetentionDays = 7;

  /// 是否已初始化
  bool _initialized = false;

  /// 初始化日志服务
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 获取应用文档目录
      final appDocDir = await getApplicationDocumentsDirectory();
      _logDir = Directory('${appDocDir.path}/logs');

      // 创建日志目录（如果不存在）
      if (!await _logDir!.exists()) {
        await _logDir!.create(recursive: true);
      }

      // 创建今天的日志文件
      await _createTodayLogFile();

      // 创建崩溃日志文件
      await _createCrashLogFile();

      // 清理旧日志
      await _cleanOldLogs();

      _initialized = true;
      await log('日志服务已初始化', level: LogLevel.info);
    } catch (e) {
      print('❌ [LOG] 初始化失败: $e');
    }
  }

  /// 创建今天的日志文件
  Future<void> _createTodayLogFile() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final logFileName = 'app_$today.log';
    _currentLogFile = File('${_logDir!.path}/$logFileName');

    // 如果文件不存在，创建并写入头部信息（带 UTF-8 BOM）
    if (!await _currentLogFile!.exists()) {
      await _currentLogFile!.create();
      // 添加 UTF-8 BOM + 头部信息
      final content = '\uFEFF=== Chat Desktop 日志 - $today ===\n';
      await _currentLogFile!.writeAsString(
        content,
        mode: FileMode.append,
        encoding: utf8,
      );
    }
  }

  /// 创建崩溃日志文件
  Future<void> _createCrashLogFile() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final crashLogFileName = 'crash_$today.log';
    _crashLogFile = File('${_logDir!.path}/$crashLogFileName');

    // 如果文件不存在，创建并写入头部信息（带 UTF-8 BOM）
    if (!await _crashLogFile!.exists()) {
      await _crashLogFile!.create();
      // 添加 UTF-8 BOM + 头部信息
      final content = '\uFEFF=== Chat Desktop 崩溃日志 - $today ===\n';
      await _crashLogFile!.writeAsString(
        content,
        mode: FileMode.append,
        encoding: utf8,
      );
    }
  }

  /// 检查并切换日志文件（如果日期变更）
  Future<void> _checkAndRotateLogFile() async {
    if (_currentLogFile == null) {
      await _createTodayLogFile();
      return;
    }

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final currentFileName = _currentLogFile!.path.split('/').last;

    // 如果当前日志文件不是今天的，创建新文件
    if (!currentFileName.contains(today)) {
      await _createTodayLogFile();
      await _cleanOldLogs(); // 日期变更时清理旧日志
    }
  }

  /// 写入日志
  Future<void> log(
    String message, {
    LogLevel level = LogLevel.info,
    String? tag,
  }) async {
    if (!_initialized) {
      print('⚠️ [LOG] 日志服务未初始化: $message');
      return;
    }

    try {
      // 检查是否需要切换日志文件
      await _checkAndRotateLogFile();

      // 格式化时间戳
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());

      // 格式化日志级别
      String levelStr;
      switch (level) {
        case LogLevel.debug:
          levelStr = 'DEBUG';
          break;
        case LogLevel.info:
          levelStr = 'INFO ';
          break;
        case LogLevel.warning:
          levelStr = 'WARN ';
          break;
        case LogLevel.error:
          levelStr = 'ERROR';
          break;
      }

      // 构建日志行
      final tagStr = tag != null ? '[$tag] ' : '';
      final logLine = '[$timestamp] [$levelStr] $tagStr$message\n';

      // 写入文件（使用UTF-8编码）
      await _currentLogFile!.writeAsString(
        logLine,
        mode: FileMode.append,
        encoding: utf8,
      );

      // 同时输出到控制台（可选）
      print(logLine.trim());
    } catch (e) {
      print('❌ [LOG] 写入失败: $e');
    }
  }

  /// 清理旧日志文件
  Future<void> _cleanOldLogs() async {
    try {
      if (_logDir == null || !await _logDir!.exists()) return;

      final now = DateTime.now();
      final cutoffDate = now.subtract(Duration(days: logRetentionDays));

      // 列出所有日志文件
      final files = await _logDir!.list().toList();

      for (final entity in files) {
        if (entity is File && entity.path.endsWith('.log')) {
          final fileName = entity.path.split('/').last;

          // 从文件名提取日期 (格式: app_yyyy-MM-dd.log 或 crash_yyyy-MM-dd.log)
          final dateMatch = RegExp(r'(app|crash)_(\d{4}-\d{2}-\d{2})\.log').firstMatch(fileName);

          if (dateMatch != null) {
            final dateStr = dateMatch.group(2)!;
            final fileDate = DateFormat('yyyy-MM-dd').parse(dateStr);

            // 如果文件日期早于保留期限，删除
            if (fileDate.isBefore(cutoffDate)) {
              await entity.delete();
              print('🗑️  [LOG] 已删除旧日志: $fileName');
            }
          }
        }
      }
    } catch (e) {
      print('❌ [LOG] 清理旧日志失败: $e');
    }
  }

  /// 获取日志目录路径
  String? get logDirectory => _logDir?.path;

  /// 获取所有日志文件
  Future<List<File>> getAllLogFiles() async {
    if (_logDir == null || !await _logDir!.exists()) {
      return [];
    }

    final files = await _logDir!.list().toList();
    return files
        .whereType<File>()
        .where((f) => f.path.endsWith('.log'))
        .toList();
  }

  /// 读取日志文件内容
  Future<String> readLogFile(File logFile) async {
    try {
      return await logFile.readAsString();
    } catch (e) {
      return '读取日志失败: $e';
    }
  }

  /// 便捷方法：Debug日志
  Future<void> debug(String message, {String? tag}) async {
    await log(message, level: LogLevel.debug, tag: tag);
  }

  /// 便捷方法：Info日志
  Future<void> info(String message, {String? tag}) async {
    await log(message, level: LogLevel.info, tag: tag);
  }

  /// 便捷方法：Warning日志
  Future<void> warning(String message, {String? tag}) async {
    await log(message, level: LogLevel.warning, tag: tag);
  }

  /// 便捷方法：Error日志
  Future<void> error(String message, {String? tag}) async {
    await log(message, level: LogLevel.error, tag: tag);
  }

  /// 记录崩溃信息到单独的崩溃日志文件
  Future<void> logCrash(String context, Object error, StackTrace stackTrace) async {
    if (_crashLogFile == null) {
      print('⚠️ [LOG] 崩溃日志文件未初始化');
      return;
    }

    try {
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());

      // 构建崩溃日志内容
      final crashLog = '''
================================================================================
[$timestamp] 程序崩溃
--------------------------------------------------------------------------------
上下文: $context

错误类型: ${error.runtimeType}
错误信息: $error

堆栈追踪:
$stackTrace
================================================================================

''';

      // 写入崩溃日志文件（使用UTF-8编码）
      await _crashLogFile!.writeAsString(
        crashLog,
        mode: FileMode.append,
        encoding: utf8,
      );

      // 同时输出到控制台
      print('💥 [CRASH] 崩溃已记录到文件: ${_crashLogFile!.path}');

      // 也记录到普通日志文件（使用 log 方法避免与参数名冲突）
      await log('$context - $error', level: LogLevel.error, tag: 'CRASH');
    } catch (e) {
      print('❌ [LOG] 写入崩溃日志失败: $e');
    }
  }
}
