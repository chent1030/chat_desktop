using ChatDesktop.Core.Models;
using ChatDesktop.Core.Queries;

namespace ChatDesktop.Core.Interfaces;

/// <summary>
/// 任务仓储
/// </summary>
public interface ITaskRepository
{
    Task<int> CreateAsync(TaskItem task, CancellationToken cancellationToken = default);
    Task UpdateAsync(TaskItem task, CancellationToken cancellationToken = default);
    Task DeleteAsync(int taskId, CancellationToken cancellationToken = default);

    Task<TaskItem?> GetByIdAsync(int taskId, CancellationToken cancellationToken = default);
    Task<TaskItem?> GetByTaskUidAsync(string taskUid, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<TaskItem>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<IReadOnlyList<TaskItem>> QueryAsync(TaskQuery query, CancellationToken cancellationToken = default);

    Task<int> CountAsync(CancellationToken cancellationToken = default);
    Task<int> CountIncompleteAsync(CancellationToken cancellationToken = default);
    Task<int> CountCompletedAsync(CancellationToken cancellationToken = default);
    Task<int> DeleteCompletedAsync(CancellationToken cancellationToken = default);
}
