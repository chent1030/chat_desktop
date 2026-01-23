using System.Text.RegularExpressions;
using ChatDesktop.Core.Models;
using ChatDesktop.Core.Services;
using ChatDesktop.Infrastructure.External;

namespace ChatDesktop.App.ViewModels;

/// <summary>
/// 任务详情 ViewModel
/// </summary>
public sealed class TaskDetailViewModel : ViewModelBase
{
    private readonly TaskService _taskService;
    private readonly TaskItem _task;

    public TaskDetailViewModel(TaskItem task, TaskService taskService)
    {
        _task = task;
        _taskService = taskService;

        CloseCommand = new RelayCommand(_ => CloseRequested?.Invoke());
        HandleCommand = new AsyncRelayCommand(HandleAsync, () => CanHandle);
        DispatchCommand = new RelayCommand(_ => DispatchRequested?.Invoke());

        AnalyzeTask();
    }

    public event Action? CloseRequested;
    public event Action? DispatchRequested;

    public TaskItem Task => _task;
    public TaskService TaskService => _taskService;

    public string Title => _task.Title;
    public string? Description => _task.Description;
    public string? Tags => _task.Tags;
    public DateTime? DueDate => _task.DueDate;
    public bool IsRead => _task.IsRead;
    public bool IsCompleted => _task.IsCompleted;
    public bool AllowDispatch => _task.AllowDispatch;

    public bool CanHandle { get; private set; }
    public bool IsMailAction { get; private set; }
    public string? Email { get; private set; }
    public string? EmailId { get; private set; }

    public RelayCommand CloseCommand { get; }
    public AsyncRelayCommand HandleCommand { get; }
    public RelayCommand DispatchCommand { get; }

    private void AnalyzeTask()
    {
        var tagsLower = (Tags ?? string.Empty).ToLowerInvariant();
        var desc = Description ?? string.Empty;
        var descLower = desc.ToLowerInvariant();

        var emailRegex = new Regex(@"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}");
        var emailMatch = emailRegex.Match(tagsLower);
        if (!emailMatch.Success)
        {
            emailMatch = emailRegex.Match(descLower);
        }

        var hasMailKeyword = tagsLower.Contains("邮件") || tagsLower.Contains("邮箱") ||
                             descLower.Contains("邮件") || descLower.Contains("邮箱");

        var idRegex = new Regex(@"(?:邮件ID|郵件ID)[:：]\s*(\S+)");
        var idMatch = idRegex.Match(desc);

        if (emailMatch.Success)
        {
            Email = emailMatch.Value;
        }

        if (idMatch.Success)
        {
            EmailId = idMatch.Groups[1].Value;
        }

        IsMailAction = emailMatch.Success || hasMailKeyword || idMatch.Success;
        CanHandle = tagsLower.Contains("补删卡") || IsMailAction;
    }

    private async Task HandleAsync()
    {
        await _taskService.MarkReadAsync(_task.Id);

        if ((Tags ?? string.Empty).Contains("补删卡"))
        {
            ExternalLauncher.OpenDingTalk();
            return;
        }

        ExternalLauncher.OpenOutlook(Email, EmailId);
    }
}
