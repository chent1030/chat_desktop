using ChatDesktop.Core.Enums;

namespace ChatDesktop.Core.Models;

/// <summary>
/// 任务实体
/// </summary>
public sealed class TaskItem
{
    public int Id { get; set; }
    public string TaskUid { get; set; } = Guid.NewGuid().ToString();

    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public Priority Priority { get; set; } = Priority.Medium;
    public bool IsCompleted { get; set; }
    public bool IsRead { get; set; }
    public DateTime? DueDate { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.Now;
    public DateTime UpdatedAt { get; set; } = DateTime.Now;

    public TaskSource Source { get; set; } = TaskSource.Manual;
    public string? CreatedByAgentId { get; set; }
    public DateTime? CompletedAt { get; set; }
    public string? Tags { get; set; }
    public bool IsSynced { get; set; }
    public DateTime? LastSyncedAt { get; set; }

    public string? AssignedTo { get; set; }
    public string? AssignedToType { get; set; }
    public string? AssignedBy { get; set; }
    public DateTime? AssignedAt { get; set; }
    public bool AllowDispatch { get; set; }

    public bool IsOverdue => DueDate.HasValue && !IsCompleted && DateTime.Now > DueDate.Value;

    public bool IsDueSoon
    {
        get
        {
            if (!DueDate.HasValue || IsCompleted)
            {
                return false;
            }

            var diff = DueDate.Value - DateTime.Now;
            return diff.TotalHours > 0 && diff.TotalHours <= 24;
        }
    }

    public void MarkAsCompleted()
    {
        IsCompleted = true;
        CompletedAt = DateTime.Now;
        Touch();
    }

    public void MarkAsIncomplete()
    {
        IsCompleted = false;
        CompletedAt = null;
        Touch();
    }

    public void MarkAsRead()
    {
        IsRead = true;
        Touch();
    }

    public void MarkAsUnread()
    {
        IsRead = false;
        Touch();
    }

    public void Touch()
    {
        UpdatedAt = DateTime.Now;
    }
}
