import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../utils/validators.dart';
import '../common/voice_input_button.dart';
import '../../services/speech_to_text_service.dart';

/// TaskForm widget - 用于创建和编辑任务的表单
class TaskForm extends ConsumerStatefulWidget {
  final int? taskId; // null = 创建模式, 非null = 编辑模式
  final VoidCallback? onSaved;
  final VoidCallback? onCancelled;

  const TaskForm({
    super.key,
    this.taskId,
    this.onSaved,
    this.onCancelled,
  });

  @override
  ConsumerState<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends ConsumerState<TaskForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 如果是编辑模式，加载任务数据
    if (widget.taskId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadTask();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// 加载任务数据 (编辑模式)
  Future<void> _loadTask() async {
    await ref.read(taskFormProvider.notifier).loadTask(widget.taskId!);
    final state = ref.read(taskFormProvider);
    _titleController.text = state.title;
    _descriptionController.text = state.description;
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(taskFormProvider);
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            widget.taskId == null ? '创建新任务' : '编辑任务',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),

          // 任务标题输入框（带语音输入）
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '任务标题 *',
                    hintText: '输入任务标题',
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 200,
                  validator: Validators.validateTaskTitle,
                  onChanged: (value) {
                    ref.read(taskFormProvider.notifier).setTitle(value);
                  },
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: VoiceInputButton(
                  size: 40,
                  onRecordComplete: (audioPath) async {
                    try {
                      final text = await SpeechToTextService.instance
                          .uploadAndTranscribe(audioPath,
                              'https://ipaas.catl.com/gateway/outside/ipaas/LY_BASIC/outer_LY_BASIC_voiceToText');
                      _titleController.text = text;
                      ref
                          .read(taskFormProvider.notifier)
                          .setTitle(_titleController.text);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('语音转文字失败: $e'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                      return;
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 任务描述输入框（带语音输入）
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: '任务描述 (可选)',
                    hintText: '输入任务描述',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  maxLength: 1000,
                  validator: Validators.validateTaskDescription,
                  onChanged: (value) {
                    ref.read(taskFormProvider.notifier).setDescription(value);
                  },
                  textInputAction: TextInputAction.newline,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: VoiceInputButton(
                  size: 40,
                  onRecordComplete: (audioPath) async {
                    try {
                      final text = await SpeechToTextService.instance
                          .uploadAndTranscribe(audioPath,
                              'https://ipaas.catl.com/gateway/outside/ipaas/LY_BASIC/outer_LY_BASIC_voiceToText');
                      _descriptionController.text = text;
                      ref
                          .read(taskFormProvider.notifier)
                          .setDescription(_descriptionController.text);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('语音转文字失败: $e'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                      return;
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 优先级选择器 (T029)
          _buildPrioritySelector(theme, formState),
          const SizedBox(height: 16),

          // 截止日期选择器 (T029)
          _buildDueDatePicker(theme, formState),
          const SizedBox(height: 16),

          // 是否允许派发
          _buildAllowDispatchSwitch(theme, formState),
          const SizedBox(height: 16),

          // 标签输入框 (可选)
          TextFormField(
            decoration: const InputDecoration(
              labelText: '标签 (可选)',
              hintText: '例如: 工作, 生活, 学习',
              prefixIcon: Icon(Icons.label),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              ref.read(taskFormProvider.notifier).setTags(value);
            },
          ),
          const SizedBox(height: 24),

          // 错误提示
          if (formState.error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      formState.error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 操作按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // 取消按钮
              TextButton(
                onPressed: formState.isSaving
                    ? null
                    : () {
                        ref.read(taskFormProvider.notifier).reset();
                        widget.onCancelled?.call();
                      },
                child: const Text('取消'),
              ),
              const SizedBox(width: 8),

              // 保存按钮
              FilledButton.icon(
                onPressed: formState.isSaving ? null : _saveTask,
                icon: formState.isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(formState.isSaving ? '保存中...' : '保存'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建优先级选择器 (T029)
  Widget _buildPrioritySelector(ThemeData theme, TaskFormState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '优先级',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: Priority.values.map((priority) {
            final isSelected = state.priority == priority;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Color(priority.colorValue),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(priority.displayName),
                  ],
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(taskFormProvider.notifier).setPriority(priority);
                  }
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 构建截止日期选择器 (T029)
  Widget _buildDueDatePicker(ThemeData theme, TaskFormState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '截止日期',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDueDate(context, state.dueDate),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    state.dueDate != null
                        ? DateFormat('yyyy-MM-dd HH:mm').format(state.dueDate!)
                        : '选择截止日期 (可选)',
                    style: TextStyle(
                      color: state.dueDate != null
                          ? theme.textTheme.bodyLarge?.color
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
                if (state.dueDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      ref.read(taskFormProvider.notifier).setDueDate(null);
                    },
                    tooltip: '清除日期',
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAllowDispatchSwitch(ThemeData theme, TaskFormState state) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.12),
        ),
      ),
      child: SwitchListTile(
        value: state.allowDispatch,
        onChanged: (value) {
          ref.read(taskFormProvider.notifier).setAllowDispatch(value);
        },
        title: const Text('允许派发'),
        subtitle: const Text('开启后，详情页会显示“任务派发”按钮'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
    );
  }

  /// 选择截止日期
  Future<void> _selectDueDate(
      BuildContext context, DateTime? initialDate) async {
    final now = DateTime.now();
    final firstDate = now;
    final lastDate = now.add(const Duration(days: 365));

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: '选择截止日期',
      cancelText: '取消',
      confirmText: '确定',
    );

    if (selectedDate != null && context.mounted) {
      // 选择时间
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: initialDate != null
            ? TimeOfDay.fromDateTime(initialDate)
            : TimeOfDay.now(),
        helpText: '选择截止时间',
        cancelText: '取消',
        confirmText: '确定',
      );

      if (selectedTime != null) {
        final dueDate = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        ref.read(taskFormProvider.notifier).setDueDate(dueDate);
      }
    }
  }

  /// 保存任务
  Future<void> _saveTask() async {
    // 验证表单
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 保存任务
    final success = await ref.read(taskFormProvider.notifier).saveTask();

    if (success && mounted) {
      // 刷新任务列表
      ref.read(taskListProvider.notifier).refresh();

      // 通知父组件
      widget.onSaved?.call();

      // 显示成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.taskId == null ? '任务创建成功' : '任务更新成功',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
