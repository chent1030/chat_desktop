using System.Text.Json;
using ChatDesktop.Core.Models;
using ChatDesktop.Infrastructure.Http;

namespace ChatDesktop.Infrastructure.AI;

/// <summary>
/// AI 聊天服务
/// </summary>
public sealed class AiChatService
{
    private readonly SseClient _sseClient;

    public AiChatService(SseClient sseClient)
    {
        _sseClient = sseClient;
    }

    public async Task<string> SendBlockingAsync(
        AiConfig config,
        string query,
        string? conversationId,
        string userId,
        CancellationToken cancellationToken = default)
    {
        var payload = new
        {
            query,
            response_mode = "blocking",
            user = userId,
            conversation_id = conversationId,
            inputs = new { empName = "", empNo = userId, empLevel = "", ansType = "" }
        };

        var json = JsonSerializer.Serialize(payload);
        var client = new ApiClient(config.ApiUrl, () => config.ApiKey);
        return await client.PostAsync("", json, cancellationToken);
    }

    public async IAsyncEnumerable<AiStreamResponse> SendStreamingAsync(
        AiConfig config,
        string query,
        string? conversationId,
        string userId,
        [System.Runtime.CompilerServices.EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        var payload = new
        {
            query,
            response_mode = "streaming",
            user = userId,
            conversation_id = conversationId,
            inputs = new { empName = "", empNo = userId, empLevel = "", ansType = "" }
        };

        var json = JsonSerializer.Serialize(payload);
        var headers = new Dictionary<string, string>
        {
            { "Authorization", $"Bearer {config.ApiKey}" },
            { "Content-Type", "application/json" }
        };

        await foreach (var data in _sseClient.SubscribeAsync(
            HttpMethod.Post,
            config.EffectiveSseUrl,
            json,
            headers,
            cancellationToken))
        {
            if (string.IsNullOrWhiteSpace(data))
            {
                continue;
            }

            AiStreamResponse? parsed = null;
            try
            {
                using var document = JsonDocument.Parse(data);
                if (document.RootElement.ValueKind != JsonValueKind.Object)
                {
                    continue;
                }

                var root = document.RootElement;
                var eventType = root.TryGetProperty("event", out var ev) ? ev.GetString() : null;
                var conversation = root.TryGetProperty("conversation_id", out var cId) ? cId.ToString() : null;

                if (eventType is "message" or "agent_message")
                {
                    var answer = root.TryGetProperty("answer", out var answerProp) ? answerProp.GetString() : null;
                    if (!string.IsNullOrWhiteSpace(answer))
                    {
                        parsed = new AiStreamResponse
                        {
                            Content = answer,
                            ConversationId = conversation,
                            IsDone = false
                        };
                    }
                }
                else if (eventType == "message_replace")
                {
                    var answer = root.TryGetProperty("answer", out var answerProp) ? answerProp.GetString() : null;
                    if (!string.IsNullOrWhiteSpace(answer))
                    {
                        parsed = new AiStreamResponse
                        {
                            Content = answer,
                            ConversationId = conversation,
                            IsDone = false,
                            IsReplace = true
                        };
                    }
                }
                else if (eventType == "message_end")
                {
                    parsed = new AiStreamResponse
                    {
                        ConversationId = conversation,
                        IsDone = true
                    };
                }
                else if (eventType == "error")
                {
                    var message = root.TryGetProperty("message", out var msgProp) ? msgProp.GetString() : null;
                    throw new InvalidOperationException(message ?? "AI 返回错误");
                }
            }
            catch (JsonException)
            {
                parsed = new AiStreamResponse
                {
                    Content = data,
                    IsDone = false
                };
            }

            if (parsed != null)
            {
                yield return parsed;
                if (parsed.IsDone)
                {
                    yield break;
                }
            }
        }
    }
}
