using ChatDesktop.Core.Models;

namespace ChatDesktop.Infrastructure.Config;

/// <summary>
/// 本地设置服务
/// </summary>
public sealed class AppSettingsService
{
    private readonly LocalSettingsStore _store;
    private AppSettings? _cached;

    public AppSettingsService(LocalSettingsStore store)
    {
        _store = store;
    }

    public async Task<AppSettings> LoadAsync(CancellationToken cancellationToken = default)
    {
        _cached = await _store.LoadAsync(cancellationToken).ConfigureAwait(false);
        return _cached;
    }

    public AppSettings? Current => _cached;
}
