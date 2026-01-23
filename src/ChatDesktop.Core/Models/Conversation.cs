namespace ChatDesktop.Core.Models;

/// <summary>
/// 会话实体
/// </summary>
public sealed class Conversation
{
    public int Id { get; set; }
    public string AgentId { get; set; } = string.Empty;
    public string Title { get; set; } = "新对话";
    public bool IsActive { get; set; } = true;
    public int MessageCount { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.Now;
    public DateTime UpdatedAt { get; set; } = DateTime.Now;
    public string? LastMessageContent { get; set; }
    public bool IsPinned { get; set; }
    public int? TotalTokens { get; set; }
    public string? Metadata { get; set; }

    public void Touch()
    {
        UpdatedAt = DateTime.Now;
    }

    public void IncrementMessageCount()
    {
        MessageCount++;
        Touch();
    }

    public void UpdateLastMessage(string content)
    {
        LastMessageContent = content.Length > 100 ? string.Concat(content.AsSpan(0, 100), "...") : content;
        Touch();
    }

    public void TogglePin()
    {
        IsPinned = !IsPinned;
        Touch();
    }
}
