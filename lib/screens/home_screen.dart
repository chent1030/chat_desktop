import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/task_provider.dart';
import '../providers/window_provider.dart';
import '../widgets/tasks/task_list.dart';
import '../widgets/tasks/task_form.dart';
import '../widgets/chat/chat_view.dart';
import '../widgets/common/emp_no_dialog.dart';
import '../widgets/tasks/unify_task_list_dialog.dart';
import '../services/config_service.dart';
import '../providers/font_provider.dart';
import '../utils/app_fonts.dart';
import '../services/mqtt_service.dart';
import '../utils/constants.dart';
import '../services/floating_window_service.dart';
import 'dart:io' show Platform;
import '../models/task.dart';

/// HomeScreen - 应用主界面
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0; // 0: 任务列表, 1: AI助手
  final _configService = ConfigService.instance;
  final _mqttService = MqttService.instance;
  bool _ipcListenerHooked = false;
  bool _initialUnreadSynced = false;

  @override
  void initState() {
    super.initState();
    // 延迟检查工号，确保UI已构建
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 强制初始化TaskListProvider，确保它订阅了所有需要的流
      print('🎯 [HomeScreen] 初始化 TaskListProvider');
      ref.read(taskListProvider);
      _checkAndInitializeMqtt();
    });
  }

  /// 检查工号并初始化MQTT
  Future<void> _checkAndInitializeMqtt() async {
    if (!_configService.hasEmpNo) {
      // 没有工号，显示弹窗（不可关闭）
      final empNo = await EmpNoDialog.show(context, canDismiss: false);

      if (empNo == null || empNo.isEmpty) {
        // 用户未输入工号（理论上不应该到这里，因为弹窗不可关闭）
        print('⚠️ [MQTT] 用户未输入工号');
        return;
      }
    } else {
      // 已有工号，直接连接MQTT
      final empNo = _configService.empNo!;
      print('📡 [MQTT] 使用已保存的工号连接: $empNo');

      await _mqttService.connect(
        broker: AppConstants.mqttBrokerHost,
        port: AppConstants.mqttBrokerPort,
        empNo: empNo,
        username: AppConstants.mqttUsername,
        password: AppConstants.mqttPassword,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskListState = ref.watch(taskListProvider);

    // 在 build 中注册 Riverpod 监听，符合 Riverpod 约束（避免 debugDoingBuild 断言）
    if (!_ipcListenerHooked) {
      _ipcListenerHooked = true;
      ref.listen<List<Task>>(unreadTasksProvider, (previous, next) {
        try {
          if (Platform.isWindows) {
            FloatingWindowService.instance.syncUnreadTasks(next);
          }
        } catch (_) {}
      });
    }

    // 首次构建后，同步一次未读列表给原生悬浮窗
    if (Platform.isWindows && !_initialUnreadSynced) {
      _initialUnreadSynced = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          final unread = ref.read(unreadTasksProvider);
          FloatingWindowService.instance.syncUnreadTasks(unread);
        } catch (_) {}
      });
    }

    // 检查屏幕宽度,决定是使用双栏布局还是标签页布局
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: _buildAppBar(theme, taskListState, isWideScreen),
      body:
          isWideScreen ? _buildWideScreenLayout() : _buildNarrowScreenLayout(),
      // 浮动按钮仅在窄屏任务列表页面显示
      floatingActionButton: (!isWideScreen && _selectedIndex == 0)
          ? FloatingActionButton.extended(
              onPressed: () => _showTaskFormDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('新建任务'),
            )
          : null,
    );
  }

  /// 宽屏布局 (左右分栏)
  Widget _buildWideScreenLayout() {
    return Row(
      children: [
        // 左侧任务列表侧边栏 (30%宽度)
        Container(
          width: 340,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              right: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // 顶部操作区
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showTaskFormDialog(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('新建任务'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _openPagedTaskDialog(),
                      icon: const Icon(Icons.table_rows, size: 18),
                      label: const Text('分页任务'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 紧凑型统计信息条
              _buildCompactStatistics(),

              // 任务列表
              const Expanded(
                child: TaskList(),
              ),
            ],
          ),
        ),

        // 右侧AI助手 (70%宽度)
        const Expanded(
          child: ChatPanel(),
        ),
      ],
    );
  }

  /// 窄屏布局 (标签页切换)
  Widget _buildNarrowScreenLayout() {
    return IndexedStack(
      index: _selectedIndex,
      children: [
        // 任务列表页面
        Column(
          children: [
            _buildStatisticsCard(),
            const Expanded(child: TaskList()),
          ],
        ),

        // AI助手页面
        const ChatPanel(),
      ],
    );
  }

  /// 构建AppBar
  PreferredSizeWidget _buildAppBar(
    ThemeData theme,
    TaskListState state,
    bool isWideScreen,
  ) {
    final currentFontKey = ref.watch(appFontKeyProvider);
    return AppBar(
      elevation: 0,
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
      title: Row(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            isWideScreen
                ? 'ChatDesktop'
                : (_selectedIndex == 0 ? '待办事项' : 'AI助手'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      leading: !isWideScreen
          ? IconButton(
              icon: Icon(_selectedIndex == 0 ? Icons.task_alt : Icons.chat),
              onPressed: () {
                setState(() {
                  _selectedIndex = _selectedIndex == 0 ? 1 : 0;
                });
              },
              tooltip: _selectedIndex == 0 ? '切换到AI助手' : '切换到任务列表',
            )
          : null,
      actions: [
        PopupMenuButton<String>(
          tooltip: '字体',
          icon: const Icon(Icons.text_fields, size: 20),
          onSelected: (key) async {
            await ref.read(appFontKeyProvider.notifier).setFontKey(key);
            if (!context.mounted) return;
            final label = AppFonts.optionForKey(key).label;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('已切换字体：$label')),
            );
          },
          itemBuilder: (context) {
            return AppFonts.options
                .map(
                  (o) => PopupMenuItem<String>(
                    value: o.key,
                    child: Row(
                      children: [
                        Icon(
                          o.key == currentFontKey
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                o.label,
                                style: TextStyle(fontFamily: o.family),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '示例：中文 ABC 123',
                                style: TextStyle(
                                  fontFamily: o.family,
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.65),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(growable: false);
          },
        ),
        // 更多菜单（合并搜索和清除功能）
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 20),
          onSelected: (value) async {
            if (value == 'search') {
              _showSearchDialog(context);
            } else if (value == 'clear_completed') {
              await _clearCompletedTasks();
            } else if (value == 'change_emp_no') {
              await _showChangeEmpNoDialog();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'search',
              child: Row(
                children: [
                  Icon(Icons.search, size: 18),
                  SizedBox(width: 8),
                  Text('搜索任务'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear_completed',
              child: Row(
                children: [
                  Icon(Icons.clear_all, size: 18),
                  SizedBox(width: 8),
                  Text('清除已完成任务'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'change_emp_no',
              child: Row(
                children: [
                  const Icon(Icons.badge, size: 18),
                  const SizedBox(width: 8),
                  Text('修改工号 (${_configService.empNo ?? '未设置'})'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Future<void> _openPagedTaskDialog() async {
    await UnifyTaskListDialog.show(
      context,
      type: UnifyTaskListDialogType.myTasks,
    );
  }

  /// 构建紧凑型统计信息（侧边栏用）
  Widget _buildCompactStatistics() {
    final statisticsAsync = ref.watch(taskStatisticsProvider);
    final currentFilter = ref.watch(
      taskListProvider.select((state) => state.filter),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: statisticsAsync.when(
        data: (stats) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildCompactStatItem(
              label: '未完成',
              value: stats['incomplete'].toString(),
              color: Theme.of(context).colorScheme.primary,
              isActive: currentFilter == TaskFilter.incomplete,
              onTap: () {
                ref
                    .read(taskListProvider.notifier)
                    .setFilter(TaskFilter.incomplete);
              },
            ),
            Container(
              width: 1,
              height: 20,
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
            _buildCompactStatItem(
              label: '已完成',
              value: stats['completed'].toString(),
              color: Colors.green,
              isActive: currentFilter == TaskFilter.completed,
              onTap: () {
                ref
                    .read(taskListProvider.notifier)
                    .setFilter(TaskFilter.completed);
              },
            ),
            Container(
              width: 1,
              height: 20,
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            ),
            _buildCompactStatItem(
              label: '逾期',
              value: stats['overdue'].toString(),
              color: Colors.red,
              isActive: currentFilter == TaskFilter.overdue,
              onTap: () {
                ref
                    .read(taskListProvider.notifier)
                    .setFilter(TaskFilter.overdue);
              },
            ),
          ],
        ),
        loading: () => const Center(
          child: SizedBox(
            height: 40,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  /// 构建紧凑型统计项
  Widget _buildCompactStatItem({
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
    bool isActive = false,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建统计信息卡片（窄屏用）
  Widget _buildStatisticsCard() {
    final statisticsAsync = ref.watch(taskStatisticsProvider);
    final currentFilter = ref.watch(
      taskListProvider.select((state) => state.filter),
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: statisticsAsync.when(
        data: (stats) => Column(
          children: [
            Row(
              children: [
                const Text(
                  '任务概览',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => _openPagedTaskDialog(),
                  icon: const Icon(Icons.table_rows, size: 16),
                  label: const Text('分页任务'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.6)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.task,
                  label: '总任务',
                  value: stats['total'].toString(),
                ),
                _buildStatItem(
                  icon: Icons.pending_actions,
                  label: '未完成',
                  value: stats['incomplete'].toString(),
                  isActive: currentFilter == TaskFilter.incomplete,
                  onTap: () {
                    ref
                        .read(taskListProvider.notifier)
                        .setFilter(TaskFilter.incomplete);
                  },
                ),
                _buildStatItem(
                  icon: Icons.check_circle,
                  label: '已完成',
                  value: stats['completed'].toString(),
                  isActive: currentFilter == TaskFilter.completed,
                  onTap: () {
                    ref
                        .read(taskListProvider.notifier)
                        .setFilter(TaskFilter.completed);
                  },
                ),
                _buildStatItem(
                  icon: Icons.event_busy,
                  label: '逾期',
                  value: stats['overdue'].toString(),
                  isActive: currentFilter == TaskFilter.overdue,
                  onTap: () {
                    ref
                        .read(taskListProvider.notifier)
                        .setFilter(TaskFilter.overdue);
                  },
                ),
              ],
            ),
          ],
        ),
        loading: () => const Center(
          child: SizedBox(
            height: 60,
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        ),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  /// 构建单个统计项
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
    bool isActive = false,
  }) {
    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );

    if (onTap == null) return child;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: child,
      ),
    );
  }

  /// 显示任务表单对话框
  void _showTaskFormDialog(BuildContext context, {int? taskId}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          padding: const EdgeInsets.all(24),
          child: TaskForm(
            taskId: taskId,
            onSaved: () {
              Navigator.pop(context);
            },
            onCancelled: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  /// 显示搜索对话框
  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('搜索任务'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入关键词',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onSubmitted: (keyword) {
            ref.read(taskListProvider.notifier).setSearchKeyword(keyword);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(taskListProvider.notifier).clearSearch();
              Navigator.pop(context);
            },
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }

  /// 清除已完成任务
  Future<void> _clearCompletedTasks() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('确定要清除所有已完成的任务吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(taskListProvider.notifier).clearCompletedTasks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已清除所有已完成任务'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// 显示修改工号对话框
  Future<void> _showChangeEmpNoDialog() async {
    final currentEmpNo = _configService.empNo;

    // 先断开MQTT连接并销毁客户端（因为clientId包含工号）
    await _mqttService.disconnect(destroyClient: true);
    print('📡 [MQTT] 已断开连接并销毁客户端，准备修改工号');

    // 显示工号输入弹窗（允许取消）
    final newEmpNo = await EmpNoDialog.show(context, canDismiss: true);

    if (newEmpNo != null && newEmpNo.isNotEmpty) {
      // 用户输入了新工号
      if (newEmpNo != currentEmpNo) {
        print('✓ 工号已从 $currentEmpNo 修改为 $newEmpNo');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('工号已修改为: $newEmpNo'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('ℹ️ 工号未变化: $newEmpNo');
      }
    } else {
      // 用户取消了，使用原来的工号重新连接
      if (currentEmpNo != null && currentEmpNo.isNotEmpty) {
        print('ℹ️ 用户取消修改，使用原工号重新连接: $currentEmpNo');
        await _mqttService.connect(
          broker: AppConstants.mqttBrokerHost,
          port: AppConstants.mqttBrokerPort,
          empNo: currentEmpNo,
          username: AppConstants.mqttUsername,
          password: AppConstants.mqttPassword,
        );
      }
    }
  }
}
