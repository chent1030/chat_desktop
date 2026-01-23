using System.Text;
using System.Text.Json;
using ChatDesktop.Core.Enums;
using ChatDesktop.Core.Interfaces;
using ChatDesktop.Core.Models;
using ChatDesktop.Core.Services;
using ChatDesktop.Infrastructure.Config;
using MQTTnet;
using MQTTnet.Client;

namespace ChatDesktop.Infrastructure.Mqtt;

/// <summary>
/// MQTT 服务实现
/// </summary>
public sealed class MqttService : IMqttService
{
    private IMqttClient? _client;
    private readonly MqttFactory _factory = new();
    private readonly TaskService? _taskService;

    public MqttService(TaskService? taskService = null)
    {
        _taskService = taskService;
    }

    public event Action? TaskChanged;
    public event Action<string>? ConnectionStateChanged;

    public async Task<bool> ConnectAsync(
        string broker,
        int port,
        string empNo,
        string? username,
        string? password,
        CancellationToken cancellationToken = default)
    {
        if (_client != null && _client.IsConnected)
        {
            return true;
        }

        _client = _factory.CreateMqttClient();
        _client.ConnectedAsync += _ =>
        {
            ConnectionStateChanged?.Invoke("connected");
            return Task.CompletedTask;
        };
        _client.DisconnectedAsync += _ =>
        {
            ConnectionStateChanged?.Invoke("disconnected");
            return Task.CompletedTask;
        };
        _client.ApplicationMessageReceivedAsync += HandleMessageAsync;

        var clientId = $"chat_desktop_{empNo}";
        var options = new MqttClientOptionsBuilder()
            .WithClientId(clientId)
            .WithTcpServer(broker, port)
            .WithProtocolVersion(MQTTnet.Formatter.MqttProtocolVersion.V500)
            .WithKeepAlivePeriod(TimeSpan.FromSeconds(60))
            .WithCleanStart(false)
            .Build();

        if (!string.IsNullOrWhiteSpace(username))
        {
            options = new MqttClientOptionsBuilder()
                .WithClientId(clientId)
                .WithTcpServer(broker, port)
                .WithProtocolVersion(MQTTnet.Formatter.MqttProtocolVersion.V500)
                .WithKeepAlivePeriod(TimeSpan.FromSeconds(60))
                .WithCleanStart(false)
                .WithCredentials(username, password)
                .Build();
        }

        try
        {
            ConnectionStateChanged?.Invoke("connecting");
            await _client.ConnectAsync(options, cancellationToken);
            await SubscribeTopicsAsync(empNo, cancellationToken);
            return _client.IsConnected;
        }
        catch
        {
            ConnectionStateChanged?.Invoke("error");
            return false;
        }
    }

    public async Task DisconnectAsync(CancellationToken cancellationToken = default)
    {
        if (_client == null)
        {
            return;
        }

        if (_client.IsConnected)
        {
            await _client.DisconnectAsync(cancellationToken: cancellationToken);
        }
    }

    private async Task SubscribeTopicsAsync(string empNo, CancellationToken cancellationToken)
    {
        if (_client == null)
        {
            return;
        }

        var topics = BuildTopics(empNo);
        if (topics.Count == 0)
        {
            return;
        }

        var filters = topics
            .Select(t => new MqttTopicFilterBuilder().WithTopic(t).Build())
            .ToList();

        await _client.SubscribeAsync(filters, cancellationToken);
    }

    private static List<string> BuildTopics(string empNo)
    {
        var topics = new List<string>();
        var raw = EnvConfig.MqttTopics;
        if (!string.IsNullOrWhiteSpace(raw))
        {
            topics.AddRange(raw.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries));
        }

        if (!topics.Any())
        {
            topics.Add($"mqtt_app/tasks/{empNo}/#");
        }

        return topics;
    }

    private async Task HandleMessageAsync(MqttApplicationMessageReceivedEventArgs args)
    {
        if (_taskService == null)
        {
            return;
        }

        var payload = args.ApplicationMessage?.PayloadSegment;
        if (payload == null || payload.Value.IsEmpty)
        {
            return;
        }

        var text = Encoding.UTF8.GetString(payload.Value.Span);
        if (string.IsNullOrWhiteSpace(text))
        {
            return;
        }

        try
        {
            using var doc = JsonDocument.Parse(text);
            if (doc.RootElement.ValueKind != JsonValueKind.Object)
            {
                return;
            }

            var root = doc.RootElement;
            if (!root.TryGetProperty("action", out var actionElement) || actionElement.ValueKind != JsonValueKind.String)
            {
                return;
            }

            var action = actionElement.GetString();
            switch (action)
            {
                case "create":
                    await HandleCreateAsync(root);
                    break;
                case "update":
                    await HandleUpdateAsync(root);
                    break;
                case "delete":
                    await HandleDeleteAsync(root);
                    break;
                case "complete":
                    await HandleCompleteAsync(root);
                    break;
            }
        }
        catch
        {
        }
    }

    private async Task HandleCreateAsync(JsonElement root)
    {
        if (!root.TryGetProperty("task", out var taskElement) || taskElement.ValueKind != JsonValueKind.Object)
        {
            return;
        }

        var task = ParseTask(taskElement);
        if (string.IsNullOrWhiteSpace(task.TaskUid))
        {
            return;
        }

        var existing = await _taskService!.GetByTaskUidAsync(task.TaskUid);
        if (existing != null)
        {
            return;
        }

        await _taskService.CreateAsync(task);
        TaskChanged?.Invoke();
    }

    private async Task HandleUpdateAsync(JsonElement root)
    {
        if (!root.TryGetProperty("changes", out var changesElement) || changesElement.ValueKind != JsonValueKind.Object)
        {
            return;
        }

        var task = await ResolveTaskAsync(root);
        if (task == null)
        {
            return;
        }

        if (TryGetString(changesElement, "title", out var title))
        {
            task.Title = title ?? task.Title;
        }

        if (TryGetString(changesElement, "description", out var desc))
        {
            task.Description = desc;
        }

        if (TryGetInt(changesElement, "priority", out var priority))
        {
            task.Priority = priority switch
            {
                0 => Priority.Low,
                2 => Priority.High,
                _ => Priority.Medium
            };
        }

        if (TryGetString(changesElement, "dueDate", out var due))
        {
            task.DueDate = ParseDateTime(due) ?? task.DueDate;
        }

        if (TryGetString(changesElement, "tags", out var tags))
        {
            task.Tags = tags;
        }

        await _taskService!.UpdateAsync(task);
        TaskChanged?.Invoke();
    }

    private async Task HandleDeleteAsync(JsonElement root)
    {
        var task = await ResolveTaskAsync(root);
        if (task == null)
        {
            return;
        }

        await _taskService!.DeleteAsync(task.Id);
        TaskChanged?.Invoke();
    }

    private async Task HandleCompleteAsync(JsonElement root)
    {
        var task = await ResolveTaskAsync(root);
        if (task == null)
        {
            return;
        }

        var isCompleted = true;
        if (TryGetBool(root, "isCompleted", out var completed))
        {
            isCompleted = completed ?? true;
        }

        if (isCompleted)
        {
            task.MarkAsCompleted();
        }
        else
        {
            task.MarkAsIncomplete();
        }

        await _taskService!.UpdateAsync(task);
        TaskChanged?.Invoke();
    }

    private async Task<TaskItem?> ResolveTaskAsync(JsonElement root)
    {
        if (TryGetString(root, "uuid", out var uuid) && !string.IsNullOrWhiteSpace(uuid))
        {
            return await _taskService!.GetByTaskUidAsync(uuid);
        }

        if (TryGetInt(root, "taskId", out var taskId) && taskId > 0)
        {
            return await _taskService!.GetByIdAsync(taskId);
        }

        return null;
    }

    private static TaskItem ParseTask(JsonElement element)
    {
        var taskUid = GetString(element, "uuid") ?? GetString(element, "taskUid") ?? Guid.NewGuid().ToString();
        var createdAt = ParseDateTime(GetString(element, "createdAt")) ?? DateTime.Now;
        var updatedAt = ParseDateTime(GetString(element, "updatedAt")) ?? createdAt;

        return new TaskItem
        {
            TaskUid = taskUid,
            Title = GetString(element, "title") ?? string.Empty,
            Description = GetString(element, "description"),
            Priority = ParsePriority(GetInt(element, "priority")),
            IsCompleted = GetBool(element, "isCompleted"),
            IsRead = GetBool(element, "isRead"),
            DueDate = ParseDateTime(GetString(element, "dueDate")),
            CreatedAt = createdAt,
            UpdatedAt = updatedAt,
            Source = ParseSource(GetInt(element, "source")),
            CreatedByAgentId = GetString(element, "createdByAgentId"),
            CompletedAt = ParseDateTime(GetString(element, "completedAt")),
            Tags = GetString(element, "tags"),
            IsSynced = GetBool(element, "isSynced"),
            LastSyncedAt = ParseDateTime(GetString(element, "lastSyncedAt")),
            AssignedTo = GetString(element, "assignedTo"),
            AssignedToType = GetString(element, "assignedToType"),
            AssignedBy = GetString(element, "assignedBy"),
            AssignedAt = ParseDateTime(GetString(element, "assignedAt")),
            AllowDispatch = GetBool(element, "allowDispatch"),
        };
    }

    private static TaskSource ParseSource(int source)
    {
        return source switch
        {
            1 => TaskSource.Ai,
            _ => TaskSource.Manual
        };
    }

    private static Priority ParsePriority(int priority)
    {
        return priority switch
        {
            0 => Priority.Low,
            2 => Priority.High,
            _ => Priority.Medium
        };
    }

    private static bool TryGetString(JsonElement element, string name, out string? value)
    {
        value = null;
        if (!element.TryGetProperty(name, out var prop))
        {
            return false;
        }

        if (prop.ValueKind == JsonValueKind.String)
        {
            value = prop.GetString();
            return true;
        }

        if (prop.ValueKind == JsonValueKind.Number)
        {
            value = prop.GetRawText();
            return true;
        }

        return false;
    }

    private static bool TryGetInt(JsonElement element, string name, out int value)
    {
        value = 0;
        if (!element.TryGetProperty(name, out var prop))
        {
            return false;
        }

        if (prop.ValueKind == JsonValueKind.Number && prop.TryGetInt32(out var num))
        {
            value = num;
            return true;
        }

        if (prop.ValueKind == JsonValueKind.String && int.TryParse(prop.GetString(), out var textNum))
        {
            value = textNum;
            return true;
        }

        return false;
    }

    private static bool TryGetBool(JsonElement element, string name, out bool? value)
    {
        value = null;
        if (!element.TryGetProperty(name, out var prop))
        {
            return false;
        }

        if (prop.ValueKind == JsonValueKind.True)
        {
            value = true;
            return true;
        }

        if (prop.ValueKind == JsonValueKind.False)
        {
            value = false;
            return true;
        }

        if (prop.ValueKind == JsonValueKind.Number && prop.TryGetInt32(out var num))
        {
            value = num != 0;
            return true;
        }

        if (prop.ValueKind == JsonValueKind.String && bool.TryParse(prop.GetString(), out var text))
        {
            value = text;
            return true;
        }

        return false;
    }

    private static string? GetString(JsonElement element, string name)
    {
        return TryGetString(element, name, out var value) ? value : null;
    }

    private static int GetInt(JsonElement element, string name)
    {
        return TryGetInt(element, name, out var value) ? value : 0;
    }

    private static bool GetBool(JsonElement element, string name)
    {
        return TryGetBool(element, name, out var value) && value.HasValue && value.Value;
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
            if (DateTime.TryParseExact(text, format, System.Globalization.CultureInfo.InvariantCulture, System.Globalization.DateTimeStyles.None, out var value))
            {
                return value;
            }
        }

        if (DateTime.TryParse(text, out var fallback))
        {
            return fallback;
        }

        return null;
    }
}
