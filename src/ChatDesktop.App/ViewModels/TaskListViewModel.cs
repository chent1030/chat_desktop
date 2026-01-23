using System.Collections.ObjectModel;
using ChatDesktop.Core.Dto;
using ChatDesktop.Core.Enums;
using ChatDesktop.Core.Models;
using ChatDesktop.Core.Queries;
using ChatDesktop.Core.Services;

namespace ChatDesktop.App.ViewModels;

/// <summary>
/// 任务列表 ViewModel
/// </summary>
public sealed class TaskListViewModel : ViewModelBase
{
    private readonly TaskService _taskService;
    private readonly ObservableCollection<TaskItem> _tasks = new();
    private TaskStatistics _statistics = new();
    private TaskFilter _selectedFilter = TaskFilter.Incomplete;
    private TaskSortOrder _selectedSort = TaskSortOrder.CreatedAtDesc;
    private string _searchKeyword = string.Empty;
    private bool _isLoading;
    private string? _error;

    public TaskListViewModel(TaskService taskService)
    {
        _taskService = taskService;
        RefreshCommand = new AsyncRelayCommand(LoadAsync);
        ClearSearchCommand = new RelayCommand(_ => ClearSearch());
        OpenCreateCommand = new RelayCommand(_ => CreateRequested?.Invoke());
        OpenPagedCommand = new RelayCommand(_ => PagedRequested?.Invoke());
        ClearCompletedCommand = new RelayCommand(_ => ClearCompletedRequested?.Invoke());
        ToggleCompletionCommand = new AsyncRelayCommand<TaskItem>(ToggleCompletionAsync);
        OpenDetailCommand = new RelayCommand(OpenDetail);
        OpenEditCommand = new RelayCommand(OpenEdit);
        OpenVoiceCreateCommand = new RelayCommand(_ => VoiceCreateRequested?.Invoke());
        OpenChangeEmpNoCommand = new RelayCommand(_ => ChangeEmpNoRequested?.Invoke());
        SelectFilterCommand = new RelayCommand(SelectFilter);

        FilterOptions = new List<EnumOption<TaskFilter>>
        {
            new(TaskFilter.All, "全部任务"),
            new(TaskFilter.Incomplete, "未完成"),
            new(TaskFilter.Completed, "已完成"),
            new(TaskFilter.Overdue, "已逾期"),
            new(TaskFilter.DueSoon, "即将到期"),
            new(TaskFilter.Today, "今天"),
        };

        SortOptions = new List<EnumOption<TaskSortOrder>>
        {
            new(TaskSortOrder.CreatedAtDesc, "创建时间 ↓"),
            new(TaskSortOrder.CreatedAtAsc, "创建时间 ↑"),
            new(TaskSortOrder.DueDateAsc, "截止日期 ↑"),
            new(TaskSortOrder.DueDateDesc, "截止日期 ↓"),
            new(TaskSortOrder.PriorityDesc, "优先级 ↓"),
            new(TaskSortOrder.PriorityAsc, "优先级 ↑"),
            new(TaskSortOrder.TitleAsc, "标题 A-Z"),
        };
    }

    public ObservableCollection<TaskItem> Tasks => _tasks;

    public IReadOnlyList<EnumOption<TaskFilter>> FilterOptions { get; }

    public IReadOnlyList<EnumOption<TaskSortOrder>> SortOptions { get; }

    public TaskStatistics Statistics
    {
        get => _statistics;
        private set
        {
            _statistics = value;
            RaisePropertyChanged();
        }
    }

    public TaskFilter SelectedFilter
    {
        get => _selectedFilter;
        set
        {
            if (_selectedFilter == value)
            {
                return;
            }

            _selectedFilter = value;
            RaisePropertyChanged();
            _ = LoadAsync();
        }
    }

    public TaskSortOrder SelectedSort
    {
        get => _selectedSort;
        set
        {
            if (_selectedSort == value)
            {
                return;
            }

            _selectedSort = value;
            RaisePropertyChanged();
            _ = LoadAsync();
        }
    }

    public string SearchKeyword
    {
        get => _searchKeyword;
        set
        {
            if (_searchKeyword == value)
            {
                return;
            }

            _searchKeyword = value;
            RaisePropertyChanged();
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

    public AsyncRelayCommand RefreshCommand { get; }

    public RelayCommand ClearSearchCommand { get; }
    public RelayCommand OpenCreateCommand { get; }
    public RelayCommand OpenPagedCommand { get; }
    public RelayCommand ClearCompletedCommand { get; }

    public AsyncRelayCommand<TaskItem> ToggleCompletionCommand { get; }
    public RelayCommand OpenDetailCommand { get; }
    public RelayCommand OpenEditCommand { get; }
    public RelayCommand OpenVoiceCreateCommand { get; }
    public RelayCommand OpenChangeEmpNoCommand { get; }
    public RelayCommand SelectFilterCommand { get; }

    public event Action<TaskItem>? DetailRequested;
    public event Action<TaskItem>? EditRequested;
    public event Action? CreateRequested;
    public event Action? PagedRequested;
    public event Action? ClearCompletedRequested;
    public event Action? VoiceCreateRequested;
    public event Action? ChangeEmpNoRequested;

    public async Task LoadAsync()
    {
        if (IsLoading)
        {
            return;
        }

        try
        {
            IsLoading = true;
            Error = null;

            var query = new TaskQuery
            {
                Filter = SelectedFilter,
                SortOrder = SelectedSort,
                SearchKeyword = string.IsNullOrWhiteSpace(SearchKeyword) ? null : SearchKeyword,
            };

            var tasks = await _taskService.QueryAsync(query);
            _tasks.Clear();
            foreach (var task in tasks)
            {
                _tasks.Add(task);
            }

            Statistics = await _taskService.GetStatisticsAsync();
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

    private void ClearSearch()
    {
        SearchKeyword = string.Empty;
        _ = LoadAsync();
    }

    private async Task ToggleCompletionAsync(TaskItem? task)
    {
        if (task == null)
        {
            return;
        }

        await _taskService.ToggleCompletionAsync(task.Id);
        await LoadAsync();
    }

    public async Task ClearCompletedAsync()
    {
        await _taskService.ClearCompletedAsync();
        await LoadAsync();
    }

    private void OpenDetail(object? parameter)
    {
        if (parameter is TaskItem task)
        {
            DetailRequested?.Invoke(task);
        }
    }

    private void OpenEdit(object? parameter)
    {
        if (parameter is TaskItem task)
        {
            EditRequested?.Invoke(task);
        }
    }

    private void SelectFilter(object? parameter)
    {
        if (parameter is TaskFilter filter)
        {
            SelectedFilter = filter;
        }
    }
}
