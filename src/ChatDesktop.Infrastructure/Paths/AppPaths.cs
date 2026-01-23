using System.IO;
using ChatDesktop.Core.Constants;

namespace ChatDesktop.Infrastructure.Paths;

/// <summary>
/// 应用路径
/// </summary>
public static class AppPaths
{
    private static readonly string AppDataRoot = InitializeRoot();

    public static string AppDataDirectory => AppDataRoot;

    public static string LogsDirectory => EnsureDirectory(Path.Combine(AppDataRoot, "logs"));

    public static string DatabasePath => Path.Combine(AppDataRoot, AppConstants.DatabaseFileName);

    public static string SettingsPath => Path.Combine(AppDataRoot, AppConstants.SettingsFileName);

    private static string InitializeRoot()
    {
        var baseDir = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
        var target = Path.Combine(baseDir, AppConstants.AppDataFolderName);
        Directory.CreateDirectory(target);
        return target;
    }

    private static string EnsureDirectory(string path)
    {
        Directory.CreateDirectory(path);
        return path;
    }
}
