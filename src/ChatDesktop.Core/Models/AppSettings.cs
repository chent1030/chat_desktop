using System.Text.Json;
using System.Text.Json.Serialization;

namespace ChatDesktop.Core.Models;

/// <summary>
/// 本地配置
/// </summary>
public sealed class AppSettings
{
    public string? EmpNo { get; set; }
    public string? FontKey { get; set; }
    public string? AiAssistantKey { get; set; }
    public string? DeviceId { get; set; }
    public DateTime LastSeenTaskTimestamp { get; set; }

    public WindowBounds? MainWindowBounds { get; set; }
    public WindowPoint? MiniWindowPosition { get; set; }

    [JsonExtensionData]
    public Dictionary<string, JsonElement>? ExtraConfig { get; set; }
}

/// <summary>
/// 窗口位置与大小
/// </summary>
public sealed class WindowBounds
{
    public double X { get; set; }
    public double Y { get; set; }
    public double Width { get; set; }
    public double Height { get; set; }
}

/// <summary>
/// 窗口位置
/// </summary>
public sealed class WindowPoint
{
    public double X { get; set; }
    public double Y { get; set; }
}
