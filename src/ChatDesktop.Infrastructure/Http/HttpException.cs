namespace ChatDesktop.Infrastructure.Http;

/// <summary>
/// HTTP 异常
/// </summary>
public sealed class HttpException : Exception
{
    public int StatusCode { get; }
    public string? ResponseContent { get; }

    public HttpException(string message, int statusCode, string? responseContent = null)
        : base(message)
    {
        StatusCode = statusCode;
        ResponseContent = responseContent;
    }
}
