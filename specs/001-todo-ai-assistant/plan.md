# 实施计划：待办事项与AI智能助手

**分支**: `001-todo-ai-assistant` | **日期**: 2025-11-27 | **规格**: [spec.md](./spec.md)
**输入**: 功能规格来自 `/specs/001-todo-ai-assistant/spec.md`

## 概述

本应用是一个Flutter构建的跨平台桌面应用（macOS + Windows），结合待办事项管理和多智能体AI助手对话功能。核心特性包括：
- 本地+云端同步的待办任务管理（WebSocket实时推送）
- 多AI智能体对���支持，用户可通过界面选择器切换
- 桌面常驻小窗口模式，带未读角标通知
- 无需用户登录（设备级数据隔离）

## 技术上下文

**语言/版本**: Flutter 3.16+ / Dart 3.2+
**主要依赖**:
- `web_socket_channel` - WebSocket客户端
- `hive` / `isar` - 本地数据持久化（NEEDS CLARIFICATION: 选择哪个）
- `riverpod` / `bloc` - 状态管理（NEEDS CLARIFICATION: 选择哪个）
- `window_manager` - 桌面窗口控制（小窗口模式）
- `http` / `dio` - AI服务HTTP客户端
- `flutter_local_notifications` - 系统通知
- `shared_preferences` - 用户偏好存储

**存储**: 本地数据库（Hive或Isar）+ WebSocket云端同步
**测试**: Flutter test framework (widget tests, unit tests, integration tests)
**目标平台**: macOS 10.14+, Windows 10+
**项目类型**: 桌面应用（单项目结构）
**性能目标**:
- 应用启动 < 2秒
- AI响应首字节 < 3秒
- 支持500+待办任务无明显卡顿
- 小窗口模式流畅拖动（60fps）

**约束**:
- 跨平台一致性（macOS和Windows功能对等）
- 离线可用（待办功能）
- 实时推送（WebSocket延迟 < 500ms）
- 小窗口always-on-top

**规模/范围**:
- 预期用户：企业内部或个人效率工具
- 4个主要用户故事
- 43个功能需求
- 6个数据实体
- 2-5个可选AI智能体

## 章程检查

*门禁：必须在Phase 0研究前通过。Phase 1设计后重新检查。*

### ✅ 一、跨平台一致性

**状态**: 合规

- 所有用户故事在macOS和Windows上功能对等
- 平台特定代码将隔离在`lib/platform/`接口实现中
- 小窗口模式、键盘快捷键等都有平台适配计划

**验证**:
- FR-009, FR-041-043明确要求跨平台一致性
- 小窗口always-on-top将使用`window_manager`包的跨平台API

### ✅ 二、Flutter最佳实践

**状态**: 合规

- 计划使用不可变widget和状态管理模式
- UI与业务逻辑分离（services层独立）
- 遵循flutter_lints规则

**验证**:
- 项目结构将按功能域组织（tasks/, chat/, window_manager/）
- Widget测试覆盖关键UI交互
- const构造函数将在编码阶段强制执行

### ✅ 三、桌面优先设计

**状态**: 合规

- 键盘导航支持（FR-041）
- 窗口调整大小和小窗口模式（FR-029-039）
- 平台适配的键盘快捷键（FR-041）

**验证**:
- 用户故事4专门针对桌面常驻小窗口功能
- 不涉及移动端触摸手势，全部使用鼠标+键盘交互

### ✅ 四、平台集成

**状态**: 合规

- 系统通知（FR-043）
- 平台原生键盘快捷键（FR-041）
- 文件选择对话框（FR-040，如需导入/导出）

**验证**:
- 将使用`flutter_local_notifications`和`window_manager`平台插件
- macOS和Windows的平台特定实现将通过公共接口抽象

### ✅ 五、可测试性与可维护性

**状态**: 合规

- 业务逻辑与UI分离（services/, models/, widgets/）
- 测试要求：widget tests, unit tests, integration tests
- 每个智能体独立对话历史，便于测试隔离

**验证**:
- 章程要求的测试类型将在tasks.md中具体化
- 状态管理模式确保可测试性（Riverpod或Bloc）

### 平台一致性强制

**状态**: 合规

- CI/CD将在两个平台构建和测试（尚未配置，记录TODO）
- 功能需求已明确标注跨平台要求

**待办**: 配置GitHub Actions或其他CI在macOS和Windows上运行测试

### 质量门禁

**状态**: 计划合规

- `flutter analyze` 零警告零错误
- 所有测试在两平台通过
- Widget测试覆盖关键交互

**待办**: 在tasks.md中添加质量门禁任务

## 项目结构

### 文档（本功能）

```text
specs/001-todo-ai-assistant/
├── plan.md              # 本文件 (/speckit.plan 命令输出)
├── research.md          # Phase 0 输出
├── data-model.md        # Phase 1 输出
├── quickstart.md        # Phase 1 输出
├── contracts/           # Phase 1 输出
│   ├── websocket.md     # WebSocket协议定义
│   └── ai_api.md        # AI服务API接口
└── tasks.md             # Phase 2 输出 (/speckit.tasks 命令)
```

### 源代码（仓库根目录）

```text
lib/
├── main.dart                    # 应用入口
├── app.dart                     # 根Widget
│
├── models/                      # 数据模型
│   ├── task.dart               # 待办任务
│   ├── ai_agent.dart           # AI智能体
│   ├── message.dart            # 对话消息
│   ├── conversation.dart       # 对话会话
│   ├── task_action.dart        # 任务操作
│   └── badge.dart              # 通知角标
│
├── services/                    # 业务逻辑服务
│   ├── task_service.dart       # 任务管理服务
│   ├── websocket_service.dart  # WebSocket同步服务
│   ├── ai_service.dart         # AI对话服务
│   ├── storage_service.dart    # 本地存储服务
│   └── notification_service.dart # 通知服务
│
├── providers/                   # 状态管理（Riverpod或Bloc）
│   ├── task_provider.dart
│   ├── chat_provider.dart
│   ├── agent_provider.dart
│   └── window_provider.dart
│
├── widgets/                     # UI组件
│   ├── tasks/                  # 待办任务相关widget
│   │   ├── task_list.dart
│   │   ├── task_item.dart
│   │   └── task_form.dart
│   ├── chat/                   # AI对话相关widget
│   │   ├── chat_view.dart
│   │   ├── agent_selector.dart
│   │   ├── message_bubble.dart
│   │   └── chat_input.dart
│   ├── window/                 # 窗口管理widget
│   │   ├── mini_window.dart    # 小窗口圆形图标
│   │   └── badge_indicator.dart # 角标
│   └── common/                 # 通用组件
│       ├── loading_indicator.dart
│       └── error_view.dart
│
├── screens/                     # 页面/屏幕
│   ├── home_screen.dart        # 主界面（任务+对话）
│   └── settings_screen.dart    # 设置界面
│
├── platform/                    # 平台特定代码
│   ├── platform_interface.dart  # 平台接口抽象
│   ├── macos_impl.dart         # macOS实现
│   └── windows_impl.dart       # Windows实现
│
└── utils/                       # 工具类
    ├── constants.dart
    ├── theme.dart
    └── validators.dart

test/
├── widget_test/                 # Widget测试
│   ├── task_list_test.dart
│   ├── chat_view_test.dart
│   └── mini_window_test.dart
├── unit_test/                   # 单元测试
│   ├── task_service_test.dart
│   ├── websocket_service_test.dart
│   └── ai_service_test.dart
└── integration_test/            # 集成测试
    ├── task_flow_test.dart
    ├── chat_flow_test.dart
    └── mini_window_test.dart

macos/                           # macOS平台配置
windows/                         # Windows平台配置
```

**结构决策**: 选择Flutter单项目结构，因为：
1. 这是一个桌面应用，不是Web+移动多端
2. macOS和Windows共享相同的Dart代码库
3. 平台特定代码通过`lib/platform/`抽象隔离
4. 符合章程的"按功能域组织"原则

## 复杂性追踪

> 仅在章程检查有违规需要说明时填写

**无违规** - 所有章程原则均已合规。

