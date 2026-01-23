using System.Text.Json;
using ChatDesktop.Core.Models;
using ChatDesktop.Infrastructure.Paths;

namespace ChatDesktop.Infrastructure.Config;

/// <summary>
/// 本地配置存储
/// </summary>
public sealed class LocalSettingsStore
{
    private readonly JsonSerializerOptions _jsonOptions = new()
    {
        WriteIndented = true,
    };

    public async Task<AppSettings> LoadAsync(CancellationToken cancellationToken = default)
    {
        var path = AppPaths.SettingsPath;
        if (!File.Exists(path))
        {
            return new AppSettings();
        }

        var json = await File.ReadAllTextAsync(path, cancellationToken);
        var settings = JsonSerializer.Deserialize<AppSettings>(json, _jsonOptions);
        return settings ?? new AppSettings();
    }

    public async Task SaveAsync(AppSettings settings, CancellationToken cancellationToken = default)
    {
        var path = AppPaths.SettingsPath;
        var json = JsonSerializer.Serialize(settings, _jsonOptions);
        await File.WriteAllTextAsync(path, json, cancellationToken);
    }
}
