using ChatDesktop.Core.Enums;

namespace ChatDesktop.Core.Queries;

/// <summary>
/// 任务查询条件
/// </summary>
public sealed class TaskQuery
{
    public TaskFilter Filter { get; set; } = TaskFilter.Incomplete;
    public TaskSortOrder SortOrder { get; set; } = TaskSortOrder.CreatedAtDesc;
    public string? SearchKeyword { get; set; }
}
