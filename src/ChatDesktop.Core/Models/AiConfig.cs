namespace ChatDesktop.Core.Models;

/// <summary>
/// AI 配置
/// </summary>
public sealed class AiConfig
{
    public string ApiUrl { get; set; } = string.Empty;
    public string? SseUrl { get; set; }
    public string ApiKey { get; set; } = string.Empty;

    public string EffectiveSseUrl => string.IsNullOrWhiteSpace(SseUrl) ? ApiUrl : SseUrl!;
}
