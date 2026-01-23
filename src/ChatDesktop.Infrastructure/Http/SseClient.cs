using System.Net.Http.Headers;
using System.Text;

namespace ChatDesktop.Infrastructure.Http;

/// <summary>
/// SSE 客户端
/// </summary>
public sealed class SseClient
{
    private readonly HttpClient _client = new();

    public async IAsyncEnumerable<string> SubscribeAsync(
        HttpMethod method,
        string url,
        string? jsonBody,
        IDictionary<string, string>? headers,
        [System.Runtime.CompilerServices.EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        using var request = new HttpRequestMessage(method, url);
        if (!string.IsNullOrWhiteSpace(jsonBody))
        {
            request.Content = new StringContent(jsonBody, Encoding.UTF8, "application/json");
        }

        request.Headers.Accept.Clear();
        request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("text/event-stream"));

        if (headers != null)
        {
            foreach (var pair in headers)
            {
                request.Headers.TryAddWithoutValidation(pair.Key, pair.Value);
            }
        }

        using var response = await _client.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            var content = await response.Content.ReadAsStringAsync(cancellationToken);
            throw new HttpException($"SSE 连接失败: {(int)response.StatusCode}", (int)response.StatusCode, content);
        }

        await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
        using var reader = new StreamReader(stream, Encoding.UTF8);

        var dataBuffer = new StringBuilder();
        while (!reader.EndOfStream && !cancellationToken.IsCancellationRequested)
        {
            var line = await reader.ReadLineAsync();
            if (line == null)
            {
                break;
            }

            if (line.StartsWith(":", StringComparison.Ordinal))
            {
                continue;
            }

            if (line.StartsWith("data:", StringComparison.Ordinal))
            {
                var payload = line[5..].TrimStart();
                if (dataBuffer.Length > 0)
                {
                    dataBuffer.Append('\n');
                }
                dataBuffer.Append(payload);
                continue;
            }

            if (line.Length == 0)
            {
                if (dataBuffer.Length > 0)
                {
                    yield return dataBuffer.ToString();
                    dataBuffer.Clear();
                }
            }
        }

        if (dataBuffer.Length > 0)
        {
            yield return dataBuffer.ToString();
        }
    }
}
