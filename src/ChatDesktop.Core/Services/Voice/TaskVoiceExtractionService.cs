using System.Globalization;
using System.Linq;
using System.Text.Json;
using ChatDesktop.Core.Models;

namespace ChatDesktop.Core.Services.Voice;

/// <summary>
/// 语音任务抽取
/// </summary>
public sealed class TaskVoiceExtractionService
{
    private static readonly List<string> DispatchKeywords = new()
    {
        "派发给",
        "派给",
        "分配给",
        "指派给",
        "发给",
        "交给"
    };

    private static readonly List<string> ImplicitDispatchKeywords = new()
    {
        "让",
        "通知",
        "提醒",
        "叫"
    };

    public VoiceTaskDraft ExtractWithRules(string transcript, DateTime now, IReadOnlyList<DispatchCandidate> candidates)
    {
        var cleaned = transcript.Trim();
        var dueDate = TryParseDate(cleaned, now);
        var ignoredTimeHint = ExtractTimeHint(cleaned);

        var title = ExtractTitle(cleaned);
        var description = ExtractDescription(cleaned);

        if (!string.IsNullOrWhiteSpace(ignoredTimeHint) && !description.Contains(ignoredTimeHint, StringComparison.Ordinal))
        {
            description = $"{description}\n\n- 截止时间提示：{ignoredTimeHint}（当前保存格式 `yyyy-MM-dd HH:mm`）";
        }

        var dispatchTarget = ExtractDispatchTarget(cleaned);
        var dispatchMatch = MatchDispatchTarget(dispatchTarget, candidates);

        return new VoiceTaskDraft
        {
            Title = title,
            Description = description,
            DueDate = dueDate,
            DispatchNow = dispatchMatch.DispatchNow,
            AssignedToType = dispatchMatch.AssignedToType,
            AssignedTo = dispatchMatch.AssignedTo,
            AssignedToEmpNo = dispatchMatch.AssignedToEmpNo,
            OriginalDispatchTarget = dispatchTarget,
            IgnoredTimeHint = ignoredTimeHint
        };
    }

    public VoiceTaskDraft ExtractFromModelAnswer(
        string modelAnswer,
        string transcript,
        DateTime now,
        IReadOnlyList<DispatchCandidate> candidates)
    {
        var json = ExtractJsonObject(modelAnswer);
        var fields = ParseFields(json);
        return ConvertToDraft(fields, transcript, now, candidates);
    }

    private static string ExtractJsonObject(string raw)
    {
        var text = raw.Trim();
        if (string.IsNullOrWhiteSpace(text))
        {
            throw new FormatException("大模型返回为空");
        }

        if (text.StartsWith('{') && text.EndsWith('}'))
        {
            return text;
        }

        var start = text.IndexOf('{');
        var end = text.LastIndexOf('}');
        if (start < 0 || end <= start)
        {
            throw new FormatException("大模型返回中未找到 JSON 对象");
        }

        return text.Substring(start, end - start + 1);
    }

    private static LlmFields ParseFields(string jsonText)
    {
        var decoded = JsonDocument.Parse(jsonText);
        if (decoded.RootElement.ValueKind != JsonValueKind.Object)
        {
            throw new FormatException("大模型 JSON 不是对象");
        }

        string? StringOrNull(JsonElement element)
        {
            if (element.ValueKind == JsonValueKind.String)
            {
                var s = element.GetString();
                return string.IsNullOrWhiteSpace(s) ? null : s.Trim();
            }

            if (element.ValueKind == JsonValueKind.Number)
            {
                return element.GetRawText();
            }

            return null;
        }

        bool BoolOrFalse(JsonElement element)
        {
            if (element.ValueKind == JsonValueKind.True) return true;
            if (element.ValueKind == JsonValueKind.False) return false;
            if (element.ValueKind == JsonValueKind.String)
            {
                var s = element.GetString()?.ToLowerInvariant();
                return s is "true" or "1";
            }
            return false;
        }

        var root = decoded.RootElement;
        return new LlmFields
        {
            Title = root.TryGetProperty("title", out var title) ? StringOrNull(title) : null,
            Description = root.TryGetProperty("description", out var desc) ? StringOrNull(desc) ?? string.Empty : string.Empty,
            DueDate = root.TryGetProperty("dueDate", out var due) ? StringOrNull(due) : null,
            DispatchNow = root.TryGetProperty("dispatchNow", out var dispatch) && BoolOrFalse(dispatch),
            AssignedToType = root.TryGetProperty("assignedToType", out var type) ? StringOrNull(type) : null,
            AssignedTo = root.TryGetProperty("assignedTo", out var target) ? StringOrNull(target) : null,
            TimeHint = root.TryGetProperty("timeHint", out var hint) ? StringOrNull(hint) : null,
        };
    }

    private VoiceTaskDraft ConvertToDraft(
        LlmFields fields,
        string transcript,
        DateTime now,
        IReadOnlyList<DispatchCandidate> candidates)
    {
        var title = (fields.Title ?? string.Empty).Trim();
        var safeTitle = string.IsNullOrWhiteSpace(title) ? ExtractTitle(transcript) : title;

        DateTime? dueDate = null;
        if (!string.IsNullOrWhiteSpace(fields.DueDate))
        {
            dueDate = ParseDueDate(fields.DueDate!, now);
        }

        var description = fields.Description;
        if (!string.IsNullOrWhiteSpace(fields.TimeHint) && !description.Contains(fields.TimeHint!, StringComparison.Ordinal))
        {
            description = $"{description}\n\n- 截止时间提示：{fields.TimeHint}（当前保存格式 `yyyy-MM-dd HH:mm`）";
        }

        var fallbackTarget = ExtractDispatchTarget(transcript);
        var fallbackMatch = MatchDispatchTarget(fallbackTarget, candidates);
        var shouldDispatch = fields.DispatchNow ||
                             (!string.IsNullOrWhiteSpace(fields.AssignedToType) && !string.IsNullOrWhiteSpace(fields.AssignedTo)) ||
                             fallbackMatch.DispatchNow;

        DispatchMatch match;
        if (shouldDispatch && !string.IsNullOrWhiteSpace(fields.AssignedToType))
        {
            match = MatchByTypedTarget(fields.AssignedToType!, fields.AssignedTo, candidates);
        }
        else
        {
            match = MatchDispatchTarget(fallbackTarget ?? fields.AssignedTo, candidates);
        }

        return new VoiceTaskDraft
        {
            Title = safeTitle.Length <= 50 ? safeTitle : safeTitle[..50],
            Description = description,
            DueDate = dueDate ?? TryParseDate(transcript, now),
            DispatchNow = shouldDispatch && match.DispatchNow,
            AssignedToType = shouldDispatch ? match.AssignedToType : null,
            AssignedTo = shouldDispatch ? match.AssignedTo : null,
            AssignedToEmpNo = shouldDispatch ? match.AssignedToEmpNo : null,
            OriginalDispatchTarget = fields.AssignedTo ?? fallbackTarget,
            IgnoredTimeHint = fields.TimeHint
        };
    }

    private static string ExtractTitle(string transcript)
    {
        var text = transcript.Trim();
        if (string.IsNullOrWhiteSpace(text))
        {
            return "新任务";
        }

        var separators = new[] { '。', '.', '！', '!', '？', '?', '\n' };
        var index = text.IndexOfAny(separators);
        var result = index > 0 ? text[..index] : text;
        return result.Length > 50 ? result[..50] : result;
    }

    private static string ExtractDescription(string transcript)
    {
        return transcript.Trim();
    }

    private static string? ExtractDispatchTarget(string transcript)
    {
        foreach (var keyword in DispatchKeywords)
        {
            var index = transcript.IndexOf(keyword, StringComparison.Ordinal);
            if (index >= 0)
            {
                return ExtractTargetAfter(transcript, index + keyword.Length);
            }
        }

        foreach (var keyword in ImplicitDispatchKeywords)
        {
            var index = transcript.IndexOf(keyword, StringComparison.Ordinal);
            if (index >= 0)
            {
                return ExtractTargetAfter(transcript, index + keyword.Length);
            }
        }

        return null;
    }

    private static string? ExtractTargetAfter(string transcript, int start)
    {
        if (start >= transcript.Length)
        {
            return null;
        }

        var tail = transcript[start..].Trim();
        if (string.IsNullOrWhiteSpace(tail))
        {
            return null;
        }

        var separators = new[] { '，', ',', '。', '.', '！', '!', '？', '?', ' ' };
        var index = tail.IndexOfAny(separators);
        var result = index > 0 ? tail[..index] : tail;
        return result.Trim();
    }

    private static DispatchMatch MatchByTypedTarget(string type, string? target, IReadOnlyList<DispatchCandidate> candidates)
    {
        var t = target?.Trim();
        if (string.IsNullOrWhiteSpace(t))
        {
            return DispatchMatch.None();
        }

        if (type == "团队")
        {
            var workGroups = candidates
                .Select(c => c.WorkGroup)
                .Where(w => !string.IsNullOrWhiteSpace(w))
                .Select(w => w!.Trim())
                .ToHashSet();

            if (workGroups.Contains(t))
            {
                return DispatchMatch.Team(t);
            }

            var hit = workGroups.FirstOrDefault(g => g.Contains(t) || t.Contains(g));
            return string.IsNullOrWhiteSpace(hit) ? DispatchMatch.Unknown(t) : DispatchMatch.Team(hit);
        }

        if (type == "用户")
        {
            var byEmpNo = candidates.Where(c => c.EmpNo == t).ToList();
            if (byEmpNo.Count == 1)
            {
                return DispatchMatch.User(byEmpNo[0].EmpName, byEmpNo[0].EmpNo);
            }

            var matched = candidates.Where(c => c.EmpName == t).ToList();
            if (matched.Count == 1)
            {
                return DispatchMatch.User(matched[0].EmpName, matched[0].EmpNo);
            }

            return DispatchMatch.Unknown(t);
        }

        return DispatchMatch.None();
    }

    private static DispatchMatch MatchDispatchTarget(string? target, IReadOnlyList<DispatchCandidate> candidates)
    {
        var t = target?.Trim();
        if (string.IsNullOrWhiteSpace(t))
        {
            return DispatchMatch.None();
        }

        var workGroup = candidates
            .Select(c => c.WorkGroup)
            .Where(w => !string.IsNullOrWhiteSpace(w))
            .Select(w => w!.Trim())
            .FirstOrDefault(w => w == t || w.Contains(t) || t.Contains(w));

        if (!string.IsNullOrWhiteSpace(workGroup))
        {
            return DispatchMatch.Team(workGroup);
        }

        var byName = candidates.Where(c => c.EmpName == t).ToList();
        if (byName.Count == 1)
        {
            return DispatchMatch.User(byName[0].EmpName, byName[0].EmpNo);
        }

        return DispatchMatch.Unknown(t);
    }

    private static DateTime? ParseDueDate(string value, DateTime now)
    {
        if (DateTime.TryParse(value, CultureInfo.CurrentCulture, DateTimeStyles.AssumeLocal, out var parsed))
        {
            return parsed;
        }

        if (DateTime.TryParseExact(value, "yyyy-MM-dd HH:mm", CultureInfo.InvariantCulture, DateTimeStyles.None, out parsed))
        {
            return parsed;
        }

        if (DateTime.TryParseExact(value, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out parsed))
        {
            return parsed;
        }

        return null;
    }

    private static DateTime? TryParseDate(string text, DateTime now)
    {
        if (DateTime.TryParse(text, CultureInfo.CurrentCulture, DateTimeStyles.AssumeLocal, out var parsed))
        {
            return parsed;
        }

        return null;
    }

    private static string? ExtractTimeHint(string text)
    {
        var patterns = new[] { "下午", "上午", "中午", "晚上" };
        return patterns.FirstOrDefault(text.Contains);
    }

    private sealed class LlmFields
    {
        public string? Title { get; set; }
        public string Description { get; set; } = string.Empty;
        public string? DueDate { get; set; }
        public bool DispatchNow { get; set; }
        public string? AssignedToType { get; set; }
        public string? AssignedTo { get; set; }
        public string? TimeHint { get; set; }
    }

    private sealed class DispatchMatch
    {
        public bool DispatchNow { get; init; }
        public string? AssignedToType { get; init; }
        public string? AssignedTo { get; init; }
        public string? AssignedToEmpNo { get; init; }

        public static DispatchMatch None() => new();

        public static DispatchMatch Team(string workGroup) => new()
        {
            DispatchNow = true,
            AssignedToType = "团队",
            AssignedTo = workGroup
        };

        public static DispatchMatch User(string empName, string empNo) => new()
        {
            DispatchNow = true,
            AssignedToType = "用户",
            AssignedTo = empName,
            AssignedToEmpNo = empNo
        };

        public static DispatchMatch Unknown(string target) => new()
        {
            DispatchNow = true,
            AssignedTo = target
        };
    }
}
