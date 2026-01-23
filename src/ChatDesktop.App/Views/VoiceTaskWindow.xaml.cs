using System.Windows;
using ChatDesktop.App.ViewModels;

namespace ChatDesktop.App.Views;

/// <summary>
/// 语音创建任务窗口
/// </summary>
public partial class VoiceTaskWindow : Window
{
    public VoiceTaskWindow(VoiceTaskViewModel viewModel)
    {
        InitializeComponent();
        DataContext = viewModel;
        viewModel.CloseRequested += Close;
    }
}
