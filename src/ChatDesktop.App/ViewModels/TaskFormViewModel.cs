using System.Collections.ObjectModel;
using System.Linq;
using ChatDesktop.Core.Enums;
using ChatDesktop.Core.Interfaces;
using ChatDesktop.Core.Models;
using ChatDesktop.Core.Services;

namespace ChatDesktop.App.ViewModels;

/// <summary>
/// 任务表单 ViewModel（创建/编辑）
/// </summary>
public sealed class TaskFormViewModel : ViewModelBase
{
    private readonly TaskService _taskService;
    private readonly ITaskRemoteService _remoteService;
    private readonly string _currentEmpNo;
    private readonly int? _taskId;

    private string _title = string.Empty;
    private string _description = string.Empty;
    private Priority _selectedPriority = Priority.Medium;
    private DateTime? _dueDate;
    private string _dueTimeText = string.Empty;
    private string _tags = string.Empty;
    private bool _allowDispatch;
    private string? _assignedToType;
    private string? _selectedUserEmpNo;
    private string? _selectedTeam;
    private bool _isSaving;
    private string? _error;

    public TaskFormViewModel(TaskService taskService, ITaskRemoteService remoteService, string currentEmpNo, int? taskId)
    {
        _taskService = taskService;
        _remoteService = remoteService;
        _currentEmpNo = currentEmpNo;
        _taskId = taskId;

        SaveCommand = new AsyncRelayCommand(SaveAsync, CanSave);
        CancelCommand = new RelayCommand(_ => CloseRequested?.Invoke());

        PriorityOptions = new List<EnumOption<Priority>>
        {
            new(Priority.Low, "低"),
            new(Priority.Medium, "中"),
            new(Priority.High, "高"),
        };

        DispatchTypeOptions = new List<string> { "不派发", "用户", "团队" };
    }

    public event Action? CloseRequested;

    public bool IsEditing => _taskId.HasValue;

    public IReadOnlyList<EnumOption<Priority>> PriorityOptions { get; }

    public IReadOnlyList<string> DispatchTypeOptions { get; }

    public ObservableCollection<DispatchCandidate> UserOptions { get; } = new();

    public ObservableCollection<string> TeamOptions { get; } = new();

    public TaskService TaskService => _taskService;

    public ITaskRemoteService RemoteService => _remoteService;

    public string CurrentEmpNo => _currentEmpNo;

    public string Title
    {
        get => _title;
        set
        {
            if (_title == value)
            {
                return;
            }

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
            if (_description == value)
            {
                return;
            }

            _description = value;
            RaisePropertyChanged();
        }
    }

    public Priority SelectedPriority
    {
        get => _selectedPriority;
        set
        {
            if (_selectedPriority == value)
            {
                return;
            }

            _selectedPriority = value;
            RaisePropertyChanged();
        }
    }

    public DateTime? DueDate
    {
        get => _dueDate;
        set
        {
            if (_dueDate == value)
            {
                return;
            }

            _dueDate = value;
            RaisePropertyChanged();
            RaisePropertyChanged(nameof(DueDateDisplay));
        }
    }

    public string DueTimeText
    {
        get => _dueTimeText;
        set
        {
            if (_dueTimeText == value)
            {
                return;
            }

            _dueTimeText = value;
            RaisePropertyChanged();
        }
    }

    public string DueDateDisplay => DueDate.HasValue
        ? DueDate.Value.ToString("yyyy-MM-dd HH:mm")
        : "选择截止日期(可选)";

    public string Tags
    {
        get => _tags;
        set
        {
            if (_tags == value)
            {
                return;
            }

            _tags = value;
            RaisePropertyChanged();
        }
    }

    public bool AllowDispatch
    {
        get => _allowDispatch;
        set
        {
            if (_allowDispatch == value)
            {
                return;
            }

            _allowDispatch = value;
            RaisePropertyChanged();
        }
    }

    public string? AssignedToType
    {
        get => _assignedToType;
        set
        {
            var normalized = string.IsNullOrWhiteSpace(value) ? null : value.Trim();
            if (_assignedToType == normalized)
            {
                return;
            }

            _assignedToType = normalized;
            if (string.IsNullOrWhiteSpace(_assignedToType) || _assignedToType == "不派发")
            {
                SelectedUserEmpNo = null;
                SelectedTeam = null;
            }

            RaisePropertyChanged();
        }
    }

    public string? SelectedUserEmpNo
    {
        get => _selectedUserEmpNo;
        set
        {
            if (_selectedUserEmpNo == value)
            {
                return;
            }

            _selectedUserEmpNo = value;
            RaisePropertyChanged();
        }
    }

    public string? SelectedTeam
    {
        get => _selectedTeam;
        set
        {
            if (_selectedTeam == value)
            {
                return;
            }

            _selectedTeam = value;
            RaisePropertyChanged();
        }
    }

    public bool IsSaving
    {
        get => _isSaving;
        private set
        {
            if (_isSaving == value)
            {
                return;
            }

            _isSaving = value;
            RaisePropertyChanged();
            SaveCommand.RaiseCanExecuteChanged();
        }
    }

    public string? Error
    {
        get => _error;
        private set
        {
            if (_error == value)
            {
                return;
            }

            _error = value;
            RaisePropertyChanged();
        }
    }

    public AsyncRelayCommand SaveCommand { get; }
    public RelayCommand CancelCommand { get; }

    public async Task InitializeAsync()
    {
        if (IsEditing)
        {
            var task = await _taskService.GetByIdAsync(_taskId!.Value);
            if (task == null)
            {
                Error = "任务不存在";
                return;
            }

            Title = task.Title;
            Description = task.Description ?? string.Empty;
            SelectedPriority = task.Priority;
            DueDate = task.DueDate;
            DueTimeText = task.DueDate.HasValue ? task.DueDate.Value.ToString("HH:mm") : string.Empty;
            Tags = task.Tags ?? string.Empty;
            AllowDispatch = task.AllowDispatch;
            return;
        }

        await LoadDispatchCandidatesAsync();
    }

    private bool CanSave()
    {
        return !IsSaving && !string.IsNullOrWhiteSpace(Title);
    }

    private async Task SaveAsync()
    {
        Error = null;
        if (string.IsNullOrWhiteSpace(Title))
        {
            Error = "任务标题不能为空";
            return;
        }

        IsSaving = true;
        try
        {
            if (IsEditing)
            {
                var task = await _taskService.GetByIdAsync(_taskId!.Value);
                if (task == null)
                {
                    Error = "任务不存在";
                    return;
                }

                task.Title = Title.Trim();
                task.Description = string.IsNullOrWhiteSpace(Description) ? null : Description.Trim();
                task.Priority = SelectedPriority;
                task.DueDate = BuildDueDate();
                task.Tags = string.IsNullOrWhiteSpace(Tags) ? null : Tags.Trim();
                task.AllowDispatch = AllowDispatch;

                await _taskService.UpdateAsync(task);
                CloseRequested?.Invoke();
                return;
            }

            if (string.IsNullOrWhiteSpace(_currentEmpNo))
            {
                Error = "未设置工号，无法创建任务";
                return;
            }

            var dispatchType = AssignedToType == "不派发" ? null : AssignedToType;
            string? assignedTo = null;
            if (!string.IsNullOrWhiteSpace(dispatchType))
            {
                if (dispatchType == "用户")
                {
                    if (string.IsNullOrWhiteSpace(SelectedUserEmpNo))
                    {
                        Error = "请选择具体派发用户（工号）";
                        return;
                    }

                    assignedTo = SelectedUserEmpNo;
                }
                else if (dispatchType == "团队")
                {
                    if (string.IsNullOrWhiteSpace(SelectedTeam))
                    {
                        Error = "请选择派发团队";
                        return;
                    }

                    assignedTo = SelectedTeam;
                }
            }

            var taskItem = new TaskItem
            {
                Title = Title.Trim(),
                Description = string.IsNullOrWhiteSpace(Description) ? null : Description.Trim(),
                Priority = SelectedPriority,
                DueDate = BuildDueDate(),
                Tags = string.IsNullOrWhiteSpace(Tags) ? null : Tags.Trim(),
                Source = TaskSource.Manual,
                AssignedToType = string.IsNullOrWhiteSpace(dispatchType) ? null : dispatchType,
                AssignedTo = assignedTo
            };

            await _taskService.CreateAndSyncAsync(taskItem, _currentEmpNo);
            CloseRequested?.Invoke();
        }
        catch (Exception ex)
        {
            Error = $"保存失败: {ex.Message}";
        }
        finally
        {
            IsSaving = false;
        }
    }

    private DateTime? BuildDueDate()
    {
        return DueDate;
    }

    private async Task LoadDispatchCandidatesAsync()
    {
        try
        {
            var list = await _remoteService.FetchDispatchCandidatesAsync();
            UserOptions.Clear();
            TeamOptions.Clear();

            var userMap = new Dictionary<string, DispatchCandidate>();
            var teamSet = new SortedSet<string>(StringComparer.OrdinalIgnoreCase);

            foreach (var candidate in list)
            {
                if (!string.IsNullOrWhiteSpace(candidate.EmpNo) && !string.IsNullOrWhiteSpace(candidate.EmpName))
                {
                    userMap.TryAdd(candidate.EmpNo, candidate);
                }

                if (!string.IsNullOrWhiteSpace(candidate.WorkGroup))
                {
                    teamSet.Add(candidate.WorkGroup.Trim());
                }
            }

            foreach (var item in userMap.Values.OrderBy(u => u.EmpName))
            {
                UserOptions.Add(item);
            }

            foreach (var team in teamSet)
            {
                TeamOptions.Add(team);
            }
        }
        catch
        {
            UserOptions.Clear();
            TeamOptions.Clear();
        }
    }
}
