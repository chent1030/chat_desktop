using System.Windows;
using ChatDesktop.App.ViewModels;

namespace ChatDesktop.App.Views;

/// <summary>
/// Unify 任务详情窗口
/// </summary>
public partial class UnifyTaskDetailWindow : Window
{
    public UnifyTaskDetailWindow(UnifyTaskDetailViewModel viewModel)
    {
        InitializeComponent();
        DataContext = viewModel;
        viewModel.CloseRequested += OnCloseRequested;
    }

    private void OnCloseRequested()
    {
        Close();
    }
}
