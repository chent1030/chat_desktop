using System.Net.Http.Headers;
using System.Text.Json;

namespace ChatDesktop.Infrastructure.Voice;

/// <summary>
/// 语音转文字服务
/// </summary>
public sealed class SpeechToTextService
{
    private readonly HttpClient _client = new()
    {
        Timeout = TimeSpan.FromSeconds(30)
    };

    public async Task<string> UploadAndTranscribeAsync(string audioFilePath, string apiUrl, CancellationToken cancellationToken = default)
    {
        if (!File.Exists(audioFilePath))
        {
            throw new FileNotFoundException("音频文件不存在", audioFilePath);
        }

        var token = await FetchTokenAsync(cancellationToken);

        using var content = new MultipartFormDataContent();
        var fileContent = new StreamContent(File.OpenRead(audioFilePath));
        fileContent.Headers.ContentType = new MediaTypeHeaderValue("audio/wav");
        content.Add(fileContent, "file", Path.GetFileName(audioFilePath));

        using var request = new HttpRequestMessage(HttpMethod.Post, apiUrl)
        {
            Content = content
        };
        request.Headers.TryAddWithoutValidation("deipaaskeyauth", "Wc3X579QXQw99925W214iZ38B8w2sr7H");
        request.Headers.TryAddWithoutValidation("deipaasjwt", $"Bearer {token}");

        using var response = await _client.SendAsync(request, cancellationToken);
        var responseText = await response.Content.ReadAsStringAsync(cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException($"语音转写失败: {response.StatusCode}");
        }

        using var doc = JsonDocument.Parse(responseText);
        if (doc.RootElement.TryGetProperty("result", out var result))
        {
            return result.GetString() ?? string.Empty;
        }

        return string.Empty;
    }

    private async Task<string> FetchTokenAsync(CancellationToken cancellationToken)
    {
        using var request = new HttpRequestMessage(
            HttpMethod.Post,
            "https://ipaas.catl.com/gateway/outside/ipaas/ipaas/ipaas_getJwtToken");

        request.Headers.TryAddWithoutValidation("deipaaskeyauth", "Wc3X579QXQw99925W214iZ38B8w2sr7H");
        request.Content = new StringContent(
            "{\"appKey\":\"TIMES-YL31AR20\",\"appSecret\":\"585331fc-cca7-4184-97e3-82315993a67d\",\"time\":\"60\"}",
            System.Text.Encoding.UTF8,
            "application/json");

        using var response = await _client.SendAsync(request, cancellationToken);
        var json = await response.Content.ReadAsStringAsync(cancellationToken);
        response.EnsureSuccessStatusCode();

        using var doc = JsonDocument.Parse(json);
        if (doc.RootElement.TryGetProperty("accessToken", out var token))
        {
            return token.GetString() ?? string.Empty;
        }

        throw new InvalidOperationException("获取语音服务 Token 失败");
    }
}
