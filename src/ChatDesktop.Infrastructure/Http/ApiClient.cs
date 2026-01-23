using System.Net.Http.Headers;
using System.Text;

namespace ChatDesktop.Infrastructure.Http;

/// <summary>
/// HTTP 客户端封装
/// </summary>
public sealed class ApiClient
{
    private readonly HttpClient _client;
    private readonly Func<string?>? _tokenProvider;

    public ApiClient(string baseUrl, Func<string?>? tokenProvider = null)
    {
        _client = new HttpClient
        {
            BaseAddress = new Uri(baseUrl, UriKind.Absolute),
            Timeout = TimeSpan.FromSeconds(30),
        };
        _tokenProvider = tokenProvider;
    }

    public async Task<string> GetAsync(string path, CancellationToken cancellationToken = default)
    {
        using var request = new HttpRequestMessage(HttpMethod.Get, path);
        ApplyHeaders(request);
        using var response = await _client.SendAsync(request, cancellationToken);
        return await HandleResponse(response, cancellationToken);
    }

    public async Task<string> PostAsync(string path, string jsonBody, CancellationToken cancellationToken = default)
    {
        using var request = new HttpRequestMessage(HttpMethod.Post, path);
        ApplyHeaders(request);
        request.Content = new StringContent(jsonBody, Encoding.UTF8, "application/json");
        using var response = await _client.SendAsync(request, cancellationToken);
        return await HandleResponse(response, cancellationToken);
    }

    private void ApplyHeaders(HttpRequestMessage request)
    {
        request.Headers.Accept.Clear();
        request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
        var token = _tokenProvider?.Invoke();
        if (!string.IsNullOrWhiteSpace(token))
        {
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
        }
    }

    private static async Task<string> HandleResponse(HttpResponseMessage response, CancellationToken cancellationToken)
    {
        var content = await response.Content.ReadAsStringAsync(cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            throw new HttpException($"请求失败: {(int)response.StatusCode}", (int)response.StatusCode, content);
        }

        return content;
    }
}
