import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/ai_agent.dart';
import '../../providers/agent_provider.dart';

/// 智能体选择器 Widget
/// 显示可用的AI智能体列表，允许用户选择当前使用的智能体
class AgentSelector extends ConsumerWidget {
  const AgentSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentListState = ref.watch(agentListProvider);
    final selectedAgent = agentListState.selectedAgent;

    if (agentListState.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (agentListState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            agentListState.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }

    if (agentListState.agents.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('暂无可用的AI智能体'),
        ),
      );
    }

    return PopupMenuButton<String>(
      tooltip: '选择AI智能体',
      onSelected: (agentId) {
        ref.read(agentListProvider.notifier).selectAgent(agentId);
      },
      itemBuilder: (context) {
        return agentListState.agents.map((agent) {
          return PopupMenuItem<String>(
            value: agent.agentId,
            child: _buildAgentMenuItem(
              context,
              agent,
              isSelected: agent.agentId == selectedAgent?.agentId,
            ),
          );
        }).toList();
      },
      child: _buildAgentSelectorButton(context, selectedAgent),
    );
  }

  /// 构建智能体选择按钮
  Widget _buildAgentSelectorButton(BuildContext context, AIAgent? agent) {
    if (agent == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.smart_toy,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            const Text('选择智能体'),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAgentAvatar(agent, size: 20),
          const SizedBox(width: 8),
          Text(
            agent.name,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_drop_down,
            size: 20,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ],
      ),
    );
  }

  /// 构建智能体菜单项
  Widget _buildAgentMenuItem(
    BuildContext context,
    AIAgent agent, {
    required bool isSelected,
  }) {
    return Row(
      children: [
        _buildAgentAvatar(agent, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                agent.name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (agent.description != null && agent.description!.isNotEmpty)
                Text(
                  agent.description!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        if (isSelected)
          Icon(
            Icons.check,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
      ],
    );
  }

  /// 构建智能体头像
  Widget _buildAgentAvatar(AIAgent agent, {required double size}) {
    // 如果有自定义头像，显示图片
    if (agent.avatar != null && agent.avatar!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          agent.avatar!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar(agent, size);
          },
        ),
      );
    }

    return _buildDefaultAvatar(agent, size);
  }

  /// 构建默认头像（使用图标）
  Widget _buildDefaultAvatar(AIAgent agent, double size) {
    // 根据智能体名称选择不同的颜色和图标
    final IconData icon;
    final Color color;

    if (agent.name.contains('GPT') || agent.name.contains('OpenAI')) {
      icon = Icons.psychology;
      color = const Color(0xFF10A37F); // OpenAI green
    } else if (agent.name.contains('Claude')) {
      icon = Icons.auto_awesome;
      color = const Color(0xFFD97757); // Anthropic orange
    } else {
      icon = Icons.smart_toy;
      color = Colors.blue;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: size * 0.6,
        color: color,
      ),
    );
  }
}

/// 智能体详细列表 Widget (用于设置页面等)
class AgentListView extends ConsumerWidget {
  const AgentListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentListState = ref.watch(agentListProvider);

    if (agentListState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (agentListState.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              agentListState.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(agentListProvider.notifier).loadAgents();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (agentListState.agents.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.smart_toy_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无可用的AI智能体',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '请联系管理员添加智能体',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: agentListState.agents.length,
      itemBuilder: (context, index) {
        final agent = agentListState.agents[index];
        final isSelected =
            agent.agentId == agentListState.selectedAgent?.agentId;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: isSelected ? 4 : 1,
          child: ListTile(
            selected: isSelected,
            leading: _AgentAvatar(agent: agent, size: 40),
            title: Text(
              agent.name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (agent.description != null && agent.description!.isNotEmpty)
                  Text(agent.description!),
                const SizedBox(height: 4),
                Text(
                  '${agent.modelName ?? agent.agentId} • 消息数: ${agent.messageCount}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            trailing: isSelected
                ? Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () {
              ref.read(agentListProvider.notifier).selectAgent(agent.agentId);
            },
          ),
        );
      },
    );
  }
}

/// 智能体头像 Widget (可复用)
class _AgentAvatar extends StatelessWidget {
  final AIAgent agent;
  final double size;

  const _AgentAvatar({
    required this.agent,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    // 如果有自定义头像，显示图片
    if (agent.avatar != null && agent.avatar!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          agent.avatar!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar(context);
          },
        ),
      );
    }

    return _buildDefaultAvatar(context);
  }

  Widget _buildDefaultAvatar(BuildContext context) {
    // 根据智能体名称选择不同的颜色和图标
    final IconData icon;
    final Color color;

    if (agent.name.contains('GPT') || agent.name.contains('OpenAI')) {
      icon = Icons.psychology;
      color = const Color(0xFF10A37F); // OpenAI green
    } else if (agent.name.contains('Claude')) {
      icon = Icons.auto_awesome;
      color = const Color(0xFFD97757); // Anthropic orange
    } else {
      icon = Icons.smart_toy;
      color = Colors.blue;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: color,
      ),
    );
  }
}

