using System.Windows;
using ChatDesktop.App.ViewModels;

namespace ChatDesktop.App.Views;

/// <summary>
/// Unify 任务分页窗口
/// </summary>
public partial class UnifyTaskListWindow : Window
{
    public UnifyTaskListWindow(UnifyTaskListViewModel viewModel)
    {
        InitializeComponent();
        DataContext = viewModel;
        viewModel.DetailRequested += OnDetailRequested;
    }

    private async void OnLoaded(object sender, RoutedEventArgs e)
    {
        if (DataContext is UnifyTaskListViewModel viewModel)
        {
            await viewModel.LoadAsync();
        }
    }

    private async void OnDetailRequested(Core.Models.TaskItem task)
    {
        if (DataContext is not UnifyTaskListViewModel viewModel)
        {
            return;
        }

        if (viewModel.SelectedType == UnifyTaskListType.MyTasks)
        {
            await viewModel.MarkReadAsync(task);
        }

        var detailVm = new UnifyTaskDetailViewModel(task, viewModel);
        var window = new UnifyTaskDetailWindow(detailVm)
        {
            Owner = this
        };
        window.ShowDialog();
        await viewModel.LoadAsync();
    }

    private void OnCloseClicked(object sender, RoutedEventArgs e)
    {
        Close();
    }
}
