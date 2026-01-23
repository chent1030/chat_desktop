using ChatDesktop.Core.Enums;

namespace ChatDesktop.Core.Models;

/// <summary>
/// 任务操作记录
/// </summary>
public sealed class TaskAction
{
    public int Id { get; set; }
    public int TaskId { get; set; }
    public ActionType ActionType { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.Now;
    public string PerformedBy { get; set; } = "user";
    public string? Changes { get; set; }
    public string? Description { get; set; }
    public bool CanUndo { get; set; } = true;
}
