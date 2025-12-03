# Tasks: 待办事项与AI智能助手

**Input**: 设计文档来自 `/specs/001-todo-ai-assistant/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: 规格说明中未明确要求测试任务,因此本任务列表专注于实现任务

**Organization**: 任务按用户故事分组,确保每个故事可以独立实现和测试

## Format: `[ID] [P?] [Story] Description`

- **[P]**: 可并行运行(不同文件,无依赖)
- **[Story]**: 任务所属的用户故事(例如: US1, US2, US3, US4)
- 描述中包含准确的文件路径

## Path Conventions

本项目为Flutter桌面应用单项目结构:
- 源代码: `lib/` (根目录)
- 测试: `test/` (根目录)
- 平台配置: `macos/`, `windows/`

---

## Phase 1: Setup (共享基础设施)

**Purpose**: 项目初始化和基本结构搭建

- [X] T001 根据plan.md创建Flutter项目结构和目录
- [X] T002 初始化Flutter项目并配置pubspec.yaml依赖(isar, riverpod, window_manager等)
- [X] T003 [P] 配置flutter_lints和代码格式化规则
- [X] T004 [P] 创建.env.example环境变量模板文件
- [X] T005 [P] 配置macOS平台权限和entitlements (macos/Runner/DebugProfile.entitlements)
- [X] T006 [P] 配置Windows平台权限和manifest (windows/runner/main.cpp)

---

## Phase 2: Foundational (阻塞性前置条件)

**Purpose**: 所有用户故事依赖的核心基础设施,必须在任何用户故事实现前完成

**⚠️ CRITICAL**: 此阶段完成前无法开始任何用户故事的实现

- [ ] T007 创建Isar数据模型基类和注解定义 (跳过-Isar 3.x使用@Collection注解和part文件)
- [X] T008 [P] 实现StorageService初始化Isar数据库 in lib/services/storage_service.dart
- [X] T009 [P] 配置Riverpod ProviderScope和全局providers in lib/main.dart
- [X] T010 [P] 实现window_manager初始化和窗口配置 in lib/main.dart
- [X] T011 [P] 创建应用主题配置 in lib/utils/theme.dart
- [X] T012 [P] 创建通用常量定义 in lib/utils/constants.dart
- [X] T013 [P] 创建表单验证工具类 in lib/utils/validators.dart
- [X] T014 [P] 创建通用Loading和Error widgets in lib/widgets/common/
- [X] T015 [P] 实现环境配置管理(读取.env文件) in lib/services/config_service.dart
- [X] T016 [P] 配置flutter_dotenv加载环境变量 (已在ConfigService.initialize()中实现)
- [X] T017 运行代码生成器生成Isar和Riverpod代码: flutter pub run build_runner build

**Checkpoint**: 基础设施就绪 - 用户故事实现现在可以并行开始

---

## Phase 3: User Story 1 - 创建和管理待办事项 (Priority: P1) 🎯 MVP

**Goal**: 用户可以创建、查看、编辑、完成和删除待办任务,支持优先级和截止日期,数据本地持久化

**Independent Test**: 创建新任务 → 修改任务属性(标题/优先级/截止日期) → 标记完成 → 删除任务 → 重启应用验证数据保留

### Implementation for User Story 1

#### 数据模型层

- [X] T018 [P] [US1] 创建Task实体模型 in lib/models/task.dart (包含Priority和TaskSource枚举)
- [X] T019 [P] [US1] 创建TaskAction实体模型 in lib/models/task_action.dart (包含ActionType枚举)
- [X] T020 [US1] 运行代码生成器生成Task和TaskAction的Isar schema: flutter pub run build_runner build

#### 服务层

- [X] T021 [US1] 实现TaskService管理任务CRUD操作 in lib/services/task_service.dart
- [X] T022 [US1] 在TaskService中实现任务筛选和排序逻辑(按状态/优先级/截止日期) (已在T021中实现)
- [X] T023 [US1] 在TaskService中实现TaskAction记录功能(用于审计和撤销) (已在T021中实现)

#### 状态管理层

- [X] T024 [P] [US1] 创建TaskListProvider管理任务列表状态 in lib/providers/task_provider.dart
- [X] T025 [P] [US1] 创建TaskFormProvider管理任务表单状态 in lib/providers/task_provider.dart

#### UI层 - Widgets

- [X] T026 [P] [US1] 创建TaskItem widget显示单个任务 in lib/widgets/tasks/task_item.dart
- [X] T027 [P] [US1] 创建TaskList widget显示任务列表 in lib/widgets/tasks/task_list.dart
- [X] T028 [P] [US1] 创建TaskForm widget用于创建/编辑任务 in lib/widgets/tasks/task_form.dart
- [X] T029 [US1] 在TaskForm中实现优先级选择器和截止日期选择器 (已在T028中实现)
- [X] T030 [US1] 在TaskList中实现任务排序和筛选UI控件 (已在T027中实现)

#### UI层 - Screens

- [X] T031 [US1] 创建HomeScreen主界面集成TaskList in lib/screens/home_screen.dart
- [X] T032 [US1] 在HomeScreen中实现"添加任务"浮动按钮 (已在T031中实现)
- [X] T033 [US1] 实现任务完成状态切换交互(点击复选框) (已在TaskItem中实现)
- [X] T034 [US1] 实现任务编辑和删除交互(长按或右键菜单) (已在TaskItem中实现)
- [X] T035 [US1] 添加空状态提示(任务列表为空时) (已在TaskList中实现)

**Checkpoint**: 此时,用户故事1应完全功能化并可独立测试

---

## Phase 4: User Story 2 - AI智能助手对话 (Priority: P2)

**Goal**: 用户可以与多个AI助手对话,在智能体选择器中切换不同助手,每个助手独立保存对话历史

**Independent Test**: 选择智能体 → 发送消息并接收响应 → 切换智能体验证历史独立 → 验证流式响应 → 重启应用验证历史保留

### Implementation for User Story 2

#### 数据模型层

- [X] T036 [P] [US2] 创建AIAgent实体模型 in lib/models/ai_agent.dart
- [X] T037 [P] [US2] 创建Message实体模型 in lib/models/message.dart (包含MessageRole和MessageStatus枚举)
- [X] T038 [P] [US2] 创建Conversation实体模型 in lib/models/conversation.dart
- [X] T039 [US2] 运行代码生成器生成AIAgent/Message/Conversation的Isar schema (执行中...)

#### 服务层

- [X] T040 [US2] 实现AIServiceAdapter接口定义 in lib/services/ai_service.dart
- [X] T041 [P] [US2] 实现OpenAIAdapter适配OpenAI GPT API in lib/services/adapters/openai_adapter.dart
- [X] T042 [P] [US2] 实现AnthropicAdapter适配Anthropic Claude API in lib/services/adapters/anthropic_adapter.dart
- [X] T043 [US2] 实现AIService统一管理多智能体调用 in lib/services/ai_service.dart
- [X] T044 [US2] 在AIService中实现流式响应处理(Server-Sent Events)
- [X] T045 [US2] 实现ConversationService管理会话和消息历史 in lib/services/conversation_service.dart
- [X] T046 [US2] 在ConversationService中实现自动标题生成功能
- [X] T047 [US2] 在StorageService中初始化预设AI智能体(GPT-4, Claude等)

#### 状态管理层

- [X] T048 [P] [US2] 创建AgentProvider管理智能体列表和当前选中智能体 in lib/providers/agent_provider.dart
- [X] T049 [P] [US2] 创建ChatProvider管理对话状态和消息流 in lib/providers/chat_provider.dart
- [X] T050 [P] [US2] 创建ConversationProvider管理会话历史 in lib/providers/chat_provider.dart

#### UI层 - Widgets

- [X] T051 [P] [US2] 创建AgentSelector widget显示智能体选择器 in lib/widgets/chat/agent_selector.dart
- [X] T052 [P] [US2] 创建MessageBubble widget显示单条消息 in lib/widgets/chat/message_bubble.dart
- [X] T053 [P] [US2] 创建ChatInput widget实现消息输入框 in lib/widgets/chat/chat_input.dart
- [X] T054 [US2] 创建ChatView widget集成完整对话界面 in lib/widgets/chat/chat_view.dart
- [X] T055 [US2] 在ChatView中实现流式响应显示(逐字显示)
- [X] T056 [US2] 在ChatView中实现加载指示器和错误提示
- [X] T057 [US2] 在AgentSelector中显示智能体名称/描述/图标

#### UI层 - Screens整合

- [X] T058 [US2] 在HomeScreen中集成ChatView(右侧面板)
- [X] T059 [US2] 实现HomeScreen左右分栏布局(任务列表+AI对话)
- [X] T060 [US2] 实现智能体切换时的对话历史切换逻辑
- [X] T061 [US2] 实现"清除对话历史"功能
- [X] T062 [US2] 实现记住上次使用的智能体功能(SharedPreferences)

**Checkpoint**: 此时,用户故事1和2应都能独立工作

---

## Phase 5: User Story 4 - 桌面常驻小窗口模式 (Priority: P2)

**Goal**: 用户可以将应用缩小为桌面圆形图标,显示未读角标,可拖动位置,双击恢复完整窗口

**Independent Test**: 缩小到小窗口 → 拖动图标到不同位置 → 模拟推送触发角标显示 → 双击恢复完整窗口 → 验证位置记忆

### Implementation for User Story 4

#### 数据模型层

- [ ] T063 [US4] 创建Badge计算逻辑(不持久化,实时计算) in lib/services/badge_service.dart

#### 服务层

- [ ] T064 [US4] 实现NotificationService管理系统通知 in lib/services/notification_service.dart
- [ ] T065 [US4] 在BadgeService中实现未读消息计数逻辑
- [ ] T066 [US4] 在BadgeService中实现未读任务更新计数逻辑
- [ ] T067 [US4] 实现WebSocketService建立WebSocket连接 in lib/services/websocket_service.dart
- [ ] T068 [US4] 在WebSocketService中实现心跳机制(30秒PING/PONG)
- [ ] T069 [US4] 在WebSocketService中实现自动重连逻辑(指数退避)
- [ ] T070 [US4] 在WebSocketService中实现任务推送消息处理(task_push事件)
- [ ] T071 [US4] 在WebSocketService中实现离线队列机制

#### 状态管理层

- [ ] T072 [P] [US4] 创建WindowStateProvider管理窗口模式状态 in lib/providers/window_provider.dart
- [ ] T073 [P] [US4] 创建BadgeProvider管理未读角标计数 in lib/providers/window_provider.dart
- [ ] T074 [P] [US4] 创建WebSocketProvider管理连接状态 in lib/providers/websocket_provider.dart

#### UI层 - Widgets

- [ ] T075 [P] [US4] 创建MiniWindow widget实现圆形图标 in lib/widgets/window/mini_window.dart
- [ ] T076 [P] [US4] 创建BadgeIndicator widget显示未读角标 in lib/widgets/window/badge_indicator.dart
- [ ] T077 [US4] 在MiniWindow中实现拖动功能(使用window_manager)
- [ ] T078 [US4] 在MiniWindow中实现双击恢复完整窗口功能
- [ ] T079 [US4] 在BadgeIndicator中实现角标数字动画效果

#### 窗口管理逻辑

- [ ] T080 [US4] 实现窗口缩小到小窗口模式的逻辑(setAlwaysOnTop + setSize)
- [ ] T081 [US4] 实现窗口位置记忆功能(SharedPreferences保存/恢复)
- [ ] T082 [US4] 实现窗口状态记忆功能(应用重启后恢复上次状态)
- [ ] T083 [US4] 在HomeScreen中添加缩小按钮触发小窗口模式
- [ ] T084 [US4] 实现WebSocket推送触发角标更新的集成逻辑
- [ ] T085 [US4] 实现用户查看消息/任务后清除对应角标的逻辑

#### 平台适配

- [ ] T086 [P] [US4] 创建PlatformInterface抽象平台特定功能 in lib/platform/platform_interface.dart
- [ ] T087 [P] [US4] 实现MacOSImpl平台实现 in lib/platform/macos_impl.dart
- [ ] T088 [P] [US4] 实现WindowsImpl平台实现 in lib/platform/windows_impl.dart

**Checkpoint**: 此时,用户故事1、2和4应都能独立工作

---

## Phase 6: User Story 3 - AI辅助待办事项管理 (Priority: P3)

**Goal**: 用户可以通过自然语言请求AI助手帮助创建、修改或组织待办事项

**Independent Test**: 向AI发送"添加明天下午3点的会议任务" → 验证任务列表更新 → 询问AI"我今天需要做什么" → 验证AI总结任务

### Implementation for User Story 3

#### 服务层

- [ ] T089 [US3] 扩展AIService实现任务解析API调用 in lib/services/ai_service.dart
- [ ] T090 [US3] 在AIService中实现解析结果到Task模型的转换逻辑
- [ ] T091 [US3] 在ConversationService中实现任务上下文注入(当前任务列表)
- [ ] T092 [US3] 实现AI操作确认机制(显示确认对话框)

#### UI层 - Widgets

- [ ] T093 [US3] 创建TaskConfirmationDialog widget显示AI解析的任务 in lib/widgets/tasks/task_confirmation_dialog.dart
- [ ] T094 [US3] 在ChatView中集成任务操作意图识别和确认流程
- [ ] T095 [US3] 实现AI消息中的任务卡片显示(可点击确认创建)

#### 集成逻辑

- [ ] T096 [US3] 在ChatProvider中实现AI响应解析任务操作意图
- [ ] T097 [US3] 实现AI创建任务后更新TaskList的联动逻辑
- [ ] T098 [US3] 实现AI查询任务时注入当前任务上下文的逻辑
- [ ] T099 [US3] 在TaskAction中记录AI创建的任务(createdByAgentId字段)

**Checkpoint**: 所有用户故事现在应该都能独立功能化

---

## Phase 7: WebSocket数据同步 (Cross-Cutting)

**Purpose**: 实现待办任务的云端实时同步功能,支持所有用户故事

- [ ] T100 [P] 在WebSocketService中实现任务创建消息发送(task_create)
- [ ] T101 [P] 在WebSocketService中实现任务更新消息发送(task_update)
- [ ] T102 [P] 在WebSocketService中实现任务删除消息发送(task_delete)
- [ ] T103 [P] 在WebSocketService中实现任务同步请求(sync_request)
- [ ] T104 在TaskService中集成WebSocket发送逻辑(创建/更新/删除时)
- [ ] T105 实现任务同步冲突解决逻辑(Last Write Wins策略)
- [ ] T106 在TaskProvider中实现WebSocket推送监听和UI自动更新
- [ ] T107 实现应用启动时的增量同步逻辑(基于lastSyncedAt)

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: 影响多个用户故事的改进和优化

- [ ] T108 [P] 实现键盘快捷键支持(macOS Cmd, Windows Ctrl) in lib/utils/keyboard_shortcuts.dart
- [ ] T109 [P] 实现窗口大小自适应和响应式布局
- [ ] T110 [P] 优化Isar查询性能(添加复合索引)
- [ ] T111 [P] 实现应用图标和logo资源 in assets/
- [ ] T112 [P] 添加中文本地化字符串 in lib/l10n/
- [ ] T113 代码清理:移除调试日志和未使用的imports
- [ ] T114 运行flutter analyze确保零警告零错误
- [ ] T115 性能优化:减少不必要的widget重建
- [ ] T116 安全性:验证用户输入(任务标题/AI消息)
- [ ] T117 [P] 创建应用启动加载页面 in lib/screens/splash_screen.dart
- [ ] T118 [P] 实现错误边界和全局错误处理
- [ ] T119 按照quickstart.md验证完整应用流程
- [ ] T120 在macOS和Windows上进行完整功能测试

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: 无依赖 - 可以立即开始
- **Foundational (Phase 2)**: 依赖Setup完成 - 阻塞所有用户故事
- **User Stories (Phase 3-6)**: 都依赖Foundational完成
  - 如有团队资源,用户故事可以并行进行
  - 或按优先级顺序执行 (P1 → P2 → P3)
- **WebSocket同步 (Phase 7)**: 依赖US1和US4完成
- **Polish (Phase 8)**: 依赖所有期望的用户故事完成

### User Story Dependencies

- **User Story 1 (P1)**: Foundational完成后可开始 - 无其他故事依赖
- **User Story 2 (P2)**: Foundational完成后可开始 - 无其他故事依赖
- **User Story 4 (P2)**: Foundational完成后可开始 - 与US1集成但可独立测试
- **User Story 3 (P3)**: 依赖US1和US2完成 - 需要任务管理和AI对话功能

### Within Each User Story

- 数据模型 → 服务层 → 状态管理 → UI组件 → 屏幕集成
- 运行代码生成器在模型创建后
- 核心实现完成后再进行集成
- 故事完成后再进入下一个优先级

### Parallel Opportunities

- Phase 1中所有[P]标记的任务可并行运行
- Phase 2中所有[P]标记的任务可并行运行
- Foundational完成后,所有用户故事可并行开始(如团队容量允许)
- 每个用户故事内,所有[P]标记的任务可并行运行
- 不同用户故事可由不同团队成员并行处理

---

## Parallel Example: User Story 1

```bash
# 同时启动User Story 1的所有模型任务:
Task T018: "创建Task实体模型 in lib/models/task.dart"
Task T019: "创建TaskAction实体模型 in lib/models/task_action.dart"

# 同时启动User Story 1的所有widget任务:
Task T026: "创建TaskItem widget in lib/widgets/tasks/task_item.dart"
Task T027: "创建TaskList widget in lib/widgets/tasks/task_list.dart"
Task T028: "创建TaskForm widget in lib/widgets/tasks/task_form.dart"
```

## Parallel Example: User Story 2

```bash
# 同时启动User Story 2的所有适配器任务:
Task T041: "实现OpenAIAdapter in lib/services/adapters/openai_adapter.dart"
Task T042: "实现AnthropicAdapter in lib/services/adapters/anthropic_adapter.dart"

# 同时启动User Story 2的所有provider任务:
Task T048: "创建AgentProvider in lib/providers/agent_provider.dart"
Task T049: "创建ChatProvider in lib/providers/chat_provider.dart"
Task T050: "创建ConversationProvider in lib/providers/chat_provider.dart"
```

---

## Implementation Strategy

### MVP First (仅User Story 1)

1. 完成 Phase 1: Setup
2. 完成 Phase 2: Foundational (关键 - 阻塞所有故事)
3. 完成 Phase 3: User Story 1
4. **停止并验证**: 独立测试User Story 1
5. 如果就绪,部署/演示

### Incremental Delivery (增量交付)

1. 完成Setup + Foundational → 基础就绪
2. 添加User Story 1 → 独立测试 → 部署/演示 (MVP!)
3. 添加User Story 2 → 独立测试 → 部署/演示
4. 添加User Story 4 → 独立测试 → 部署/演示
5. 添加User Story 3 → 独立测试 → 部署/演示
6. 每个故事都增加价值而不破坏之前的故事

### Parallel Team Strategy (并行团队策略)

多开发者团队:

1. 团队一起完成Setup + Foundational
2. Foundational完成后:
   - 开发者A: User Story 1
   - 开发者B: User Story 2
   - 开发者C: User Story 4
3. 故事独立完成并集成

---

## Task Summary

- **总任务数**: 120个任务
- **Phase 1 (Setup)**: 6个任务
- **Phase 2 (Foundational)**: 11个任务 (关键阻塞点)
- **Phase 3 (US1)**: 18个任务 - MVP核心
- **Phase 4 (US2)**: 27个任务
- **Phase 5 (US4)**: 26个任务
- **Phase 6 (US3)**: 11个任务
- **Phase 7 (WebSocket)**: 8个任务
- **Phase 8 (Polish)**: 13个任务

### User Story Task Count

- **US1 (P1 - MVP)**: 18个任务
- **US2 (P2)**: 27个任务
- **US4 (P2)**: 26个任务
- **US3 (P3)**: 11个任务

### Parallel Opportunities Identified

- **Setup阶段**: 5个并行任务 (T003-T006)
- **Foundational阶段**: 9个并行任务 (T008-T016)
- **US1阶段**: 5组并行任务
- **US2阶段**: 8组并行任务
- **US4阶段**: 5组并行任务
- **Polish阶段**: 8个并行任务

### Suggested MVP Scope

**最小可行产品 (MVP)**: 仅实现User Story 1

- Phase 1: Setup (6个任务)
- Phase 2: Foundational (11个任务)
- Phase 3: User Story 1 (18个任务)
- **总计**: 35个任务完成MVP

MVP提供核心价值: 用户可以创建、管理和跟踪待办任务,数据本地持久化,应用重启后保留

---

## Notes

- [P] 任务 = 不同文件,无依赖,可并行
- [Story] 标签将任务映射到特定用户故事以便追踪
- 每个用户故事应该可以独立完成和测试
- 在每个checkpoint验证故事独立性
- 每个任务或逻辑组完成后提交
- 避免: 模糊任务、相同文件冲突、破坏独立性的跨故事依赖
- 运行`flutter pub run build_runner build`在每次修改数据模型后
- 在macOS和Windows两个平台上测试所有功能
