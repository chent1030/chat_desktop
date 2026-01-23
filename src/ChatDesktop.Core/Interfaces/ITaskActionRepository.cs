using ChatDesktop.Core.Models;

namespace ChatDesktop.Core.Interfaces;

/// <summary>
/// 任务操作记录仓储
/// </summary>
public interface ITaskActionRepository
{
    Task<int> CreateAsync(TaskAction action, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<TaskAction>> GetByTaskIdAsync(int taskId, CancellationToken cancellationToken = default);
}
