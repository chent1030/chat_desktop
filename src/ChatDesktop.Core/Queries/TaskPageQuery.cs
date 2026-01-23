namespace ChatDesktop.Core.Queries;

/// <summary>
/// 任务分页查询参数
/// </summary>
public sealed class TaskPageQuery : PagedQuery
{
    public string? EmpNo { get; set; }
    public string? AssignedBy { get; set; }
    public string? Title { get; set; }
    public DateTime? DueDateStart { get; set; }
    public DateTime? DueDateEnd { get; set; }
}
