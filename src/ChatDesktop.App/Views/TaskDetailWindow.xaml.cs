using System.Windows;
using ChatDesktop.App.ViewModels;
using ChatDesktop.Core.Interfaces;

namespace ChatDesktop.App.Views;

/// <summary>
/// 任务详情窗口
/// </summary>
public partial class TaskDetailWindow : Window
{
    private readonly ITaskRemoteService _remoteService;
    private readonly string _currentEmpNo;
    private readonly Action? _refreshTasks;

    public TaskDetailWindow(TaskDetailViewModel viewModel, ITaskRemoteService remoteService, string currentEmpNo, Action? refreshTasks = null)
    {
        InitializeComponent();
        DataContext = viewModel;
        _remoteService = remoteService;
        _currentEmpNo = currentEmpNo;
        _refreshTasks = refreshTasks;
        viewModel.CloseRequested += Close;
        viewModel.DispatchRequested += () =>
        {
            var dispatchVm = new TaskDispatchViewModel(viewModel.Task, viewModel.TaskService, _remoteService, _currentEmpNo, _refreshTasks);
            var window = new TaskDispatchWindow(dispatchVm)
            {
                Owner = this
            };
            window.ShowDialog();
        };
    }
}
