# 修改工号功能说明

## 功能描述

允许用户在运行时修改工号，解决输错工号导致无法接收MQTT推送的问题。

## 使用方法

### 1. 通过菜单修改工号

1. 点击应用右上角的 **⋮** (更多菜单)
2. 在菜单中可以看到当前工号：**修改工号 (61016968)**
3. 点击该选项
4. 在弹出的对话框中输入新工号
5. 点击"确认"保存

### 2. 修改流程

```
用户点击"修改工号"
    ↓
断开当前MQTT连接
    ↓
显示工号输入弹窗
    ↓
用户输入新工号 (或取消)
    ↓
保存新工号并重新连接MQTT
```

## 界面说明

### 修改工号弹窗

- **标题**: "修改工号" (区别于首次使用时的"输入工号")
- **提示文本**: "修改工号后，将断开当前连接并使用新工号重新连接MQTT"
- **预填充**: 自动填充当前工号，方便用户查看和修改
- **可取消**: 允许用户点击"取消"按钮或按ESC键取消修改

### 菜单显示

在"更多"菜单中会显示：
```
搜索任务
清除已完成任务
────────────────
修改工号 (当前工号)
```

## 使用场景

1. **首次输入错误**：用户首次启动应用时输错了工号
2. **切换账号**：需要切换到另一个工号来接收不同的任务推送
3. **验证工号**：查看当前使用的工号是否正确

## 注意事项

1. **断开连接**：修改工号会先断开当前MQTT连接
2. **重新连接**：输入新工号后会自动使用新工号连接MQTT
3. **取消操作**：如果取消修改，会使用原工号重新连接
4. **无需重启**：修改工号不需要重启应用，实时生效

## 技术实现

### 相关文件

- `lib/screens/home_screen.dart` - 添加菜单选项和修改逻辑
- `lib/widgets/common/emp_no_dialog.dart` - 工号输入弹窗（支持修改模式）

### 核心逻辑

```dart
// 修改工号流程
Future<void> _showChangeEmpNoDialog() async {
  final currentEmpNo = _configService.empNo;

  // 1. 断开MQTT连接
  await _mqttService.disconnect();

  // 2. 显示工号输入弹窗（允许取消）
  final newEmpNo = await EmpNoDialog.show(context, canDismiss: true);

  if (newEmpNo != null && newEmpNo.isNotEmpty) {
    // 3. 用户输入了新工号，EmpNoDialog已自动连接MQTT
    if (newEmpNo != currentEmpNo) {
      // 显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('工号已修改为: $newEmpNo')),
      );
    }
  } else {
    // 4. 用户取消了，使用原工号重新连接
    if (currentEmpNo != null) {
      await _mqttService.connect(
        broker: AppConstants.mqttBrokerHost,
        port: AppConstants.mqttBrokerPort,
        empNo: currentEmpNo,
      );
    }
  }
}
```

### 弹窗模式判断

```dart
// 判断是否是修改模式
final isEditMode = widget.canDismiss && _empNoController.text.isNotEmpty;

// 根据模式显示不同的标题和提示
Text(isEditMode ? '修改工号' : '输入工号')
Text(
  isEditMode
      ? '修改工号后，将断开当前连接并使用新工号重新连接MQTT'
      : '请输入您的工号以启用MQTT待办同步功能',
)
```

## 日志输出

修改工号时会输出以下日志：

```
📡 [MQTT] 已断开连接，准备修改工号
✓ 工号已从 61016968 修改为 123456
📡 [MQTT] 正在连接到 localhost:1883...
✓ [MQTT] 连接成功
```

如果用户取消修改：
```
📡 [MQTT] 已断开连接，准备修改工号
ℹ️ 用户取消修改，使用原工号重新连接: 61016968
📡 [MQTT] 正在连接到 localhost:1883...
```

## 常见问题

### Q: 修改工号后之前的待办会丢失吗？
A: 不会。本地数据库中的待办不会受影响，只是MQTT推送会订阅新工号的主题。

### Q: 可以随时修改工号吗？
A: 可以。在应用运行期间随时可以通过菜单修改工号。

### Q: 修改工号需要重启应用吗？
A: 不需要。修改后会自动断开并重新连接MQTT，实时生效。

### Q: 如果输错新工号怎么办？
A: 可以再次点击"修改工号"重新输入正确的工号。

## 相关文档

- [MQTT环境变量配置](./MQTT_ENV_CONFIG.md)
- [EMQX连接配置](./EMQX_CONFIG.md)
- [MQTT测试指南](./MQTT_TEST_GUIDE.md)
