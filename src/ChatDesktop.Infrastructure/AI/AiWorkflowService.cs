using System.Text.Json;
using ChatDesktop.Core.Models;
using ChatDesktop.Infrastructure.Http;

namespace ChatDesktop.Infrastructure.AI;

/// <summary>
/// AI 工作流服务
/// </summary>
public sealed class AiWorkflowService
{
    private readonly SseClient _sseClient;

    public AiWorkflowService(SseClient sseClient)
    {
        _sseClient = sseClient;
    }

    public async IAsyncEnumerable<string> SendWorkflowStreamAsync(
        AiConfig config,
        string query,
        string userId,
        IDictionary<string, object?> inputs,
        string? conversationId = null,
        [System.Runtime.CompilerServices.EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        var payload = new
        {
            query,
            response_mode = "streaming",
            user = userId,
            conversation_id = conversationId ?? string.Empty,
            inputs
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

            string? output = null;
            var shouldComplete = false;

            try
            {
                using var document = JsonDocument.Parse(data);
                if (document.RootElement.ValueKind != JsonValueKind.Object)
                {
                    continue;
                }

                var root = document.RootElement;
                var eventType = root.TryGetProperty("event", out var ev) ? ev.GetString() : null;

                if (eventType is "message" or "agent_message" or "message_replace")
                {
                    output = root.TryGetProperty("answer", out var answerProp) ? answerProp.GetString() : null;
                }
                else if (eventType == "message_end")
                {
                    shouldComplete = true;
                }
                else if (eventType == "error")
                {
                    var message = root.TryGetProperty("message", out var msgProp) ? msgProp.GetString() : null;
                    throw new InvalidOperationException(message ?? "工作流返回错误");
                }
            }
            catch (JsonException)
            {
                output = data;
            }

            if (!string.IsNullOrWhiteSpace(output))
            {
                yield return output;
            }

            if (shouldComplete)
            {
                yield break;
            }
        }
    }
}
