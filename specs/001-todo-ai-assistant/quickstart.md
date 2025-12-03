# 快速开始指南：待办事项与AI智能助手

**功能**: 001-todo-ai-assistant
**日期**: 2025-11-27
**目标**: 快速搭建和运行Flutter桌面应用

## 前置条件

### 系统要求

**macOS**:
- macOS 10.14 (Mojave) 或更高版本
- Xcode 13.0 或更高版本
- CocoaPods 1.11 或更高版本

**Windows**:
- Windows 10 1809 或更高版本
- Visual Studio 2022 或更高版本
  - 必须安装"使用C++的桌面开发"工作负载

### 开发工具

1. **Flutter SDK 3.16+**
   ```bash
   # 检查Flutter版本
   flutter --version

   # 如果需要升级
   flutter upgrade
   ```

2. **Dart SDK 3.2+** (随Flutter一起安装)

3. **IDE** (选择其一):
   - Android Studio + Flutter插件
   - VS Code + Flutter扩展
   - IntelliJ IDEA + Flutter插件

## 快速启动（5分钟）

### 1. 克隆仓库

```bash
git clone <repository-url>
cd chat_desktop
git checkout 001-todo-ai-assistant
```

### 2. 安装依赖

```bash
# 获取Flutter依赖
flutter pub get

# 运行代码生成
flutter pub run build_runner build
```

### 3. 配置环境

复制环境配置模板：

```bash
cp .env.example .env
```

编辑`.env`文件，配置API密钥：

```env
# AI服务API密钥
OPENAI_API_KEY=sk-your-openai-key
ANTHROPIC_API_KEY=sk-ant-your-anthropic-key

# WebSocket服务端点
WEBSOCKET_URL=wss://api.example.com/ws/tasks

# 设备ID（首次启动时自动生成）
DEVICE_ID=
```

### 4. 运行应用

**macOS**:
```bash
flutter run -d macos
```

**Windows**:
```bash
flutter run -d windows
```

### 5. 验证功能

应用启动后，测试以下功能：

- ✅ 创建一个待办任务
- ✅ 标记任务为完成
- ✅ 打开AI助手，发送一条消息
- ✅ 切换不同的AI智能体
- ✅ 缩小窗口到桌面小图标

## 完整安装指南

### 步骤1：项目初始化

```bash
# 创建Flutter桌面项目（如果从头开始）
flutter create --platforms=macos,windows chat_desktop
cd chat_desktop

# 切换到feature分支
git checkout -b 001-todo-ai-assistant
```

### 步骤2：配置依赖

编辑`pubspec.yaml`：

```yaml
name: chat_desktop
description: 待办事项与AI智能助手桌面应用
version: 1.0.0+1

environment:
  sdk: '>=3.2.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # 状态管理
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0

  # 数据持久化
  isar: ^3.1.0
  isar_flutter_libs: ^3.1.0
  path_provider: ^2.1.0

  # WebSocket
  web_socket_channel: ^2.4.0

  # 桌面窗口管理
  window_manager: ^0.3.7

  # 系统通知
  flutter_local_notifications: ^16.3.0

  # HTTP客户端
  dio: ^5.4.0

  # 工具
  shared_preferences: ^2.2.2
  uuid: ^4.3.0
  flutter_dotenv: ^5.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1

  # 代码生成
  build_runner: ^2.4.7
  riverpod_generator: ^2.3.9
  isar_generator: ^3.1.0

flutter:
  uses-material-design: true
  assets:
    - .env
```

### 步骤3：项目结构

创建项目目录结构：

```bash
# 创建主要目录
mkdir -p lib/{models,services,providers,widgets,screens,platform,utils}
mkdir -p lib/widgets/{tasks,chat,window,common}
mkdir -p test/{widget_test,unit_test,integration_test}

# 创建contracts目录
mkdir -p lib/platform
```

### 步骤4：生成Isar模型

创建`lib/models/task.dart`：

```dart
import 'package:isar/isar.dart';

part 'task.g.dart';

@collection
class Task {
  Id id = Isar.autoIncrement;

  late String title;
  String? description;

  @enumerated
  late Priority priority;

  late bool isCompleted;

  @Index()
  late DateTime createdAt;

  DateTime? dueDate;
  DateTime? completedAt;

  String? serverId;

  @Index()
  late DateTime lastSyncedAt;

  late bool isSynced;
  late bool isDeleted;

  @enumerated
  late TaskSource source;

  String? createdByAgentId;
}

enum Priority {
  low,
  medium,
  high,
}

enum TaskSource {
  local,
  server,
  ai,
}
```

创建其他模型（Message, Conversation, AIAgent）...

运行代码生成：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 步骤5：初始化数据库

创建`lib/services/storage_service.dart`：

```dart
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/task.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import '../models/ai_agent.dart';

class StorageService {
  late final Isar isar;

  Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();

    isar = await Isar.open(
      [TaskSchema, MessageSchema, ConversationSchema, AIAgentSchema],
      directory: dir.path,
      inspector: true, // 开发环境启用
    );

    // 初始化预设AI智能体
    await _initializeAgents();
  }

  Future<void> _initializeAgents() async {
    final existingAgents = await isar.aIAgents.count();
    if (existingAgents > 0) return;

    final agents = [
      AIAgent()
        ..agentId = 'gpt-4'
        ..name = 'GPT-4'
        ..description = '通用AI助手，适合各类对话'
        ..endpoint = 'https://api.openai.com/v1/chat/completions'
        ..isEnabled = true
        ..isDefault = true
        ..sortOrder = 1
        ..messageCount = 0
        ..lastUsedAt = DateTime.now(),

      AIAgent()
        ..agentId = 'claude-3'
        ..name = 'Claude 3'
        ..description = '擅长分析和创作的AI助手'
        ..endpoint = 'https://api.anthropic.com/v1/messages'
        ..isEnabled = true
        ..isDefault = false
        ..sortOrder = 2
        ..messageCount = 0
        ..lastUsedAt = DateTime.now(),
    ];

    await isar.writeTxn(() async {
      await isar.aIAgents.putAll(agents);
    });
  }
}
```

### 步骤6：配置Riverpod

创建`lib/main.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:window_manager/window_manager.dart';
import 'services/storage_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 加载环境变量
  await dotenv.load(fileName: ".env");

  // 初始化窗口管理器
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(1200, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: '待办事项与AI智能助手',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  // 初始化数据库
  final storageService = StorageService();
  await storageService.initialize();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
      ],
      child: MyApp(),
    ),
  );
}
```

### 步骤7：创建基础UI

创建`lib/app.dart`：

```dart
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '待办事项与AI智能助手',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: HomeScreen(),
    );
  }
}
```

创建`lib/screens/home_screen.dart`（示例）：

```dart
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('待办事项与AI智能助手'),
      ),
      body: Row(
        children: [
          // 左侧：待办任务列表
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey[100],
              child: Center(child: Text('任务列表')),
            ),
          ),
          // 右侧：AI对话
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              child: Center(child: Text('AI助手')),
            ),
          ),
        ],
      ),
    );
  }
}
```

## 平台特定配置

### macOS配置

1. 编辑`macos/Runner/DebugProfile.entitlements`：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <!-- 网络访问权限 -->
  <key>com.apple.security.network.client</key>
  <true/>
  <!-- 文件系统访问 -->
  <key>com.apple.security.files.user-selected.read-write</key>
  <true/>
</dict>
</plist>
```

2. 同样编辑`Release.entitlements`

### Windows配置

1. 编辑`windows/runner/Runner.rc`，设置应用图标和版本信息

2. 如需管理员权限，编辑`windows/runner/main.cpp`

## 开发工作流

### 代码生成

当修改模型或Provider时，运行代码生成：

```bash
# 一次性生成
flutter pub run build_runner build --delete-conflicting-outputs

# 监听模式（开发时推荐）
flutter pub run build_runner watch
```

### 运行测试

```bash
# Widget测试
flutter test test/widget_test/

# 单元测试
flutter test test/unit_test/

# 集成测试
flutter test integration_test/

# 所有测试
flutter test
```

### 代码检查

```bash
# 运行linter
flutter analyze

# 格式化代码
dart format lib test
```

### 热重载

开发时使用热重载加速迭代：

```bash
# 在运行的应用中按 'r' 进行热重载
# 或按 'R' 进行完全重启
```

## 调试指南

### 1. Isar Inspector

在浏览器中查看数据库：

1. 确保`inspector: true`已启用
2. 运行应用
3. 控制台会显示Inspector URL: `http://localhost:port`
4. 在浏览器打开该URL

### 2. Riverpod DevTools

安装DevTools扩展：

```bash
dart pub global activate devtools
devtools
```

### 3. 日志输出

使用logger包记录详细日志：

```dart
import 'package:logger/logger.dart';

final logger = Logger();

logger.d('Debug信息');
logger.i('Info信息');
logger.w('警告');
logger.e('错误');
```

## 常见问题

### Q1: WebSocket连接失败

**症状**: 应用启动后无法连接到WebSocket服务器

**解决**:
1. 检查`.env`中的`WEBSOCKET_URL`是否正确
2. 确保网络权限已配置（见平台特定配置）
3. 检查后端服务是否运行

### Q2: Isar模型生成失败

**症状**: 运行`build_runner`时报错

**解决**:
```bash
# 清理并重新生成
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Q3: 小窗口模式不工作

**症状**: 缩小到小窗口时崩溃或显示异常

**解决**:
1. 确保`window_manager`版本正确
2. 检查平台权限配置
3. 查看控制台错误信息

### Q4: AI响应超时

**症状**: 发送消息后长时间无响应

**解决**:
1. 检查API Key是否正确且有效
2. 检查网络连接
3. 增加超时时间：
   ```dart
   final dio = Dio()
     ..options.connectTimeout = Duration(seconds: 30)
     ..options.receiveTimeout = Duration(seconds: 60);
   ```

## 性能优化建议

### 1. 构建优化

```bash
# Release模式构建（显著提升性能）
flutter build macos --release
flutter build windows --release
```

### 2. 减少不必要的重建

使用`const`构造函数：

```dart
// 好
const Text('Hello');

// 不好
Text('Hello');
```

### 3. 延迟加载

对于大型列表，使用`ListView.builder`：

```dart
ListView.builder(
  itemCount: tasks.length,
  itemBuilder: (context, index) {
    return TaskItem(task: tasks[index]);
  },
)
```

## 下一步

完成快速启动后，建议：

1. 阅读`spec.md`了解完整功能规格
2. 查看`data-model.md`理解数据结构
3. 参考`contracts/`目录了解API接口
4. 运行`/speckit.tasks`生成详细任务列表
5. 开始实现用户故事1（待办事项管理）

## 有用的命令

```bash
# 查看设备列表
flutter devices

# 查看依赖树
flutter pub deps

# 更新依赖
flutter pub upgrade

# 清理构建缓存
flutter clean

# 检查Flutter安装
flutter doctor -v

# 分析包大小
flutter build macos --analyze-size
```

## 资源链接

- [Flutter桌面文档](https://docs.flutter.dev/desktop)
- [Isar文档](https://isar.dev/)
- [Riverpod文档](https://riverpod.dev/)
- [window_manager插件](https://pub.dev/packages/window_manager)
- [项目规格说明](./spec.md)
- [数据模型文档](./data-model.md)

---

**祝开发顺利！** 如遇问题，请查看文档或提Issue。
