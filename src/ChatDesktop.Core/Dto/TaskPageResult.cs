using ChatDesktop.Core.Models;

namespace ChatDesktop.Core.Dto;

/// <summary>
/// 任务分页结果
/// </summary>
public sealed class TaskPageResult
{
    public int TotalPages { get; set; }
    public int TotalElements { get; set; }
    public int NumberOfElements { get; set; }
    public int Size { get; set; }
    public int Number { get; set; }
    public IReadOnlyList<TaskItem> Content { get; set; } = Array.Empty<TaskItem>();
}
