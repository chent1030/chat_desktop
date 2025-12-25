import 'package:flutter/material.dart';
import '../../services/config_service.dart';
import '../../services/mqtt_service.dart';
import '../../utils/constants.dart';

/// 工号输入弹窗
class EmpNoDialog extends StatefulWidget {
  /// 是否可以关闭（首次强制输入时为false）
  final bool canDismiss;

  const EmpNoDialog({
    super.key,
    this.canDismiss = true,
  });

  /// 显示弹窗
  static Future<String?> show(
    BuildContext context, {
    bool canDismiss = true,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: canDismiss,
      builder: (context) => EmpNoDialog(canDismiss: canDismiss),
    );
  }

  @override
  State<EmpNoDialog> createState() => _EmpNoDialogState();
}

class _EmpNoDialogState extends State<EmpNoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _empNoController = TextEditingController();
  final _configService = ConfigService.instance;
  final _mqttService = MqttService.instance;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 如果已有工号，预填充
    final existingEmpNo = _configService.empNo;
    if (existingEmpNo != null) {
      _empNoController.text = existingEmpNo;
    }
  }

  @override
  void dispose() {
    _empNoController.dispose();
    super.dispose();
  }

  /// 验证工号格式
  String? _validateEmpNo(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '请输入工号';
    }

    final trimmed = value.trim();

    if (trimmed.length < 3) {
      return '工号长度至少为3位';
    }

    if (trimmed.length > 20) {
      return '工号长度不能超过20位';
    }

    // 可以添加更多验证规则，如只允许数字、字母等
    // final regex = RegExp(r'^[a-zA-Z0-9]+$');
    // if (!regex.hasMatch(trimmed)) {
    //   return '工号只能包含字母和数字';
    // }

    return null;
  }

  /// 提交工号
  Future<void> _submitEmpNo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final empNo = _empNoController.text.trim();

      // 保存工号到配置
      await _configService.setEmpNo(empNo);

      // 连接到MQTT
      final connected = await _mqttService.connect(
        broker: AppConstants.mqttBrokerHost,
        port: AppConstants.mqttBrokerPort,
        empNo: empNo,
        username: AppConstants.mqttUsername,
        password: AppConstants.mqttPassword,
      );

      if (!connected) {
        setState(() {
          _errorMessage = 'MQTT连接失败，请检查网络设置';
          _isLoading = false;
        });
        return;
      }

      // 成功，关闭弹窗
      if (mounted) {
        Navigator.of(context).pop(empNo);
      }
    } catch (e) {
      setState(() {
        _errorMessage = '保存失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 判断是否是修改模式（已有工号且允许关闭）
    final isEditMode = widget.canDismiss && _empNoController.text.isNotEmpty;

    return PopScope(
      canPop: widget.canDismiss,
      child: AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.badge, color: Colors.blue),
            const SizedBox(width: 12),
            Text(isEditMode ? '修改工号' : '输入工号'),
            if (!widget.canDismiss) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '必填',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditMode
                      ? '修改工号后，将断开当前连接并使用新工号重新连接MQTT'
                      : '请输入您的工号以启用MQTT待办同步功能',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _empNoController,
                  autofocus: true,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: '工号',
                    hintText: '例如: 123456',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateEmpNo,
                  onFieldSubmitted: (_) => _submitEmpNo(),
                ),
                const SizedBox(height: 16),
                // 认证信息统一从环境变量读取（见 .env），此处不再展示输入项
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '工号用于接收个人待办推送和团队协作',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (widget.canDismiss)
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitEmpNo,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('确认'),
          ),
        ],
      ),
    );
  }
}
