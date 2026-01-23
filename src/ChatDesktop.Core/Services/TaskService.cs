using ChatDesktop.Core.Dto;
using ChatDesktop.Core.Enums;
using ChatDesktop.Core.Interfaces;
using ChatDesktop.Core.Models;
using ChatDesktop.Core.Queries;

namespace ChatDesktop.Core.Services;

/// <summary>
/// 任务服务
/// </summary>
public sealed class TaskService
{
    private readonly ITaskRepository _taskRepository;
    private readonly ITaskActionRepository _actionRepository;
    private readonly ITaskRemoteService? _remoteService;

    public TaskService(ITaskRepository taskRepository, ITaskActionRepository actionRepository, ITaskRemoteService? remoteService = null)
    {
        _taskRepository = taskRepository;
        _actionRepository = actionRepository;
        _remoteService = remoteService;
    }

    public Task<int> CreateAsync(TaskItem task, CancellationToken cancellationToken = default)
    {
        return _taskRepository.CreateAsync(task, cancellationToken);
    }

    public async Task<int> CreateAndSyncAsync(TaskItem task, string currentEmpNo, CancellationToken cancellationToken = default)
    {
        var id = await _taskRepository.CreateAsync(task, cancellationToken);
        if (_remoteService != null)
        {
            try
            {
                await _remoteService.CreateTaskAsync(task, currentEmpNo, cancellationToken);
            }
            catch
            {
            }
        }

        return id;
    }

    public Task UpdateAsync(TaskItem task, CancellationToken cancellationToken = default)
    {
        task.Touch();
        return _taskRepository.UpdateAsync(task, cancellationToken);
    }

    public Task DeleteAsync(int taskId, CancellationToken cancellationToken = default)
    {
        return _taskRepository.DeleteAsync(taskId, cancellationToken);
    }

    public Task<TaskItem?> GetByIdAsync(int taskId, CancellationToken cancellationToken = default)
    {
        return _taskRepository.GetByIdAsync(taskId, cancellationToken);
    }

    public Task<TaskItem?> GetByTaskUidAsync(string taskUid, CancellationToken cancellationToken = default)
    {
        return _taskRepository.GetByTaskUidAsync(taskUid, cancellationToken);
    }

    public Task<IReadOnlyList<TaskItem>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        return _taskRepository.GetAllAsync(cancellationToken);
    }

    public Task<IReadOnlyList<TaskItem>> QueryAsync(TaskQuery query, CancellationToken cancellationToken = default)
    {
        return _taskRepository.QueryAsync(query, cancellationToken);
    }

    public async Task<TaskStatistics> GetStatisticsAsync(CancellationToken cancellationToken = default)
    {
        var total = await _taskRepository.CountAsync(cancellationToken);
        var incomplete = await _taskRepository.CountIncompleteAsync(cancellationToken);
        var completed = await _taskRepository.CountCompletedAsync(cancellationToken);
        return new TaskStatistics
        {
            Total = total,
            Incomplete = incomplete,
            Completed = completed,
        };
    }

    public Task<int> ClearCompletedAsync(CancellationToken cancellationToken = default)
    {
        return _taskRepository.DeleteCompletedAsync(cancellationToken);
    }

    public async Task MarkCompletedAsync(int taskId, CancellationToken cancellationToken = default)
    {
        var task = await _taskRepository.GetByIdAsync(taskId, cancellationToken);
        if (task == null)
        {
            return;
        }

        task.MarkAsCompleted();
        await _taskRepository.UpdateAsync(task, cancellationToken);

        if (_remoteService != null && !string.IsNullOrWhiteSpace(task.TaskUid))
        {
            try
            {
                await _remoteService.CompleteAsync(task.TaskUid, cancellationToken);
            }
            catch
            {
            }
        }
    }

    public async Task MarkIncompleteAsync(int taskId, CancellationToken cancellationToken = default)
    {
        var task = await _taskRepository.GetByIdAsync(taskId, cancellationToken);
        if (task == null)
        {
            return;
        }

        task.MarkAsIncomplete();
        await _taskRepository.UpdateAsync(task, cancellationToken);
    }

    public async Task MarkReadAsync(int taskId, CancellationToken cancellationToken = default)
    {
        var task = await _taskRepository.GetByIdAsync(taskId, cancellationToken);
        if (task == null)
        {
            return;
        }

        task.MarkAsRead();
        await _taskRepository.UpdateAsync(task, cancellationToken);

        if (_remoteService != null && !string.IsNullOrWhiteSpace(task.TaskUid))
        {
            try
            {
                await _remoteService.MarkReadAsync(task.TaskUid, cancellationToken);
            }
            catch
            {
            }
        }
    }

    public async Task MarkUnreadAsync(int taskId, CancellationToken cancellationToken = default)
    {
        var task = await _taskRepository.GetByIdAsync(taskId, cancellationToken);
        if (task == null)
        {
            return;
        }

        task.MarkAsUnread();
        await _taskRepository.UpdateAsync(task, cancellationToken);
    }

    public async Task ToggleCompletionAsync(int taskId, CancellationToken cancellationToken = default)
    {
        var task = await _taskRepository.GetByIdAsync(taskId, cancellationToken);
        if (task == null)
        {
            return;
        }

        if (task.IsCompleted)
        {
            task.MarkAsIncomplete();
        }
        else
        {
            task.MarkAsCompleted();
        }

        await _taskRepository.UpdateAsync(task, cancellationToken);
    }
}
