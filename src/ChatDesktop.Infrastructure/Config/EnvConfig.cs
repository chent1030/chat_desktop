using System.Collections.Concurrent;
using System.Text;
using ChatDesktop.Core.Constants;
using ChatDesktop.Core.Models;
using System.Text.Json;

namespace ChatDesktop.Infrastructure.Config;

/// <summary>
/// .env 配置读取
/// </summary>
public static class EnvConfig
{
    private static readonly ConcurrentDictionary<string, string> Values = new();
    private static bool _loaded;

    public static void Load(AppSettings? settings = null, string? envPath = null)
    {
        if (_loaded)
        {
            ApplySettings(settings);
            return;
        }

        var path = ResolveEnvPath(envPath);
        if (!string.IsNullOrWhiteSpace(path) && File.Exists(path))
        {
            foreach (var line in File.ReadAllLines(path, Encoding.UTF8))
            {
                var trimmed = line.Trim();
                if (string.IsNullOrEmpty(trimmed) || trimmed.StartsWith("#"))
                {
                    continue;
                }

                var idx = trimmed.IndexOf('=');
                if (idx <= 0)
                {
                    continue;
                }

                var key = trimmed[..idx].Trim();
                var value = trimmed[(idx + 1)..].Trim().Trim('"');
                if (!string.IsNullOrEmpty(key))
                {
                    Values[key] = value;
                }
            }
        }

        ApplySettings(settings);
        _loaded = true;
    }

    public static void ApplySettings(AppSettings? settings)
    {
        if (settings?.ExtraConfig == null)
        {
            return;
        }

        foreach (var (rawKey, element) in settings.ExtraConfig)
        {
            if (string.IsNullOrWhiteSpace(rawKey))
            {
                continue;
            }

            var value = ConvertToString(element);
            if (string.IsNullOrWhiteSpace(value))
            {
                continue;
            }

            var key = rawKey.Trim();
            Values[key.ToUpperInvariant()] = value;
        }
    }

    private static string? ResolveEnvPath(string? envPath)
    {
        if (!string.IsNullOrWhiteSpace(envPath) && File.Exists(envPath))
        {
            return envPath;
        }

        var candidates = new List<string>
        {
            Path.Combine(AppDomain.CurrentDomain.BaseDirectory, ".env"),
            Path.Combine(Environment.CurrentDirectory, ".env"),
        };

        foreach (var candidate in candidates)
        {
            if (File.Exists(candidate))
            {
                return candidate;
            }
        }

        // 开发环境：从输出目录向上查找项目根目录的 .env
        var baseDir = new DirectoryInfo(AppDomain.CurrentDomain.BaseDirectory);
        var current = baseDir;
        for (var i = 0; i < 5 && current != null; i++)
        {
            var candidate = Path.Combine(current.FullName, ".env");
            if (File.Exists(candidate))
            {
                return candidate;
            }

            current = current.Parent;
        }

        return null;
    }

    public static bool Debug => GetBool(ConfigKeys.Debug, false);

    public static string UnifyApiBaseUrl => GetString(ConfigKeys.UnifyApiBaseUrl, "https://cshzeroapi.uabcbattery.com/unify/v1/0");
    public static string UnifyCreateTaskPath => GetString(ConfigKeys.UnifyCreateTaskPath, string.Empty);
    public static string UnifyTaskReadPath => GetString(ConfigKeys.UnifyTaskReadPath, string.Empty);
    public static string UnifyTaskCompletePath => GetString(ConfigKeys.UnifyTaskCompletePath, string.Empty);
    public static string UnifyTaskListPath => GetString(ConfigKeys.UnifyTaskListPath, string.Empty);
    public static string UnifyDispatchCandidatesPath => GetString(ConfigKeys.UnifyDispatchCandidatesPath, string.Empty);
    public static string UnifyEmpNoCheckPath => GetString(ConfigKeys.UnifyEmpNoCheckPath, string.Empty);

    public static string ApiBaseUrl => GetString(ConfigKeys.ApiBaseUrl, "http://localhost:3000");
    public static string? ApiToken => GetNullableString(ConfigKeys.ApiToken);

    public static string AiApiUrl => GetString(ConfigKeys.AiApiUrl, string.Empty);
    public static string? AiSseUrl => GetNullableString(ConfigKeys.AiSseUrl);
    public static string AiApiKey => GetString(ConfigKeys.AiApiKey, string.Empty);
    public static string AiApiKeyXinService => GetString(ConfigKeys.AiApiKeyXinService, AiApiKey);
    public static string AiApiKeyLocalQa => GetString(ConfigKeys.AiApiKeyLocalQa, AiApiKey);

    public static string AiTaskExtractApiUrl => GetString(ConfigKeys.AiTaskExtractApiUrl, AiApiUrl);
    public static string? AiTaskExtractSseUrl => GetNullableString(ConfigKeys.AiTaskExtractSseUrl) ?? AiSseUrl;
    public static string AiTaskExtractApiKey => GetString(ConfigKeys.AiTaskExtractApiKey, string.Empty);

    public static string MqttBrokerHost => GetString(ConfigKeys.MqttBrokerHost, "localhost");
    public static int MqttBrokerPort => GetInt(ConfigKeys.MqttBrokerPort, 1883);
    public static string? MqttUsername => GetNullableString(ConfigKeys.MqttUsername);
    public static string? MqttPassword => GetNullableString(ConfigKeys.MqttPassword);
    public static int MqttSessionExpirySeconds => GetInt(ConfigKeys.MqttSessionExpirySeconds, 0);
    public static string MqttTopics => GetString(ConfigKeys.MqttTopics, string.Empty);

    public static string? DeviceId => GetNullableString(ConfigKeys.DeviceId);
    public static string? WebSocketUrl => GetNullableString(ConfigKeys.WebSocketUrl);
    public static string? OutlookPathWindows => GetNullableString(ConfigKeys.OutlookPathWindows);
    public static string? DingTalkPathWindows => GetNullableString(ConfigKeys.DingTalkPathWindows);
    public static string? OpenAiApiKey => GetNullableString(ConfigKeys.OpenAiApiKey);
    public static string? AnthropicApiKey => GetNullableString(ConfigKeys.AnthropicApiKey);

    public static string GetString(string key, string defaultValue)
    {
        var value = GetNullableString(key);
        return string.IsNullOrWhiteSpace(value) ? defaultValue : value;
    }

    public static string? GetNullableString(string key)
    {
        if (Values.TryGetValue(key, out var value))
        {
            return value;
        }

        var envValue = Environment.GetEnvironmentVariable(key);
        return string.IsNullOrWhiteSpace(envValue) ? null : envValue.Trim();
    }

    public static int GetInt(string key, int defaultValue)
    {
        var raw = GetNullableString(key);
        return int.TryParse(raw, out var value) ? value : defaultValue;
    }

    public static bool GetBool(string key, bool defaultValue)
    {
        var raw = GetNullableString(key);
        if (string.IsNullOrWhiteSpace(raw))
        {
            return defaultValue;
        }

        var normalized = raw.Trim().ToLowerInvariant();
        return normalized is "true" or "1" or "yes" or "y";
    }

    private static string? ConvertToString(JsonElement element)
    {
        switch (element.ValueKind)
        {
            case JsonValueKind.String:
                return element.GetString();
            case JsonValueKind.Number:
                return element.ToString();
            case JsonValueKind.True:
                return "true";
            case JsonValueKind.False:
                return "false";
            case JsonValueKind.Null:
            case JsonValueKind.Undefined:
                return null;
            default:
                return element.ToString();
        }
    }
}
