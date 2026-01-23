using System.Collections.ObjectModel;
using ChatDesktop.Core.Dto;
using ChatDesktop.Core.Interfaces;
using ChatDesktop.Core.Models;
using ChatDesktop.Core.Queries;

namespace ChatDesktop.App.ViewModels;

/// <summary>
/// Unify 任务分页 ViewModel
/// </summary>
public sealed class UnifyTaskListViewModel : ViewModelBase
{
    private readonly ITaskRemoteService _remoteService;
    private readonly string _currentEmpNo;

    private UnifyTaskListType _selectedType = UnifyTaskListType.MyTasks;
    private string _keyword = string.Empty;
    private DateTime? _dueStartDate;
    private DateTime? _dueEndDate;
    private string _dueStartTimeText = string.Empty;
    private string _dueEndTimeText = string.Empty;
    private bool _isLoading;
    private string? _error;
    private int _page;
    private int _size = 10;
    private int _totalPages;
    private int _totalElements;

    public UnifyTaskListViewModel(ITaskRemoteService remoteService, string currentEmpNo)
    {
        _remoteService = remoteService;
        _currentEmpNo = currentEmpNo;

        TypeOptions = new List<EnumOption<UnifyTaskListType>>
        {
            new(UnifyTaskListType.MyTasks, "我的任务"),
            new(UnifyTaskListType.DispatchedByMe, "我派发的"),
        };

        SizeOptions = new List<int> { 10, 20, 50 };

        RefreshCommand = new AsyncRelayCommand(LoadAsync);
        SearchCommand = new AsyncRelayCommand(ResetAndLoadAsync);
        PrevCommand = new AsyncRelayCommand(PrevAsync, () => CanPrev);
        NextCommand = new AsyncRelayCommand(NextAsync, () => CanNext);
        OpenDetailCommand = new RelayCommand(OpenDetail);
        MarkReadCommand = new AsyncRelayCommand<TaskItem>(MarkReadAsync);
        CompleteCommand = new AsyncRelayCommand<TaskItem>(CompleteAsync);
    }

    public event Action<TaskItem>? DetailRequested;

    public ObservableCollection<TaskItem> Tasks { get; } = new();

    public IReadOnlyList<EnumOption<UnifyTaskListType>> TypeOptions { get; }

    public IReadOnlyList<int> SizeOptions { get; }

    public UnifyTaskListType SelectedType
    {
        get => _selectedType;
        set
        {
            if (_selectedType == value)
            {
                return;
            }

            _selectedType = value;
            RaisePropertyChanged();
            RaisePropertyChanged(nameof(Title));
            _ = ResetAndLoadAsync();
        }
    }

    public string Keyword
    {
        get => _keyword;
        set
        {
            if (_keyword == value)
            {
                return;
            }

            _keyword = value;
            RaisePropertyChanged();
        }
    }

    public DateTime? DueStartDate
    {
        get => _dueStartDate;
        set
        {
            if (_dueStartDate == value)
            {
                return;
            }

            _dueStartDate = value;
            RaisePropertyChanged();
        }
    }

    public DateTime? DueEndDate
    {
        get => _dueEndDate;
        set
        {
            if (_dueEndDate == value)
            {
                return;
            }

            _dueEndDate = value;
            RaisePropertyChanged();
        }
    }

    public string DueStartTimeText
    {
        get => _dueStartTimeText;
        set
        {
            if (_dueStartTimeText == value)
            {
                return;
            }

            _dueStartTimeText = value;
            RaisePropertyChanged();
        }
    }

    public string DueEndTimeText
    {
        get => _dueEndTimeText;
        set
        {
            if (_dueEndTimeText == value)
            {
                return;
            }

            _dueEndTimeText = value;
            RaisePropertyChanged();
        }
    }

    public bool IsLoading
    {
        get => _isLoading;
        private set
        {
            if (_isLoading == value)
            {
                return;
            }

            _isLoading = value;
            RaisePropertyChanged();
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

    public int Page
    {
        get => _page;
        private set
        {
            if (_page == value)
            {
                return;
            }

            _page = value;
            RaisePropertyChanged();
            RaisePagingChanged();
        }
    }

    public int Size
    {
        get => _size;
        set
        {
            if (_size == value)
            {
                return;
            }

            _size = value;
            RaisePropertyChanged();
            _ = ResetAndLoadAsync();
        }
    }

    public int TotalPages
    {
        get => _totalPages;
        private set
        {
            if (_totalPages == value)
            {
                return;
            }

            _totalPages = value;
            RaisePropertyChanged();
            RaisePagingChanged();
        }
    }

    public int TotalElements
    {
        get => _totalElements;
        private set
        {
            if (_totalElements == value)
            {
                return;
            }

            _totalElements = value;
            RaisePropertyChanged();
        }
    }

    public string PageLabel => TotalPages <= 0 ? "-" : $"{Page + 1}/{TotalPages}";

    public bool CanPrev => Page > 0;

    public bool CanNext => TotalPages > 0 && Page + 1 < TotalPages;

    public AsyncRelayCommand RefreshCommand { get; }
    public AsyncRelayCommand SearchCommand { get; }
    public AsyncRelayCommand PrevCommand { get; }
    public AsyncRelayCommand NextCommand { get; }
    public RelayCommand OpenDetailCommand { get; }
    public AsyncRelayCommand<TaskItem> MarkReadCommand { get; }
    public AsyncRelayCommand<TaskItem> CompleteCommand { get; }

    public string Title => SelectedType == UnifyTaskListType.MyTasks ? "我的任务（分页）" : "我派发的任务（分页）";

    public async Task LoadAsync()
    {
        if (IsLoading)
        {
            return;
        }

        if (string.IsNullOrWhiteSpace(_currentEmpNo))
        {
            Error = "未设置工号，无法加载任务列表";
            return;
        }

        if (!TryBuildDateTime(DueStartDate, DueStartTimeText, out var dueStart) ||
            !TryBuildDateTime(DueEndDate, DueEndTimeText, out var dueEnd))
        {
            Error = "到期时间格式错误，请使用 HH:mm";
            return;
        }

        Error = null;
        IsLoading = true;
        try
        {
            var query = new TaskPageQuery
            {
                Page = Page,
                Size = Size,
                EmpNo = SelectedType == UnifyTaskListType.MyTasks ? _currentEmpNo : null,
                AssignedBy = SelectedType == UnifyTaskListType.DispatchedByMe ? _currentEmpNo : null,
                Title = string.IsNullOrWhiteSpace(Keyword) ? null : Keyword.Trim(),
                DueDateStart = dueStart,
                DueDateEnd = dueEnd
            };

            TaskPageResult result = await _remoteService.FetchTaskPageAsync(query);
            Tasks.Clear();
            foreach (var task in result.Content)
            {
                Tasks.Add(task);
            }

            TotalPages = result.TotalPages;
            TotalElements = result.TotalElements;
        }
        catch (Exception ex)
        {
            Error = $"加载失败: {ex.Message}";
        }
        finally
        {
            IsLoading = false;
            RaisePagingChanged();
        }
    }

    public async Task MarkReadAsync(TaskItem? task)
    {
        if (task == null || string.IsNullOrWhiteSpace(task.TaskUid))
        {
            return;
        }

        try
        {
            await _remoteService.MarkReadAsync(task.TaskUid);
            task.IsRead = true;
        }
        catch
        {
        }
    }

    public async Task CompleteAsync(TaskItem? task)
    {
        if (task == null || string.IsNullOrWhiteSpace(task.TaskUid))
        {
            return;
        }

        await _remoteService.CompleteAsync(task.TaskUid);
        await LoadAsync();
    }

    private async Task ResetAndLoadAsync()
    {
        Page = 0;
        await LoadAsync();
    }

    private async Task PrevAsync()
    {
        if (!CanPrev)
        {
            return;
        }

        Page -= 1;
        await LoadAsync();
    }

    private async Task NextAsync()
    {
        if (!CanNext)
        {
            return;
        }

        Page += 1;
        await LoadAsync();
    }

    private void OpenDetail(object? parameter)
    {
        if (parameter is TaskItem task)
        {
            DetailRequested?.Invoke(task);
        }
    }

    private void RaisePagingChanged()
    {
        RaisePropertyChanged(nameof(PageLabel));
        RaisePropertyChanged(nameof(CanPrev));
        RaisePropertyChanged(nameof(CanNext));
        PrevCommand.RaiseCanExecuteChanged();
        NextCommand.RaiseCanExecuteChanged();
        RaisePropertyChanged(nameof(Title));
    }

    private static bool TryBuildDateTime(DateTime? date, string timeText, out DateTime? value)
    {
        value = null;
        if (!date.HasValue)
        {
            return string.IsNullOrWhiteSpace(timeText);
        }

        if (string.IsNullOrWhiteSpace(timeText))
        {
            value = date.Value.Date;
            return true;
        }

        if (TimeSpan.TryParse(timeText.Trim(), out var time))
        {
            value = date.Value.Date.Add(time);
            return true;
        }

        return false;
    }
}

public enum UnifyTaskListType
{
    MyTasks,
    DispatchedByMe
}
