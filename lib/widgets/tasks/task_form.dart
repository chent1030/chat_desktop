import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../../models/dispatch_candidate.dart';
import '../../providers/task_provider.dart';
import '../../utils/validators.dart';
import '../common/voice_input_button.dart';
import '../../services/speech_to_text_service.dart';
import '../../services/dispatch_candidate_api_service.dart';
import '../../services/task_voice_extraction_service.dart';
import '../../providers/agent_provider.dart';
import '../../services/ai_service.dart';
import '../../services/log_service.dart';

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
  bool _isVoiceCreating = false;
  bool _isLoadingCandidates = false;
  String? _voiceTranscript;
  List<DispatchCandidate> _dispatchCandidates = const [];

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

  Future<void> _ensureDispatchCandidatesLoaded() async {
    if (_isLoadingCandidates || _dispatchCandidates.isNotEmpty) return;
    setState(() {
      _isLoadingCandidates = true;
    });
    try {
      final list = await DispatchCandidateApiService.instance.fetchCandidates();
      if (!mounted) return;
      setState(() {
        _dispatchCandidates = list;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('获取派发候选失败: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCandidates = false;
        });
      }
    }
  }

  Future<void> _startVoiceCreate() async {
    if (_isVoiceCreating) return;

    setState(() {
      _isVoiceCreating = true;
    });

    var isProcessing = false;
    var processingHint = '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> applyFromAudio(String audioPath) async {
              setDialogState(() {
                isProcessing = true;
                processingHint = '正在进行语音转文字...';
              });
              try {
                final transcript = await SpeechToTextService.instance
                    .uploadAndTranscribe(audioPath,
                        'https://ipaas.catl.com/gateway/outside/ipaas/LY_BASIC/outer_LY_BASIC_voiceToText');
                _voiceTranscript = transcript;

                // 需要派发匹配时会用到候选列表（失败则仍可继续，只是无法自动匹配）
                await _ensureDispatchCandidatesLoaded();

                final extractor = TaskVoiceExtractionService();
                VoiceTaskDraft draft;
                String? modelAnswer;
                try {
                  setDialogState(() {
                    processingHint = '正在调用大模型解析关键信息...';
                  });
                  final now = DateTime.now();
                  final teams = _dispatchCandidates
                      .map((e) => e.workGroup)
                      .whereType<String>()
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toSet()
                      .toList()
                    ..sort();
                  final teamGroup = teams.isEmpty ? '[]' : jsonEncode(teams);

                  // 用户列表：用于大模型把“给张三创建待办”解析为具体工号（empNo）
                  final users = <Map<String, String>>[];
                  final seenEmpNo = <String>{};
                  for (final c in _dispatchCandidates) {
                    final empNo = c.empNo.trim();
                    final empName = c.empName.trim();
                    if (empNo.isEmpty || empName.isEmpty) continue;
                    if (!seenEmpNo.add(empNo)) continue;
                    users.add({'empName': empName, 'empNo': empNo});
                  }
                  users.sort((a, b) {
                    final nameA = a['empName'] ?? '';
                    final nameB = b['empName'] ?? '';
                    final byName = nameA.compareTo(nameB);
                    if (byName != 0) return byName;
                    return (a['empNo'] ?? '').compareTo(b['empNo'] ?? '');
                  });
                  final userListJson = users.isEmpty ? '[]' : jsonEncode(users);
                  final systemTime =
                      '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
                      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

                  // 语音创建任务抽取使用独立的 APIKEY（避免与聊天等场景混用额度/权限）
                  final agentConfig = ref.read(taskExtractAgentConfigProvider);
                  await LogService.instance.info(
                    '语音创建：开始调用大模型工作流抽取',
                    tag: 'VOICE_TASK',
                  );
                  final buffer = StringBuffer();
                  await for (final chunk in AIService.instance.sendWorkflowStream(
                    apiUrl: agentConfig.apiUrl,
                    apiKey: agentConfig.apiKey,
                    query: '开始转换',
                    conversationId: '',
                    inputs: {
                      'system_time': systemTime,
                      'team_group': teamGroup,
                      'user_list': userListJson,
                      'voice_content': transcript.trim(),
                    },
                  )) {
                    buffer.write(chunk);
                  }
                  modelAnswer = buffer.toString();
                  await LogService.instance.debug(
                    '语音创建：大模型返回内容长度=${modelAnswer.length}',
                    tag: 'VOICE_TASK',
                  );

                  draft = extractor.extractFromModelAnswer(
                    modelAnswer: modelAnswer,
                    transcript: transcript,
                    now: now,
                    candidates: _dispatchCandidates,
                  );
                } catch (e) {
                  setDialogState(() {
                    processingHint = '大模型解析失败，正在使用本地规则兜底...';
                  });
                  final preview = (modelAnswer == null)
                      ? ''
                      : (modelAnswer.length > 200
                          ? modelAnswer.substring(0, 200)
                          : modelAnswer);
                  await LogService.instance.warning(
                    '语音创建：大模型抽取/解析失败，准备回退本地规则: $e${preview.isEmpty ? "" : "，返回片段=$preview"}',
                    tag: 'VOICE_TASK',
                  );
                  draft = extractor.extractWithRules(
                    transcript: transcript,
                    now: DateTime.now(),
                    candidates: _dispatchCandidates,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('大模型解析失败，已使用本地规则提取: $e'),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }

                _titleController.text = draft.title;
                _descriptionController.text = draft.description;
                if (mounted) {
                  setState(() {});
                }

                ref.read(taskFormProvider.notifier).setTitle(draft.title);
                ref
                    .read(taskFormProvider.notifier)
                    .setDescription(draft.description);
                ref.read(taskFormProvider.notifier).setDueDate(draft.dueDate);

                // 派发信息：即使模型给出 dispatchNow=false，但提供了派发对象，也会在解析层回填
                ref.read(taskFormProvider.notifier).setDispatchNow(draft.dispatchNow);
                if (draft.assignedToType != null || draft.assignedTo != null) {
                  ref
                      .read(taskFormProvider.notifier)
                      .setAssignedToType(draft.assignedToType);
                  ref.read(taskFormProvider.notifier).setAssignedTo(
                        assignedTo: draft.assignedTo,
                        assignedToEmpNo: draft.assignedToEmpNo,
                      );
                }

                if (!mounted) return;
                Navigator.of(context, rootNavigator: true).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('已从语音填充任务信息，可调整后保存'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('语音创建失败: $e'),
                    duration: const Duration(seconds: 3),
                  ),
                );
              } finally {
                if (mounted) {
                  setDialogState(() {
                    isProcessing = false;
                    processingHint = '';
                  });
                }
              }
            }

            return AlertDialog(
              title: const Text('语音创建'),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('点击麦克风开始录音，完成后会自动识别并填充表单。'),
                    const SizedBox(height: 12),
                    VoiceInputButton(
                      size: 56,
                      enabled: !isProcessing,
                      onRecordComplete: applyFromAudio,
                      onRecordCancel: () {},
                    ),
                    if (isProcessing) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              processingHint.isEmpty ? '处理中...' : processingHint,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_voiceTranscript != null &&
                        _voiceTranscript!.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('最近一次识别文本：'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceVariant
                              .withOpacity(0.35),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withOpacity(0.12),
                          ),
                        ),
                        child: Text(
                          _voiceTranscript!,
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isProcessing
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('关闭'),
                ),
              ],
            );
          },
        );
      },
    );

    if (mounted) {
      setState(() {
        _isVoiceCreating = false;
      });
    }
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
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 顶部标题 + 语音创建（仅创建模式）
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.taskId == null ? '创建新任务' : '编辑任务',
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      if (widget.taskId == null)
                        FilledButton.tonalIcon(
                          onPressed: formState.isSaving ? null : _startVoiceCreate,
                          icon: const Icon(Icons.mic),
                          label: const Text('语音创建'),
                        ),
                    ],
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
                                  .uploadAndTranscribe(
                                      audioPath,
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
                            ref
                                .read(taskFormProvider.notifier)
                                .setDescription(value);
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
                                  .uploadAndTranscribe(
                                      audioPath,
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

                  // 创建时立即派发（可选）
                  _buildDispatchSection(theme, formState),
                  const SizedBox(height: 16),

                  // 是否允许派发：创建任务时去除该选择（仅编辑时显示）
                  if (widget.taskId != null) ...[
                    _buildAllowDispatchSwitch(theme, formState),
                    const SizedBox(height: 16),
                  ],

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
                ],
              ),
            ),
          ),

          // 操作按钮（固定在底部，避免内容增多导致溢出）
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
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

  Widget _buildDispatchSection(ThemeData theme, TaskFormState state) {
    if (widget.taskId != null) return const SizedBox.shrink();

    final isEnabled = !state.isSaving;

    List<DropdownMenuItem<String>> userItems() {
      final users = _dispatchCandidates.toList()
        ..sort((a, b) => a.empName.compareTo(b.empName));
      return users
          .map(
            (u) => DropdownMenuItem(
              value: u.empNo,
              child: Text('${u.empName} (${u.empNo})'),
            ),
          )
          .toList(growable: false);
    }

    List<DropdownMenuItem<String>> teamItems() {
      final teams = _dispatchCandidates
          .map((e) => e.workGroup)
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      return teams
          .map(
            (g) => DropdownMenuItem(
              value: g,
              child: Text(g),
            ),
          )
          .toList(growable: false);
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '派发（可选）',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: (state.assignedToType == null || state.assignedToType!.trim().isEmpty)
                  ? null
                  : state.assignedToType,
              items: const [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text('不派发'),
                ),
                DropdownMenuItem<String?>(
                  value: '用户',
                  child: Text('派发给用户'),
                ),
                DropdownMenuItem<String?>(
                  value: '团队',
                  child: Text('派发给团队'),
                ),
              ],
              onChanged: !isEnabled
                  ? null
                  : (value) async {
                      ref.read(taskFormProvider.notifier).setAssignedToType(value);
                      if (value != null) {
                        await _ensureDispatchCandidatesLoaded();
                      }
                    },
              decoration: const InputDecoration(
                labelText: '派发类型',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoadingCandidates) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 12),
            ],
            if (state.assignedToType != null &&
                !_isLoadingCandidates &&
                _dispatchCandidates.isEmpty)
              const Text('未加载到派发候选列表，请配置派发候选列表 API 后重试。'),
            if (state.assignedToType == '用户')
              DropdownButtonFormField<String?>(
                value: state.assignedToEmpNo,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('请选择用户'),
                  ),
                  ...userItems().map((e) => DropdownMenuItem<String?>(
                        value: e.value,
                        child: e.child,
                      )),
                ],
                onChanged: !isEnabled
                    ? null
                    : (empNo) {
                        if (empNo == null) {
                          ref.read(taskFormProvider.notifier).setAssignedTo(
                                assignedTo: null,
                                assignedToEmpNo: null,
                              );
                          return;
                        }
                        final user = _dispatchCandidates
                            .where((e) => e.empNo == empNo)
                            .toList();
                        final empName = user.isNotEmpty ? user.first.empName : null;
                        ref.read(taskFormProvider.notifier).setAssignedTo(
                              assignedTo: empName,
                              assignedToEmpNo: empNo,
                            );
                      },
                decoration: const InputDecoration(
                  labelText: '派发给（用户）',
                  border: OutlineInputBorder(),
                ),
              ),
            if (state.assignedToType == '团队')
              DropdownButtonFormField<String?>(
                value: state.assignedTo,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('请选择团队'),
                  ),
                  ...teamItems().map((e) => DropdownMenuItem<String?>(
                        value: e.value,
                        child: e.child,
                      )),
                ],
                onChanged: !isEnabled
                    ? null
                    : (workGroup) {
                        ref.read(taskFormProvider.notifier).setAssignedTo(
                              assignedTo: workGroup,
                              assignedToEmpNo: null,
                            );
                      },
                decoration: const InputDecoration(
                  labelText: '派发给（团队）',
                  border: OutlineInputBorder(),
                ),
              ),
          ],
        ),
      ),
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
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: initialDate != null
            ? TimeOfDay.fromDateTime(initialDate)
            : TimeOfDay.now(),
        helpText: '选择截止时间',
        cancelText: '取消',
        confirmText: '确定',
      );

      if (selectedTime != null && context.mounted) {
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
