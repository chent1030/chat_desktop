using System.Text.Json;
using ChatDesktop.Core.Interfaces;
using ChatDesktop.Core.Models;
using ChatDesktop.Core.Services;
using ChatDesktop.Infrastructure.AI;
using ChatDesktop.Core.Services.Voice;
using ChatDesktop.Infrastructure.Voice;

namespace ChatDesktop.App.ViewModels;

/// <summary>
/// 语音创建任务 ViewModel
/// </summary>
public sealed class VoiceTaskViewModel : ViewModelBase
{
    private readonly AudioRecorderService _recorder;
    private readonly SpeechToTextService _speechService;
    private readonly TaskService _taskService;
    private readonly TaskVoiceExtractionService _extractor;
    private readonly AiWorkflowService _workflowService;
    private readonly AiConfigService _configService;
    private readonly ITaskRemoteService _remoteService;
    private readonly string _currentEmpNo;
    private IReadOnlyList<DispatchCandidate> _candidates = Array.Empty<DispatchCandidate>();

    private string _transcript = string.Empty;
    private string _title = string.Empty;
    private string _description = string.Empty;
    private bool _isRecording;
    private bool _isProcessing;
    private string? _error;

    public VoiceTaskViewModel(
        AudioRecorderService recorder,
        SpeechToTextService speechService,
        TaskService taskService,
        TaskVoiceExtractionService extractor,
        AiWorkflowService workflowService,
        AiConfigService configService,
        ITaskRemoteService remoteService,
        string currentEmpNo)
    {
        _recorder = recorder;
        _speechService = speechService;
        _taskService = taskService;
        _extractor = extractor;
        _workflowService = workflowService;
        _configService = configService;
        _remoteService = remoteService;
        _currentEmpNo = currentEmpNo;

        StartRecordCommand = new AsyncRelayCommand(StartRecordAsync, () => !IsRecording && !IsProcessing);
        StopRecordCommand = new AsyncRelayCommand(StopRecordAsync, () => IsRecording);
        CancelCommand = new AsyncRelayCommand(CancelAsync);
        SaveCommand = new AsyncRelayCommand(SaveAsync, () => !string.IsNullOrWhiteSpace(Title));
    }

    public event Action? CloseRequested;

    public string Transcript
    {
        get => _transcript;
        private set
        {
            _transcript = value;
            RaisePropertyChanged();
        }
    }

    public string Title
    {
        get => _title;
        set
        {
            _title = value;
            RaisePropertyChanged();
            SaveCommand.RaiseCanExecuteChanged();
        }
    }

    public string Description
    {
        get => _description;
        set
        {
            _description = value;
            RaisePropertyChanged();
        }
    }

    public bool IsRecording
    {
        get => _isRecording;
        private set
        {
            _isRecording = value;
            RaisePropertyChanged();
            StartRecordCommand.RaiseCanExecuteChanged();
            StopRecordCommand.RaiseCanExecuteChanged();
        }
    }

    public bool IsProcessing
    {
        get => _isProcessing;
        private set
        {
            _isProcessing = value;
            RaisePropertyChanged();
            StartRecordCommand.RaiseCanExecuteChanged();
            StopRecordCommand.RaiseCanExecuteChanged();
            SaveCommand.RaiseCanExecuteChanged();
        }
    }

    public string? Error
    {
        get => _error;
        private set
        {
            _error = value;
            RaisePropertyChanged();
        }
    }

    public AsyncRelayCommand StartRecordCommand { get; }
    public AsyncRelayCommand StopRecordCommand { get; }
    public AsyncRelayCommand CancelCommand { get; }
    public AsyncRelayCommand SaveCommand { get; }

    private async Task StartRecordAsync()
    {
        Error = null;
        await _recorder.StartAsync();
        IsRecording = true;
    }

    private async Task StopRecordAsync()
    {
        Error = null;
        IsProcessing = true;
        var path = await _recorder.StopAsync();
        IsRecording = false;

        if (string.IsNullOrWhiteSpace(path))
        {
            IsProcessing = false;
            return;
        }

        try
        {
            var transcript = await _speechService.UploadAndTranscribeAsync(
                path,
                "https://ipaas.catl.com/gateway/outside/ipaas/LY_BASIC/outer_LY_BASIC_voiceToText");

            Transcript = transcript;
            await EnsureCandidatesLoaded();

            VoiceTaskDraft draft;
            try
            {
                var now = DateTime.Now;
                var teams = _candidates
                    .Select(c => c.WorkGroup)
                    .Where(w => !string.IsNullOrWhiteSpace(w))
                    .Distinct()
                    .OrderBy(w => w)
                    .ToList();

                var users = _candidates
                    .Where(c => !string.IsNullOrWhiteSpace(c.EmpNo) && !string.IsNullOrWhiteSpace(c.EmpName))
                    .Select(c => new { empName = c.EmpName, empNo = c.EmpNo })
                    .DistinctBy(x => x.empNo)
                    .OrderBy(x => x.empName)
                    .ToList();

                var inputs = new Dictionary<string, object?>
                {
                    { "system_time", now.ToString("yyyy-MM-dd HH:mm:ss") },
                    { "team_group", JsonSerializer.Serialize(teams) },
                    { "user_list", JsonSerializer.Serialize(users) },
                    { "voice_content", transcript.Trim() }
                };

                var config = _configService.GetTaskExtractConfig();
                var buffer = new System.Text.StringBuilder();
                await foreach (var chunk in _workflowService.SendWorkflowStreamAsync(
                                   config,
                                   "开始转换",
                                   _currentEmpNo,
                                   inputs))
                {
                    buffer.Append(chunk);
                }

                draft = _extractor.ExtractFromModelAnswer(buffer.ToString(), transcript, now, _candidates);
            }
            catch
            {
                draft = _extractor.ExtractWithRules(transcript, DateTime.Now, _candidates);
            }

            Title = draft.Title;
            Description = draft.Description;
            DueDate = draft.DueDate;
            DispatchNow = draft.DispatchNow;
            AssignedToType = draft.AssignedToType;
            AssignedTo = draft.AssignedToEmpNo ?? draft.AssignedTo;
        }
        catch (Exception ex)
        {
            Error = ex.Message;
        }
        finally
        {
            IsProcessing = false;
        }
    }

    private async Task SaveAsync()
    {
        var task = new TaskItem
        {
            Title = Title.Trim(),
            Description = Description.Trim(),
            CreatedAt = DateTime.Now,
            UpdatedAt = DateTime.Now,
        };

        if (DispatchNow && !string.IsNullOrWhiteSpace(AssignedToType) && !string.IsNullOrWhiteSpace(AssignedTo))
        {
            task.AssignedToType = AssignedToType;
            task.AssignedTo = AssignedTo;
        }

        if (DueDate.HasValue)
        {
            task.DueDate = DueDate.Value;
        }

        if (string.IsNullOrWhiteSpace(_currentEmpNo))
        {
            Error = "未设置工号，无法创建任务";
            return;
        }

        await _remoteService.CreateTaskAsync(task, _currentEmpNo);
        CloseRequested?.Invoke();
    }

    private async Task CancelAsync()
    {
        await _recorder.CancelAsync();
        CloseRequested?.Invoke();
    }

    private async Task EnsureCandidatesLoaded()
    {
        if (_candidates.Count > 0)
        {
            return;
        }

        try
        {
            _candidates = await _remoteService.FetchDispatchCandidatesAsync();
        }
        catch
        {
            _candidates = Array.Empty<DispatchCandidate>();
        }
    }

    public DateTime? DueDate { get; private set; }
    public bool DispatchNow { get; private set; }
    public string? AssignedToType { get; private set; }
    public string? AssignedTo { get; private set; }
}
