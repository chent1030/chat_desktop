using System.Windows;
using ChatDesktop.App.ViewModels;

namespace ChatDesktop.App.Views;

/// <summary>
/// 工号输入窗口
/// </summary>
public partial class EmpNoWindow : Window
{
    public EmpNoWindow(EmpNoViewModel viewModel)
    {
        InitializeComponent();
        DataContext = viewModel;
        viewModel.CloseRequested += () =>
        {
            DialogResult = true;
            Close();
        };
    }
}
