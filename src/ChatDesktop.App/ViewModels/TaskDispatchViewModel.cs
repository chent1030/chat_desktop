using System.Collections.ObjectModel;
using ChatDesktop.Core.Interfaces;
using ChatDesktop.Core.Models;
using ChatDesktop.Core.Services;

namespace ChatDesktop.App.ViewModels;

/// <summary>
/// 任务派发 ViewModel
/// </summary>
public sealed class TaskDispatchViewModel : ViewModelBase
{
    private readonly TaskItem _task;
    private readonly TaskService _taskService;
    private readonly ITaskRemoteService _remoteService;
    private readonly string _currentEmpNo;

    private string _assignedToType = "用户";
    private DispatchCandidate? _selectedCandidate;
    private string _customTarget = string.Empty;
    private bool _isLoading;
    private string? _error;

    public TaskDispatchViewModel(
        TaskItem task,
        TaskService taskService,
        ITaskRemoteService remoteService,
        string currentEmpNo,
        Action? refreshRequested = null)
    {
        _task = task;
        _taskService = taskService;
        _remoteService = remoteService;
        _currentEmpNo = currentEmpNo;
        RefreshRequested = refreshRequested;

        Candidates = new ObservableCollection<DispatchCandidate>();

        LoadCandidatesCommand = new AsyncRelayCommand(LoadCandidatesAsync);
        ConfirmCommand = new AsyncRelayCommand(ConfirmAsync, CanConfirm);
        CancelCommand = new RelayCommand(_ => CloseRequested?.Invoke());
    }

    public event Action? CloseRequested;
    public event Action<string>? DispatchSucceeded;
    public Action? RefreshRequested { get; }

    public ObservableCollection<DispatchCandidate> Candidates { get; }

    public IReadOnlyList<string> AssignedToTypeOptions { get; } = new[] { "用户", "团队" };

    public string AssignedToType
    {
        get => _assignedToType;
        set
        {
            if (_assignedToType == value)
            {
                return;
            }

            _assignedToType = value;
            RaisePropertyChanged();
            ConfirmCommand.RaiseCanExecuteChanged();
        }
    }

    public DispatchCandidate? SelectedCandidate
    {
        get => _selectedCandidate;
        set
        {
            if (_selectedCandidate == value)
            {
                return;
            }

            _selectedCandidate = value;
            RaisePropertyChanged();
            ConfirmCommand.RaiseCanExecuteChanged();
        }
    }

    public string CustomTarget
    {
        get => _customTarget;
        set
        {
            _customTarget = value;
            RaisePropertyChanged();
            ConfirmCommand.RaiseCanExecuteChanged();
        }
    }

    public bool IsLoading
    {
        get => _isLoading;
        private set
        {
            _isLoading = value;
            RaisePropertyChanged();
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

    public AsyncRelayCommand LoadCandidatesCommand { get; }
    public AsyncRelayCommand ConfirmCommand { get; }
    public RelayCommand CancelCommand { get; }

    private async Task LoadCandidatesAsync()
    {
        try
        {
            IsLoading = true;
            Error = null;
            var list = await _remoteService.FetchDispatchCandidatesAsync();
            Candidates.Clear();
            foreach (var candidate in list)
            {
                Candidates.Add(candidate);
            }
        }
        catch (Exception ex)
        {
            Error = ex.Message;
        }
        finally
        {
            IsLoading = false;
        }
    }

    private bool CanConfirm()
    {
        if (AssignedToType == "用户")
        {
            return SelectedCandidate != null;
        }

        return !string.IsNullOrWhiteSpace(CustomTarget);
    }

    private async Task ConfirmAsync()
    {
        if (string.IsNullOrWhiteSpace(_currentEmpNo))
        {
            Error = "当前工号为空，无法派发";
            return;
        }

        if (AssignedToType == "用户")
        {
            if (SelectedCandidate == null)
            {
                return;
            }

            _task.AssignedToType = "用户";
            _task.AssignedTo = SelectedCandidate.EmpNo;
            _task.AssignedBy = _currentEmpNo;
        }
        else
        {
            _task.AssignedToType = "团队";
            _task.AssignedTo = CustomTarget.Trim();
            _task.AssignedBy = _currentEmpNo;
        }

        _task.AssignedAt = DateTime.Now;
        _task.AllowDispatch = false;
        _task.Touch();

        try
        {
            IsLoading = true;
            Error = null;
            await _remoteService.CreateTaskAsync(_task, _currentEmpNo);
            await _taskService.UpdateAsync(_task);
            DispatchSucceeded?.Invoke(\"任务派发成功\");
            RefreshRequested?.Invoke();
            CloseRequested?.Invoke();
        }
        catch (Exception ex)
        {
            Error = ex.Message;
        }
        finally
        {
            IsLoading = false;
        }
    }
}
