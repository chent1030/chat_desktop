import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';

import '../../models/task.dart';
import '../../services/config_service.dart';
import '../../services/task_api_service.dart';
import '../../utils/env_config.dart';
import '../common/app_markdown.dart';

enum UnifyTaskListDialogType {
  myTasks,
  dispatchedByMe,
}

class UnifyTaskListDialog {
  static Future<void> show(
    BuildContext context, {
    required UnifyTaskListDialogType type,
  }) {
    return () async {
      // 允许运行时修改 `.env` 后立即生效（尤其是 DEBUG）
      await EnvConfig.reload();
      if (!context.mounted) return;
      await showDialog(
        context: context,
        builder: (_) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 720),
            child: _UnifyTaskListDialogBody(type: type),
          ),
        ),
      );
    }();
  }
}

class _UnifyTaskListDialogBody extends StatefulWidget {
  final UnifyTaskListDialogType type;

  const _UnifyTaskListDialogBody({required this.type});

  @override
  State<_UnifyTaskListDialogBody> createState() =>
      _UnifyTaskListDialogBodyState();
}

class _UnifyTaskListDialogBodyState extends State<_UnifyTaskListDialogBody> {
  final _taskApi = TaskApiService.instance;
  final _config = ConfigService.instance;

  final _keywordController = TextEditingController();
  late UnifyTaskListDialogType _type;

  bool _isLoading = false;
  String? _error;
  List<Task> _tasks = const [];

  int _page = 0; // 0-based
  int _size = 10;
  int _totalPages = 0;
  int _totalElements = 0;

  DateTime? _dueStart;
  DateTime? _dueEnd;

  @override
  void initState() {
    super.initState();
    _type = widget.type;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  String get _title =>
      _type == UnifyTaskListDialogType.myTasks ? '我的任务（分页）' : '我派发的任务（分页）';

  String? get _empNo {
    final empNo = _config.empNo?.trim();
    if (empNo == null || empNo.isEmpty) return null;
    return empNo;
  }

  Future<void> _load() async {
    final empNo = _empNo;
    if (empNo == null) {
      setState(() {
        _error = '未设置工号，无法加载任务列表';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final page = await _taskApi.fetchTaskPage(
        page: _page,
        size: _size,
        empNo: _type == UnifyTaskListDialogType.myTasks ? empNo : null,
        assignedBy:
            _type == UnifyTaskListDialogType.dispatchedByMe ? empNo : null,
        title: _keywordController.text.trim(),
        dueDateStart: _dueStart,
        dueDateEnd: _dueEnd,
      );

      setState(() {
        _tasks = page.content;
        _totalPages = page.totalPages;
        _totalElements = page.totalElements;
      });
    } catch (e) {
      setState(() {
        _error = '加载失败: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickDueRange() async {
    DateTime? start = _dueStart;
    DateTime? end = _dueEnd;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String label(DateTime? v) =>
                v == null ? '不限' : DateFormat('yyyy-MM-dd HH:mm').format(v);

            Future<DateTime?> pickDateTime({
              required DateTime? initial,
              required String dateHelpText,
              required String timeHelpText,
            }) async {
              final now = DateTime.now();
              final date = await showDatePicker(
                context: dialogContext,
                initialDate: initial ?? now,
                firstDate: now.subtract(const Duration(days: 3650)),
                lastDate: now.add(const Duration(days: 3650)),
                helpText: dateHelpText,
                cancelText: '取消',
                confirmText: '确定',
              );
              if (date == null || !dialogContext.mounted) return null;

              final time = await showTimePicker(
                context: dialogContext,
                initialTime: initial != null
                    ? TimeOfDay.fromDateTime(initial)
                    : TimeOfDay.now(),
                helpText: timeHelpText,
                cancelText: '取消',
                confirmText: '确定',
              );
              if (time == null || !dialogContext.mounted) return null;
              return DateTime(
                date.year,
                date.month,
                date.day,
                time.hour,
                time.minute,
              );
            }

            return AlertDialog(
              title: const Text('到期时间区间'),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 80, child: Text('开始')),
                        Expanded(child: Text(label(start))),
                        TextButton(
                          onPressed: () async {
                            final picked = await pickDateTime(
                              initial: start,
                              dateHelpText: '选择开始日期',
                              timeHelpText: '选择开始时间',
                            );
                            if (picked == null) return;
                            setDialogState(() => start = picked);
                          },
                          child: const Text('选择'),
                        ),
                        TextButton(
                          onPressed: () => setDialogState(() => start = null),
                          child: const Text('清除'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(width: 80, child: Text('结束')),
                        Expanded(child: Text(label(end))),
                        TextButton(
                          onPressed: () async {
                            final picked = await pickDateTime(
                              initial: end,
                              dateHelpText: '选择结束日期',
                              timeHelpText: '选择结束时间',
                            );
                            if (picked == null) return;
                            setDialogState(() => end = picked);
                          },
                          child: const Text('选择'),
                        ),
                        TextButton(
                          onPressed: () => setDialogState(() => end = null),
                          child: const Text('清除'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted) return;
    setState(() {
      _dueStart = start;
      _dueEnd = end;
      _page = 0;
    });
    await _load();
  }

  Future<void> _markRead(Task task) async {
    final uuid = task.uuid?.trim();
    if (uuid == null || uuid.isEmpty) return;
    try {
      await _taskApi.markTaskRead(taskUuid: uuid);
    } catch (_) {}
  }

  Future<void> _complete(Task task) async {
    final uuid = task.uuid?.trim();
    if (uuid == null || uuid.isEmpty) return;
    await _taskApi.completeTask(taskUuid: uuid);
    await _load();
  }

  Future<void> _openDetail(Task task) async {
    if (_type == UnifyTaskListDialogType.myTasks) {
      await _markRead(task);
    }
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 560),
          child: _UnifyTaskDetail(task: task),
        ),
      ),
    );
    if (mounted) {
      await _load();
    }
  }

  String _pageLabel() {
    if (_totalPages <= 0) return '-';
    return '${_page + 1}/$_totalPages';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        _Header(theme: theme, title: _title, totalElements: _totalElements),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: _Toolbar(
            theme: theme,
            type: _type,
            isLoading: _isLoading,
            keywordController: _keywordController,
            onTypeChanged: (next) async {
              setState(() {
                _type = next;
                _page = 0;
              });
              await _load();
            },
            onSearch: () async {
              setState(() => _page = 0);
              await _load();
            },
            onPickDueRange: _pickDueRange,
            debugMode: EnvConfig.debug,
          ),
        ),

        Expanded(
          child: Stack(
            children: [
              if (_error != null)
                Center(
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: _TableCard(
                    theme: theme,
                    type: _type,
                    tasks: _tasks,
                    isLoading: _isLoading,
                    onOpen: _openDetail,
                    onMarkRead: (task) async {
                      await _markRead(task);
                      await _load();
                    },
                    onComplete: _complete,
                  ),
                ),
              if (_isLoading)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      color: theme.colorScheme.surface.withOpacity(0.35),
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.only(top: 8),
                      child: const SizedBox(
                        width: 240,
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: _Footer(
            theme: theme,
            isLoading: _isLoading,
            pageLabel: _pageLabel(),
            canPrev: _page > 0,
            canNext: _totalPages > 0 && _page + 1 < _totalPages,
            size: _size,
            onPrev: () {
              setState(() => _page -= 1);
              _load();
            },
            onNext: () {
              setState(() => _page += 1);
              _load();
            },
            onSizeChanged: (value) {
              setState(() {
                _size = value;
                _page = 0;
              });
              _load();
            },
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final int totalElements;

  const _Header({
    required this.theme,
    required this.title,
    required this.totalElements,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.12),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  '共 $totalElements 条',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final ThemeData theme;
  final UnifyTaskListDialogType type;
  final bool isLoading;
  final TextEditingController keywordController;
  final Future<void> Function(UnifyTaskListDialogType next) onTypeChanged;
  final Future<void> Function() onSearch;
  final Future<void> Function() onPickDueRange;
  final bool debugMode;

  const _Toolbar({
    required this.theme,
    required this.type,
    required this.isLoading,
    required this.keywordController,
    required this.onTypeChanged,
    required this.onSearch,
    required this.onPickDueRange,
    required this.debugMode,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final searchWidth =
                constraints.maxWidth < 360 ? constraints.maxWidth : 320.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SegmentedButton<UnifyTaskListDialogType>(
                          segments: const [
                            ButtonSegment(
                              value: UnifyTaskListDialogType.myTasks,
                              label: Text('我的任务'),
                            ),
                            ButtonSegment(
                              value: UnifyTaskListDialogType.dispatchedByMe,
                              label: Text('我派发的'),
                            ),
                          ],
                          selected: {type},
                          onSelectionChanged: isLoading
                              ? null
                              : (values) async {
                                  await onTypeChanged(values.first);
                                },
                        ),
                      ),
                    ),
                    if (debugMode) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiaryContainer
                              .withOpacity(0.6),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: theme.colorScheme.tertiary.withOpacity(0.25),
                          ),
                        ),
                        child: Text(
                          'MOCK',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: searchWidth,
                      child: TextField(
                        controller: keywordController,
                        decoration: const InputDecoration(
                          hintText: '任务名称',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => onSearch(),
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: isLoading ? null : onSearch,
                      icon: const Icon(Icons.manage_search),
                      label: const Text('查询'),
                    ),
                    OutlinedButton.icon(
                      onPressed: isLoading ? null : onPickDueRange,
                      icon: const Icon(Icons.date_range),
                      label: const Text('到期区间'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  final ThemeData theme;
  final UnifyTaskListDialogType type;
  final List<Task> tasks;
  final bool isLoading;
  final Future<void> Function(Task task) onOpen;
  final Future<void> Function(Task task) onMarkRead;
  final Future<void> Function(Task task) onComplete;

  const _TableCard({
    required this.theme,
    required this.type,
    required this.tasks,
    required this.isLoading,
    required this.onOpen,
    required this.onMarkRead,
    required this.onComplete,
  });

  Widget _statusChip({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerStyle = theme.textTheme.labelLarge;
    final isDispatchedByMe = type == UnifyTaskListDialogType.dispatchedByMe;

    final compactFilled = FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      minimumSize: const Size(0, 32),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      textStyle: theme.textTheme.labelMedium,
    );
    final compactTonal = FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      minimumSize: const Size(0, 32),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      textStyle: theme.textTheme.labelMedium,
    );
    final compactOutlined = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      minimumSize: const Size(0, 32),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      textStyle: theme.textTheme.labelMedium,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.12)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 860),
              child: SingleChildScrollView(
                child: DataTable(
                showCheckboxColumn: false,
                headingRowHeight: 44,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 76,
                headingTextStyle: headerStyle,
                columns: const [
                  DataColumn(label: Text('状态')),
                  DataColumn(label: Text('标题')),
                  DataColumn(label: Text('截止时间')),
                  DataColumn(label: Text('派发给')),
                  DataColumn(label: Text('派发人')),
                  DataColumn(label: Text('操作')),
                ],
                rows: tasks.map((task) {
                  final due = task.dueDate != null
                      ? DateFormat('yyyy-MM-dd HH:mm').format(task.dueDate!)
                      : '-';
                  final statusWidgets = <Widget>[
                    _statusChip(
                      text: task.isRead ? '已读' : '未读',
                      color: task.isRead
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    _statusChip(
                      text: task.isCompleted ? '已完成' : '未完成',
                      color: task.isCompleted
                          ? theme.colorScheme.outline
                          : theme.colorScheme.tertiary,
                    ),
                  ];

                  return DataRow(
                    onSelectChanged: isLoading
                        ? null
                        : (_) {
                            onOpen(task);
                          },
                    cells: [
                      DataCell(
                        Wrap(
                          spacing: 0,
                          runSpacing: 6,
                          children: statusWidgets,
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 320,
                          child: Text(
                            task.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text(due)),
                      DataCell(Text((task.assignedTo ?? '').trim().isEmpty
                          ? '-'
                          : task.assignedTo!.trim())),
                      DataCell(Text((task.assignedBy ?? '').trim().isEmpty
                          ? '-'
                          : task.assignedBy!.trim())),
                      DataCell(
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.tonal(
                              onPressed: isLoading ? null : () => onOpen(task),
                              style: compactTonal,
                              child: const Text('查看'),
                            ),
                            if (!isDispatchedByMe)
                              OutlinedButton(
                                onPressed: isLoading || task.isRead
                                    ? null
                                    : () => onMarkRead(task),
                                style: compactOutlined,
                                child: const Text('设为已读'),
                              ),
                            if (!isDispatchedByMe)
                              FilledButton(
                                onPressed: isLoading || task.isCompleted
                                    ? null
                                    : () => onComplete(task),
                                style: compactFilled,
                                child: const Text('完成'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(growable: false),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final ThemeData theme;
  final bool isLoading;
  final String pageLabel;
  final bool canPrev;
  final bool canNext;
  final int size;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<int> onSizeChanged;

  const _Footer({
    required this.theme,
    required this.isLoading,
    required this.pageLabel,
    required this.canPrev,
    required this.canNext,
    required this.size,
    required this.onPrev,
    required this.onNext,
    required this.onSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 520;

        final pageText = Text(
          '页码 $pageLabel',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        );

        final actions = Wrap(
          spacing: 4,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: '上一页',
              onPressed: (!canPrev || isLoading) ? null : onPrev,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: '下一页',
              onPressed: (!canNext || isLoading) ? null : onNext,
            ),
            DropdownButton<int>(
              value: size,
              items: const [
                DropdownMenuItem(value: 10, child: Text('10/页')),
                DropdownMenuItem(value: 20, child: Text('20/页')),
                DropdownMenuItem(value: 50, child: Text('50/页')),
              ],
              onChanged: isLoading
                  ? null
                  : (value) {
                      if (value == null) return;
                      onSizeChanged(value);
                    },
            ),
          ],
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              pageText,
              const SizedBox(height: 6),
              Align(alignment: Alignment.centerRight, child: actions),
            ],
          );
        }

        return Row(
          children: [
            pageText,
            const Spacer(),
            actions,
          ],
        );
      },
    );
  }
}

class _UnifyTaskDetail extends StatelessWidget {
  final Task task;
  const _UnifyTaskDetail({required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.12),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: theme.textTheme.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Markdown(
              data: task.description ?? '',
              selectable: true,
              softLineBreak: true,
              onTapLink: (text, href, title) async {
                if (href == null) return;
                await AppMarkdown.launchLink(href);
              },
              styleSheet: AppMarkdown.styleSheet(theme),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              if (task.dueDate != null)
                Text('截止：${DateFormat('yyyy-MM-dd HH:mm').format(task.dueDate!)}'),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
