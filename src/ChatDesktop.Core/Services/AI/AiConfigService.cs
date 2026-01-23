using ChatDesktop.Core.Models;
using ChatDesktop.Infrastructure.Config;

namespace ChatDesktop.Core.Services.AI;

/// <summary>
/// AI 配置服务
/// </summary>
public sealed class AiConfigService
{
    public AiConfig GetChatConfig(string assistantKey)
    {
        var apiUrl = EnvConfig.AiApiUrl;
        var sseUrl = EnvConfig.AiSseUrl;
        var apiKey = assistantKey switch
        {
            "xin_service" => EnvConfig.AiApiKeyXinService,
            "local_qa" => EnvConfig.AiApiKeyLocalQa,
            _ => EnvConfig.AiApiKey,
        };

        return BuildConfig(apiUrl, sseUrl, apiKey);
    }

    public AiConfig GetTaskExtractConfig()
    {
        var apiUrl = EnvConfig.AiTaskExtractApiUrl;
        var sseUrl = EnvConfig.AiTaskExtractSseUrl;
        var apiKey = EnvConfig.AiTaskExtractApiKey;

        return BuildConfig(apiUrl, sseUrl, apiKey);
    }

    private static AiConfig BuildConfig(string apiUrl, string? sseUrl, string apiKey)
    {
        if (string.IsNullOrWhiteSpace(apiUrl))
        {
            throw new InvalidOperationException("未配置 AI_API_URL");
        }

        if (string.IsNullOrWhiteSpace(apiKey))
        {
            throw new InvalidOperationException("未配置 AI_API_KEY");
        }

        return new AiConfig
        {
            ApiUrl = apiUrl,
            SseUrl = sseUrl,
            ApiKey = apiKey,
        };
    }
}
