namespace ChatDesktop.Core.Interfaces;

/// <summary>
/// MQTT 服务接口
/// </summary>
public interface IMqttService
{
    event Action? TaskChanged;
    event Action<string>? ConnectionStateChanged;

    Task<bool> ConnectAsync(
        string broker,
        int port,
        string empNo,
        string? username,
        string? password,
        CancellationToken cancellationToken = default);

    Task DisconnectAsync(CancellationToken cancellationToken = default);
}
