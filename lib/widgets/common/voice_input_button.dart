import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// 语音输入按钮组件
/// 支持录音并返回音频文件路径
class VoiceInputButton extends StatefulWidget {
  /// 录音完成回调 - 返回音频文件路径
  final Function(String audioPath) onRecordComplete;

  /// 录音取消回调
  final VoidCallback? onRecordCancel;

  /// 按钮大小
  final double size;

  /// 按钮颜色
  final Color? color;

  /// 是否启用
  final bool enabled;

  const VoiceInputButton({
    super.key,
    required this.onRecordComplete,
    this.onRecordCancel,
    this.size = 40,
    this.color,
    this.enabled = true,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _timer;
  String? _currentRecordPath;

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  /// 开始录音
  Future<void> _startRecording() async {
    try {
      // 检查是否有麦克风权限
      if (!await _audioRecorder.hasPermission()) {
        _showError('没有麦克风权限，请在系统设置中允许应用访问麦克风');
        return;
      }

      // 生成音频文件路径
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordPath = path.join(
        directory.path,
        'voice_$timestamp.mp3',
      );

      // 配置录音参数
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc, // MP3格式（AAC编码）
        sampleRate: 44100, // 44.1kHz 采样率
        bitRate: 128000, // 128kbps 比特率
        numChannels: 1, // 单声道
      );

      // 开始录音
      await _audioRecorder.start(
        config,
        path: _currentRecordPath!,
      );

      setState(() {
        _isRecording = true;
        _recordDuration = 0;
      });

      // 启动计时器
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordDuration++;
          });
        }
      });

      print('✓ 开始录音: $_currentRecordPath');
    } catch (e) {
      print('✗ 开始录音失败: $e');
      _showError('录音失败: $e');
    }
  }

  /// 停止录音
  Future<void> _stopRecording() async {
    try {
      _timer?.cancel();

      final path = await _audioRecorder.stop();

      setState(() {
        _isRecording = false;
        _recordDuration = 0;
      });

      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          print('✓ 录音完成: $path (${await file.length()} bytes)');
          widget.onRecordComplete(path);
        } else {
          print('✗ 录音文件不存在: $path');
          _showError('录音文件不存在');
        }
      } else {
        print('✗ 录音路径为空');
        _showError('录音失败');
      }
    } catch (e) {
      print('✗ 停止录音失败: $e');
      _showError('停止录音失败: $e');
      setState(() {
        _isRecording = false;
        _recordDuration = 0;
      });
    }
  }

  /// 取消录音
  Future<void> _cancelRecording() async {
    try {
      _timer?.cancel();
      await _audioRecorder.stop();

      // 删除录音文件
      if (_currentRecordPath != null) {
        final file = File(_currentRecordPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      setState(() {
        _isRecording = false;
        _recordDuration = 0;
        _currentRecordPath = null;
      });

      widget.onRecordCancel?.call();
      print('✓ 录音已取消');
    } catch (e) {
      print('✗ 取消录音失败: $e');
      setState(() {
        _isRecording = false;
        _recordDuration = 0;
      });
    }
  }

  /// 切换录音状态
  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  /// 显示错误提示
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// 格式化录音时长
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isRecording) {
      // 录音中状态
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 录音时长显示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(_recordDuration),
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // 取消按钮
          IconButton(
            icon: const Icon(Icons.close),
            iconSize: widget.size * 0.6,
            color: Colors.grey,
            onPressed: _cancelRecording,
            tooltip: '取消录音',
          ),

          // 停止/完成按钮
          IconButton(
            icon: const Icon(Icons.check_circle),
            iconSize: widget.size,
            color: Colors.green,
            onPressed: _stopRecording,
            tooltip: '完成录音',
          ),
        ],
      );
    }

    // 未录音状态
    return IconButton(
      icon: Icon(
        Icons.mic,
        size: widget.size * 0.6,
      ),
      iconSize: widget.size,
      color: widget.color ?? theme.colorScheme.primary,
      onPressed: widget.enabled ? _toggleRecording : null,
      tooltip: '语音输入',
    );
  }
}
