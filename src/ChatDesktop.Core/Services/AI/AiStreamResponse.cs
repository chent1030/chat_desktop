namespace ChatDesktop.Core.Services.AI;

/// <summary>
/// AI 流式响应
/// </summary>
public sealed class AiStreamResponse
{
    public string? Content { get; set; }
    public string? ConversationId { get; set; }
    public bool IsDone { get; set; }
}
