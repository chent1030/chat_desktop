using System.Windows;
using ChatDesktop.App.ViewModels;

namespace ChatDesktop.App.Views;

/// <summary>
/// 任务派发窗口
/// </summary>
public partial class TaskDispatchWindow : Window
{
    public TaskDispatchWindow(TaskDispatchViewModel viewModel)
    {
        InitializeComponent();
        DataContext = viewModel;
        viewModel.CloseRequested += Close;
        viewModel.DispatchSucceeded += message =>
        {
            MessageBox.Show(message, "提示", MessageBoxButton.OK, MessageBoxImage.Information);
        };
        viewModel.LoadCandidatesCommand.Execute(null);
    }
}
