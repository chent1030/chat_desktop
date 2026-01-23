using System.Text;
using ChatDesktop.Core.Constants;
using ChatDesktop.Infrastructure.Paths;

namespace ChatDesktop.Infrastructure.Logging;

/// <summary>
/// 日志服务
/// </summary>
public sealed class LogService
{
    private readonly object _lock = new();
    private string? _currentLogDate;
    private string? _currentLogPath;
    private string? _currentCrashPath;

    public void Log(string message, LogLevel level = LogLevel.Info, string? tag = null)
    {
        lock (_lock)
        {
            RotateIfNeeded();
            var timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff");
            var levelText = level.ToString().ToUpperInvariant().PadRight(5);
            var tagText = string.IsNullOrWhiteSpace(tag) ? string.Empty : $"[{tag}] ";
            var line = $"[{timestamp}] [{levelText}] {tagText}{message}{Environment.NewLine}";
            File.AppendAllText(_currentLogPath!, line, Encoding.UTF8);
        }
    }

    public void LogCrash(string context, Exception exception)
    {
        lock (_lock)
        {
            RotateIfNeeded();
            var timestamp = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fff");
            var line = $"[{timestamp}] [CRASH] {context}: {exception}{Environment.NewLine}";
            File.AppendAllText(_currentCrashPath!, line, Encoding.UTF8);
        }
    }

    public void Debug(string message, string? tag = null) => Log(message, LogLevel.Debug, tag);
    public void Info(string message, string? tag = null) => Log(message, LogLevel.Info, tag);
    public void Warning(string message, string? tag = null) => Log(message, LogLevel.Warning, tag);
    public void Error(string message, string? tag = null) => Log(message, LogLevel.Error, tag);

    private void RotateIfNeeded()
    {
        var today = DateTime.Now.ToString("yyyy-MM-dd");
        if (_currentLogDate == today && _currentLogPath != null && _currentCrashPath != null)
        {
            return;
        }

        _currentLogDate = today;
        var logDir = AppPaths.LogsDirectory;
        _currentLogPath = Path.Combine(logDir, $"app_{today}.log");
        _currentCrashPath = Path.Combine(logDir, $"crash_{today}.log");

        EnsureFile(_currentLogPath, $"=== Chat Desktop 日志 - {today} ===");
        EnsureFile(_currentCrashPath, $"=== Chat Desktop 崩溃日志 - {today} ===");
        CleanupOldLogs(logDir);
    }

    private static void EnsureFile(string path, string header)
    {
        if (File.Exists(path))
        {
            return;
        }

        var content = "\uFEFF" + header + Environment.NewLine;
        File.WriteAllText(path, content, Encoding.UTF8);
    }

    private static void CleanupOldLogs(string logDir)
    {
        var cutoff = DateTime.Now.AddDays(-AppConstants.LogRetentionDays);
        foreach (var file in Directory.GetFiles(logDir, "*.log"))
        {
            var name = Path.GetFileName(file);
            var parts = name.Split('_', '.', StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length < 2)
            {
                continue;
            }

            if (!DateTime.TryParse(parts[1], out var fileDate))
            {
                continue;
            }

            if (fileDate < cutoff)
            {
                try
                {
                    File.Delete(file);
                }
                catch
                {
                }
            }
        }
    }
}
