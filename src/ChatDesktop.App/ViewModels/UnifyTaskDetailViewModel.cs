using ChatDesktop.Core.Models;

namespace ChatDesktop.App.ViewModels;

/// <summary>
/// Unify 任务详情 ViewModel
/// </summary>
public sealed class UnifyTaskDetailViewModel : ViewModelBase
{
    private readonly TaskItem _task;
    private readonly UnifyTaskListViewModel _listViewModel;

    public UnifyTaskDetailViewModel(TaskItem task, UnifyTaskListViewModel listViewModel)
    {
        _task = task;
        _listViewModel = listViewModel;
        CloseCommand = new RelayCommand(_ => CloseRequested?.Invoke());
        MarkReadCommand = new AsyncRelayCommand(MarkReadAsync, () => !_task.IsRead);
        CompleteCommand = new AsyncRelayCommand(CompleteAsync, () => !_task.IsCompleted);
    }

    public event Action? CloseRequested;

    public TaskItem Task => _task;

    public string Title => _task.Title;
    public string? Description => _task.Description;
    public string? Tags => _task.Tags;
    public string? AssignedTo => _task.AssignedTo;
    public string? AssignedBy => _task.AssignedBy;
    public DateTime? DueDate => _task.DueDate;
    public bool IsRead => _task.IsRead;
    public bool IsCompleted => _task.IsCompleted;

    public RelayCommand CloseCommand { get; }
    public AsyncRelayCommand MarkReadCommand { get; }
    public AsyncRelayCommand CompleteCommand { get; }

    private async Task MarkReadAsync()
    {
        await _listViewModel.MarkReadAsync(_task);
        RaisePropertyChanged(nameof(IsRead));
        MarkReadCommand.RaiseCanExecuteChanged();
    }

    private async Task CompleteAsync()
    {
        await _listViewModel.CompleteAsync(_task);
        RaisePropertyChanged(nameof(IsCompleted));
        CompleteCommand.RaiseCanExecuteChanged();
    }
}
