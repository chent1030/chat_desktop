import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/task_provider.dart';
import '../providers/window_provider.dart';
import '../widgets/tasks/task_list.dart';
import '../widgets/tasks/task_form.dart';
import '../widgets/chat/chat_view.dart';

/// HomeScreen - 应用主界面
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0; // 0: 任务列表, 1: AI助手

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskListState = ref.watch(taskListProvider);
    final windowState = ref.watch(windowStateProvider);

    // 小窗口模式：显示简化界面
    if (windowState.mode == WindowMode.mini) {
      return _buildMiniWindow(theme);
    }

    // 检查屏幕宽度,决定是使用双栏布局还是标签页布局
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: _buildAppBar(theme, taskListState, isWideScreen),
      body: isWideScreen ? _buildWideScreenLayout() : _buildNarrowScreenLayout(),
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

  /// 小窗口模式界面
  Widget _buildMiniWindow(ThemeData theme) {
    final unreadCount = ref.watch(unreadBadgeCountProvider);

    return GestureDetector(
      onTap: () {
        // 点击小窗口恢复到正常窗口
        ref.read(windowStateProvider.notifier).switchToNormalMode();
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
                size: 32,
              ),
              if (unreadCount > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
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
              // 新建任务按钮
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
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
        // 缩小到小窗口按钮
        IconButton(
          icon: const Icon(Icons.picture_in_picture_alt, size: 20),
          onPressed: () {
            ref.read(windowStateProvider.notifier).switchToMiniMode();
          },
          tooltip: '小窗口模式',
        ),

        // 更多菜单（合并搜索和清除功能）
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 20),
          onSelected: (value) async {
            if (value == 'search') {
              _showSearchDialog(context);
            } else if (value == 'clear_completed') {
              await _clearCompletedTasks();
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
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// 构建紧凑型统计信息（侧边栏用）
  Widget _buildCompactStatistics() {
    final statisticsAsync = ref.watch(taskStatisticsProvider);

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
  }) {
    return Column(
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
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  /// 构建统计信息卡片（窄屏用）
  Widget _buildStatisticsCard() {
    final statisticsAsync = ref.watch(taskStatisticsProvider);

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
        data: (stats) => Row(
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
            ),
            _buildStatItem(
              icon: Icons.check_circle,
              label: '已完成',
              value: stats['completed'].toString(),
            ),
            _buildStatItem(
              icon: Icons.event_busy,
              label: '逾期',
              value: stats['overdue'].toString(),
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
  }) {
    return Column(
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
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
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
}
