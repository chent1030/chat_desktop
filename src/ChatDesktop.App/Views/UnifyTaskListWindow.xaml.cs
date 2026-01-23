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

    private void OnPickStartDateTime(object sender, RoutedEventArgs e)
    {
        if (DataContext is not UnifyTaskListViewModel viewModel)
        {
            return;
        }

        var window = new DateTimePickerWindow(viewModel.DueStartDate, "选择到期开始")
        {
            Owner = this
        };
        if (window.ShowDialog() == true)
        {
            viewModel.DueStartDate = window.SelectedDateTime;
        }
    }

    private void OnPickEndDateTime(object sender, RoutedEventArgs e)
    {
        if (DataContext is not UnifyTaskListViewModel viewModel)
        {
            return;
        }

        var window = new DateTimePickerWindow(viewModel.DueEndDate, "选择到期结束")
        {
            Owner = this
        };
        if (window.ShowDialog() == true)
        {
            viewModel.DueEndDate = window.SelectedDateTime;
        }
    }

    private void OnCloseClicked(object sender, RoutedEventArgs e)
    {
        Close();
    }
}
