using System.Windows;
using ChatDesktop.App.ViewModels;

namespace ChatDesktop.App.Views;

/// <summary>
/// 任务表单窗口
/// </summary>
public partial class TaskFormWindow : Window
{
    public TaskFormWindow(TaskFormViewModel viewModel)
    {
        InitializeComponent();
        DataContext = viewModel;
        viewModel.CloseRequested += OnCloseRequested;
    }

    private async void OnLoaded(object sender, RoutedEventArgs e)
    {
        if (DataContext is TaskFormViewModel viewModel)
        {
            await viewModel.InitializeAsync();
        }
    }

    private void OnCloseRequested()
    {
        Close();
    }
}
