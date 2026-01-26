using System;
using System.IO;
using System.Linq;
using System.Windows;
using System.Windows.Media;

namespace ChatDesktop.App.Services;

/// <summary>
/// 字体配置与加载
/// </summary>
public static class AppFontService
{
    public const string DefaultKey = "default";
    public const string NotoSansScKey = "NotoSansSC";
    public const string SourceHanSansScKey = "SourceHanSansSC";
    public const string LxgwWenKaiKey = "LXGWWenKai";

    private static readonly IReadOnlyList<AppFontOption> OptionsInternal = new List<AppFontOption>
    {
        new(DefaultKey, "默认", null),
        new(NotoSansScKey, "Noto Sans SC", "Noto Sans SC"),
        new(SourceHanSansScKey, "思源黑体（Source Han Sans SC）", "Source Han Sans SC"),
        new(LxgwWenKaiKey, "霞鹜文楷", "LXGW WenKai"),
    };

    public static IReadOnlyList<AppFontOption> Options => OptionsInternal;

    public static string NormalizeKey(string? key)
    {
        if (string.IsNullOrWhiteSpace(key))
        {
            return DefaultKey;
        }

        return OptionsInternal.Any(o => string.Equals(o.Key, key, StringComparison.OrdinalIgnoreCase))
            ? key
            : DefaultKey;
    }

    public static AppFontOption GetOption(string? key)
    {
        var normalized = NormalizeKey(key);
        return OptionsInternal.First(o => string.Equals(o.Key, normalized, StringComparison.OrdinalIgnoreCase));
    }

    public static FontFamily GetFontFamily(string? key)
    {
        var option = GetOption(key);
        if (string.IsNullOrWhiteSpace(option.FamilyName))
        {
            return SystemFonts.MessageFontFamily;
        }

        return TryCreateCustomFont(option.FamilyName) ?? SystemFonts.MessageFontFamily;
    }

    private static FontFamily? TryCreateCustomFont(string familyName)
    {
        try
        {
            var baseDir = AppDomain.CurrentDomain.BaseDirectory;
            var fontFolder = Path.Combine(baseDir, "Assets", "fonts");
            if (!Directory.Exists(fontFolder))
            {
                return null;
            }

            var uri = new Uri(fontFolder + Path.DirectorySeparatorChar, UriKind.Absolute);
            // 使用字体文件实际家族名匹配，避免 familyName 不一致导致回退到默认字体
            var families = Fonts.GetFontFamilies(uri);
            var matched = families.FirstOrDefault(f =>
                string.Equals(f.Source, familyName, StringComparison.OrdinalIgnoreCase)
                || f.FamilyNames.Values.Any(n => string.Equals(n, familyName, StringComparison.OrdinalIgnoreCase)));
            return matched ?? families.FirstOrDefault();
        }
        catch
        {
            return null;
        }
    }
}

/// <summary>
/// 字体选项
/// </summary>
public sealed class AppFontOption
{
    public AppFontOption(string key, string label, string? familyName)
    {
        Key = key;
        Label = label;
        FamilyName = familyName;
    }

    public string Key { get; }
    public string Label { get; }
    public string? FamilyName { get; }
}
