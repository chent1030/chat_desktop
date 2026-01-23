using System.Windows;
using ChatDesktop.App.ViewModels;

namespace ChatDesktop.App.Views;

/// <summary>
/// 语音输入窗口
/// </summary>
public partial class VoiceInputWindow : Window
{
    public VoiceInputWindow(VoiceInputViewModel viewModel)
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
