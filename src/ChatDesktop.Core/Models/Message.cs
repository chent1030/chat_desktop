using ChatDesktop.Core.Enums;

namespace ChatDesktop.Core.Models;

/// <summary>
/// 消息实体
/// </summary>
public sealed class Message
{
    public int Id { get; set; }
    public int ConversationId { get; set; }
    public string AgentId { get; set; } = string.Empty;
    public MessageRole Role { get; set; } = MessageRole.User;
    public string Content { get; set; } = string.Empty;
    public MessageStatus Status { get; set; } = MessageStatus.Sending;
    public DateTime CreatedAt { get; set; } = DateTime.Now;
    public DateTime UpdatedAt { get; set; } = DateTime.Now;
    public string? Error { get; set; }
    public int? TokenCount { get; set; }
    public string? Metadata { get; set; }

    public void Touch()
    {
        UpdatedAt = DateTime.Now;
    }

    public void MarkAsSent()
    {
        Status = MessageStatus.Sent;
        Touch();
    }

    public void MarkAsFailed(string errorMessage)
    {
        Status = MessageStatus.Failed;
        Error = errorMessage;
        Touch();
    }

    public void MarkAsStreaming()
    {
        Status = MessageStatus.Streaming;
        Touch();
    }

    public void AppendContent(string chunk)
    {
        Content += chunk;
        Touch();
    }
}
