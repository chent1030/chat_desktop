using System.Globalization;
using System.Linq;
using System.Text;
using System.Text.Json;
using ChatDesktop.Core.Dto;
using ChatDesktop.Core.Enums;
using ChatDesktop.Core.Interfaces;
using ChatDesktop.Core.Models;
using ChatDesktop.Core.Queries;
using ChatDesktop.Infrastructure.Config;
using ChatDesktop.Infrastructure.Http;

namespace ChatDesktop.Infrastructure.Unify;

/// <summary>
/// Unify 任务 API
/// </summary>
public sealed class UnifyTaskApiService : ITaskRemoteService
{
    private readonly HttpClient _client = new()
    {
        Timeout = TimeSpan.FromSeconds(30)
    };

    public async Task CreateTaskAsync(TaskItem task, string currentEmpNo, CancellationToken cancellationToken = default)
    {
        if (EnvConfig.Debug)
        {
            await Task.Delay(200, cancellationToken);
            return;
        }

        var path = EnvConfig.UnifyCreateTaskPath;
        if (string.IsNullOrWhiteSpace(path))
        {
            throw new InvalidOperationException("未配置 UNIFY_API_CREATE_TASK_PATH");
        }

        var payload = new Dictionary<string, object?>
        {
            { "title", task.Title },
            { "description", task.Description },
            { "dueDate", task.DueDate.HasValue ? task.DueDate.Value.ToString("yyyy-MM-dd HH:mm", CultureInfo.InvariantCulture) : null },
            { "priority", (int)task.Priority },
            { "tags", task.Tags }
        };

        var dispatchNow = !string.IsNullOrWhiteSpace(task.AssignedToType) && !string.IsNullOrWhiteSpace(task.AssignedTo);
        if (!dispatchNow)
        {
            payload["empNo"] = currentEmpNo.Trim();
        }
        else
        {
            payload["assignedToType"] = task.AssignedToType;
            payload["assignedTo"] = task.AssignedTo;
            payload["assignedBy"] = currentEmpNo.Trim();
        }

        RemoveNull(payload);

        var json = JsonSerializer.Serialize(payload);
        var response = await PostAsync(path, json, cancellationToken);
        if (!response.IsSuccessStatusCode && response.StatusCode != System.Net.HttpStatusCode.NoContent)
        {
            throw new HttpException("创建任务失败", (int)response.StatusCode, await response.Content.ReadAsStringAsync(cancellationToken));
        }
    }

    public async Task MarkReadAsync(string taskUuid, CancellationToken cancellationToken = default)
    {
        if (EnvConfig.Debug)
        {
            await Task.Delay(120, cancellationToken);
            return;
        }

        var path = EnvConfig.UnifyTaskReadPath;
        if (string.IsNullOrWhiteSpace(path))
        {
            throw new InvalidOperationException("未配置 UNIFY_API_TASK_READ_PATH");
        }

        var json = JsonSerializer.Serialize(new { taskUuid });
        var response = await PostAsync(path, json, cancellationToken);
        if (response.StatusCode != System.Net.HttpStatusCode.NoContent)
        {
            throw new HttpException("任务已读失败", (int)response.StatusCode, await response.Content.ReadAsStringAsync(cancellationToken));
        }
    }

    public async Task CompleteAsync(string taskUuid, CancellationToken cancellationToken = default)
    {
        if (EnvConfig.Debug)
        {
            await Task.Delay(120, cancellationToken);
            return;
        }

        var path = EnvConfig.UnifyTaskCompletePath;
        if (string.IsNullOrWhiteSpace(path))
        {
            throw new InvalidOperationException("未配置 UNIFY_API_TASK_COMPLETE_PATH");
        }

        var json = JsonSerializer.Serialize(new { taskUuid });
        var response = await PostAsync(path, json, cancellationToken);
        if (response.StatusCode != System.Net.HttpStatusCode.NoContent)
        {
            throw new HttpException("任务完成失败", (int)response.StatusCode, await response.Content.ReadAsStringAsync(cancellationToken));
        }
    }

    public async Task<TaskPageResult> FetchTaskPageAsync(TaskPageQuery query, CancellationToken cancellationToken = default)
    {
        if (EnvConfig.Debug)
        {
            await Task.Delay(200, cancellationToken);
            return BuildMockPage(query);
        }

        var path = EnvConfig.UnifyTaskListPath;
        if (string.IsNullOrWhiteSpace(path))
        {
            throw new InvalidOperationException("未配置 UNIFY_API_TASK_LIST_PATH");
        }

        var parameters = new Dictionary<string, object?>
        {
            { "page", query.Page },
            { "size", query.Size },
            { "empNo", query.EmpNo },
            { "assignedBy", query.AssignedBy },
            { "title", query.Title },
            { "dueDateStart", query.DueDateStart?.ToString("yyyy-MM-dd HH:mm", CultureInfo.InvariantCulture) },
            { "dueDateEnd", query.DueDateEnd?.ToString("yyyy-MM-dd HH:mm", CultureInfo.InvariantCulture) },
        };

        RemoveNullOrEmpty(parameters);

        var url = BuildUrl(path);
        if (parameters.Count > 0)
        {
            var queryString = string.Join("&", parameters.Select(kv => $"{Uri.EscapeDataString(kv.Key)}={Uri.EscapeDataString(kv.Value?.ToString() ?? string.Empty)}"));
            url = $"{url}?{queryString}";
        }

        using var request = new HttpRequestMessage(HttpMethod.Get, url);
        request.Headers.TryAddWithoutValidation("Accept", "application/json");
        var response = await _client.SendAsync(request, cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            throw new HttpException("获取任务分页失败", (int)response.StatusCode, await response.Content.ReadAsStringAsync(cancellationToken));
        }

        var json = await response.Content.ReadAsStringAsync(cancellationToken);
        if (string.IsNullOrWhiteSpace(json))
        {
            throw new HttpException("任务分页响应为空", (int)response.StatusCode, json);
        }

        using var doc = JsonDocument.Parse(json);
        if (doc.RootElement.ValueKind != JsonValueKind.Object)
        {
            throw new HttpException("任务分页响应格式无效（期望对象）", (int)response.StatusCode, json);
        }

        var root = doc.RootElement;
        var content = new List<TaskItem>();
        if (root.TryGetProperty("content", out var contentElement) && contentElement.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in contentElement.EnumerateArray())
            {
                if (item.ValueKind != JsonValueKind.Object)
                {
                    continue;
                }

                content.Add(ParseTaskItem(item));
            }
        }

        return new TaskPageResult
        {
            TotalPages = GetInt(root, "totalPages"),
            TotalElements = GetInt(root, "totalElements"),
            NumberOfElements = GetInt(root, "numberOfElements"),
            Size = GetInt(root, "size"),
            Number = GetInt(root, "number"),
            Content = content
        };
    }

    public async Task<IReadOnlyList<DispatchCandidate>> FetchDispatchCandidatesAsync(CancellationToken cancellationToken = default)
    {
        if (EnvConfig.Debug)
        {
            await Task.Delay(120, cancellationToken);
            return new List<DispatchCandidate>
            {
                new() { EmpName = "张三", EmpNo = "61002541", WorkGroup = "运维团队", AccessGroup = "运维团队_数字化BP_创新开发" },
                new() { EmpName = "李四", EmpNo = "61002542", WorkGroup = "代经理", AccessGroup = "运维团队" },
            };
        }

        var path = EnvConfig.UnifyDispatchCandidatesPath;
        if (string.IsNullOrWhiteSpace(path))
        {
            throw new InvalidOperationException("未配置 UNIFY_API_DISPATCH_CANDIDATES_PATH");
        }

        var response = await GetAsync(path, cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            throw new HttpException("获取派发候选失败", (int)response.StatusCode, await response.Content.ReadAsStringAsync(cancellationToken));
        }

        var json = await response.Content.ReadAsStringAsync(cancellationToken);
        var list = JsonSerializer.Deserialize<List<DispatchCandidate>>(json, JsonOptions()) ?? new List<DispatchCandidate>();
        return list;
    }

    public async Task<bool> VerifyEmpNoAsync(string empNo, CancellationToken cancellationToken = default)
    {
        if (EnvConfig.Debug)
        {
            await Task.Delay(100, cancellationToken);
            return empNo.Trim().Length >= 3;
        }

        var path = EnvConfig.UnifyEmpNoCheckPath;
        if (string.IsNullOrWhiteSpace(path))
        {
            throw new InvalidOperationException("未配置 UNIFY_API_EMP_NO_CHECK_PATH");
        }

        var response = await GetAsync($"{path}?empNo={Uri.EscapeDataString(empNo.Trim())}", cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            return false;
        }

        var json = await response.Content.ReadAsStringAsync(cancellationToken);
        if (string.IsNullOrWhiteSpace(json))
        {
            return false;
        }

        using var doc = JsonDocument.Parse(json);
        return doc.RootElement.ValueKind switch
        {
            JsonValueKind.Array => doc.RootElement.GetArrayLength() > 0,
            JsonValueKind.Object => doc.RootElement.EnumerateObject().Any(),
            JsonValueKind.String => !string.IsNullOrWhiteSpace(doc.RootElement.GetString()),
            _ => true
        };
    }

    private async Task<HttpResponseMessage> PostAsync(string path, string json, CancellationToken cancellationToken)
    {
        using var request = new HttpRequestMessage(HttpMethod.Post, BuildUrl(path))
        {
            Content = new StringContent(json, Encoding.UTF8, "application/json")
        };
        request.Headers.TryAddWithoutValidation("Accept", "application/json");
        return await _client.SendAsync(request, cancellationToken);
    }

    private async Task<HttpResponseMessage> GetAsync(string path, CancellationToken cancellationToken)
    {
        using var request = new HttpRequestMessage(HttpMethod.Get, BuildUrl(path));
        request.Headers.TryAddWithoutValidation("Accept", "application/json");
        return await _client.SendAsync(request, cancellationToken);
    }

    private static void RemoveNull(Dictionary<string, object?> payload)
    {
        var keys = payload.Where(kv => kv.Value == null).Select(kv => kv.Key).ToList();
        foreach (var key in keys)
        {
            payload.Remove(key);
        }
    }

    private static void RemoveNullOrEmpty(Dictionary<string, object?> payload)
    {
        var keys = payload.Where(kv =>
        {
            if (kv.Value == null)
            {
                return true;
            }

            if (kv.Value is string s && string.IsNullOrWhiteSpace(s))
            {
                return true;
            }

            return false;
        }).Select(kv => kv.Key).ToList();

        foreach (var key in keys)
        {
            payload.Remove(key);
        }
    }

    private static string BuildUrl(string path)
    {
        var baseUrl = EnvConfig.UnifyApiBaseUrl.TrimEnd('/');
        var normalizedPath = path.StartsWith('/') ? path : $"/{path}";
        return baseUrl + normalizedPath;
    }

    private static JsonSerializerOptions JsonOptions()
    {
        return new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true
        };
    }

    private static TaskItem ParseTaskItem(JsonElement element)
    {
        var createdAt = ParseDateTime(GetString(element, "createdAt")) ?? DateTime.Now;
        var updatedAt = ParseDateTime(GetString(element, "updatedAt")) ?? createdAt;

        return new TaskItem
        {
            Id = GetInt(element, "id"),
            TaskUid = GetString(element, "taskUuid") ?? Guid.NewGuid().ToString(),
            Title = GetString(element, "title") ?? string.Empty,
            Description = NormalizeText(GetString(element, "description")),
            Priority = ParsePriority(GetString(element, "priority")),
            IsCompleted = GetBool(element, "isCompleted"),
            IsRead = GetBool(element, "isRead"),
            DueDate = ParseDateTime(GetString(element, "dueDate")),
            CreatedAt = createdAt,
            UpdatedAt = updatedAt,
            Source = GetString(element, "source") == "1" ? TaskSource.Ai : TaskSource.Manual,
            CreatedByAgentId = GetString(element, "createdByAgentId"),
            CompletedAt = ParseDateTime(GetString(element, "completedAt")),
            Tags = GetString(element, "tags"),
            AssignedTo = GetString(element, "assignedTo"),
            AssignedToType = GetString(element, "assignedToType"),
            AssignedBy = GetString(element, "assignedBy"),
            AssignedAt = ParseDateTime(GetString(element, "assignedAt")),
            AllowDispatch = false
        };
    }

    private static TaskPageResult BuildMockPage(TaskPageQuery query)
    {
        var page = query.Page;
        var size = query.Size;
        var totalPages = 10;
        var totalElements = totalPages * size;
        var now = DateTime.Now;

        var start = NormalizeDate(query.DueDateStart);
        var end = NormalizeDate(query.DueDateEnd);

        var items = new List<TaskItem>();
        for (var i = 0; i < size; i++)
        {
            var index = page * size + i + 1;
            var due = now.AddHours(index);
            if (start.HasValue && due < start.Value)
            {
                continue;
            }
            if (end.HasValue && due > end.Value)
            {
                continue;
            }

            var title = string.IsNullOrWhiteSpace(query.Title)
                ? $"Mock任务 {index}"
                : $"[{query.Title}] Mock任务 {index}";

            var task = new TaskItem
            {
                Id = index,
                TaskUid = $"mock-task-{index}",
                Title = title,
                Description = $"## Mock 描述\n- 序号：{index}\n- 仅用于 DEBUG=true 调试",
                Priority = (Priority)(index % 3),
                IsCompleted = index % 4 == 0,
                IsRead = index % 3 == 0,
                DueDate = due,
                CreatedAt = now.AddDays(-index),
                UpdatedAt = now.AddDays(-index + 1),
                Source = TaskSource.Manual,
                Tags = index % 2 == 0 ? "mock" : string.Empty,
                AssignedTo = string.IsNullOrWhiteSpace(query.AssignedBy) ? string.Empty : "运维团队",
                AssignedToType = string.IsNullOrWhiteSpace(query.AssignedBy) ? string.Empty : "团队",
                AssignedBy = query.AssignedBy,
                AssignedAt = string.IsNullOrWhiteSpace(query.AssignedBy) ? null : now.AddDays(-1),
                AllowDispatch = false
            };

            items.Add(task);
        }

        return new TaskPageResult
        {
            TotalPages = totalPages,
            TotalElements = totalElements,
            NumberOfElements = items.Count,
            Size = size,
            Number = page,
            Content = items
        };
    }

    private static DateTime? NormalizeDate(DateTime? value)
    {
        if (!value.HasValue)
        {
            return null;
        }

        var v = value.Value;
        return new DateTime(v.Year, v.Month, v.Day, v.Hour, v.Minute, 0);
    }

    private static string? NormalizeText(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        return value.Trim();
    }

    private static int GetInt(JsonElement element, string name)
    {
        if (!element.TryGetProperty(name, out var prop))
        {
            return 0;
        }

        return prop.ValueKind switch
        {
            JsonValueKind.Number => prop.TryGetInt32(out var v) ? v : 0,
            JsonValueKind.String => int.TryParse(prop.GetString(), out var v) ? v : 0,
            _ => 0
        };
    }

    private static bool GetBool(JsonElement element, string name)
    {
        if (!element.TryGetProperty(name, out var prop))
        {
            return false;
        }

        return prop.ValueKind switch
        {
            JsonValueKind.True => true,
            JsonValueKind.False => false,
            JsonValueKind.Number => prop.TryGetInt32(out var v) && v != 0,
            JsonValueKind.String => bool.TryParse(prop.GetString(), out var v) ? v : prop.GetString() == "1",
            _ => false
        };
    }

    private static string? GetString(JsonElement element, string name)
    {
        if (!element.TryGetProperty(name, out var prop))
        {
            return null;
        }

        return prop.ValueKind switch
        {
            JsonValueKind.String => prop.GetString(),
            JsonValueKind.Number => prop.GetRawText(),
            JsonValueKind.True => "true",
            JsonValueKind.False => "false",
            JsonValueKind.Null => null,
            _ => prop.GetRawText()
        };
    }

    private static DateTime? ParseDateTime(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
        {
            return null;
        }

        var text = raw.Trim();
        var formats = new[]
        {
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd"
        };

        foreach (var format in formats)
        {
            if (DateTime.TryParseExact(text, format, CultureInfo.InvariantCulture, DateTimeStyles.None, out var value))
            {
                return value;
            }
        }

        return null;
    }

    private static Priority ParsePriority(string? raw)
    {
        if (int.TryParse(raw, out var v))
        {
            return v switch
            {
                0 => Priority.Low,
                2 => Priority.High,
                _ => Priority.Medium
            };
        }

        return Priority.Medium;
    }
}
