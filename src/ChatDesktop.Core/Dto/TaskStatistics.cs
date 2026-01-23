namespace ChatDesktop.Core.Dto;

/// <summary>
/// 任务统计
/// </summary>
public sealed class TaskStatistics
{
    public int Total { get; set; }
    public int Incomplete { get; set; }
    public int Completed { get; set; }
}
