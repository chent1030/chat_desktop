using ChatDesktop.Core.Models;
using ChatDesktop.Core.Dto;
using ChatDesktop.Core.Queries;

namespace ChatDesktop.Core.Interfaces;

/// <summary>
/// 任务远端 API
/// </summary>
public interface ITaskRemoteService
{
    Task CreateTaskAsync(TaskItem task, string currentEmpNo, CancellationToken cancellationToken = default);
    Task MarkReadAsync(string taskUuid, CancellationToken cancellationToken = default);
    Task CompleteAsync(string taskUuid, CancellationToken cancellationToken = default);
    Task<TaskPageResult> FetchTaskPageAsync(TaskPageQuery query, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<DispatchCandidate>> FetchDispatchCandidatesAsync(CancellationToken cancellationToken = default);
    Task<bool> VerifyEmpNoAsync(string empNo, CancellationToken cancellationToken = default);
}
