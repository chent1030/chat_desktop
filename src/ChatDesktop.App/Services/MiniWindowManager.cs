using System.ComponentModel;
using System.Drawing;
using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Threading;
using ChatDesktop.App.ViewModels;
using ChatDesktop.App.Views;
using ChatDesktop.Core.Models;
using ChatDesktop.Infrastructure.Config;
using H.NotifyIcon;

namespace ChatDesktop.App.Services;

/// <summary>
/// 小窗与托盘管理
/// </summary>
public sealed class MiniWindowManager : IDisposable
{
    private readonly Window _mainWindow;
    private readonly MainViewModel _viewModel;
    private readonly LocalSettingsStore _settingsStore;
    private AppSettings _settings;
    private readonly DispatcherTimer _saveTimer;

    private TaskbarIcon? _trayIcon;
    private MiniWindow? _miniWindow;
    private WindowPoint? _pendingPosition;
    private bool _exitRequested;

    public MiniWindowManager(
        Window mainWindow,
        MainViewModel viewModel,
        LocalSettingsStore settingsStore,
        AppSettings settings)
    {
        _mainWindow = mainWindow;
        _viewModel = viewModel;
        _settingsStore = settingsStore;
        _settings = settings;
        _saveTimer = new DispatcherTimer { Interval = TimeSpan.FromMilliseconds(200) };
        _saveTimer.Tick += async (_, _) =>
        {
            _saveTimer.Stop();
            await SaveMiniWindowPositionAsync();
        };
    }

    public void Initialize()
    {
        _mainWindow.Closing += OnMainWindowClosing;
        _viewModel.TaskList.PropertyChanged += OnTaskListPropertyChanged;
        InitializeTrayIcon();
        UpdateMiniUnread(_viewModel.TaskList.UnreadCount);
    }

    public void Dispose()
    {
        _mainWindow.Closing -= OnMainWindowClosing;
        _viewModel.TaskList.PropertyChanged -= OnTaskListPropertyChanged;
        CloseMiniWindow();
        DisposeTrayIcon();
    }

    private void OnMainWindowClosing(object? sender, CancelEventArgs e)
    {
        if (_exitRequested)
        {
            return;
        }

        e.Cancel = true;
        _mainWindow.Hide();
        ShowMiniWindow();
    }

    private void InitializeTrayIcon()
    {
        if (_trayIcon != null)
        {
            return;
        }

        _trayIcon = new TaskbarIcon
        {
            Icon = LoadTrayIcon(),
            ToolTipText = "芯服务 - 双击恢复窗口",
            ContextMenu = BuildTrayMenu()
        };
        _trayIcon.Visibility = Visibility.Visible;
        _trayIcon.TrayMouseDoubleClick += (_, _) => RestoreMainWindow();
    }

    private static Icon LoadTrayIcon()
    {
        try
        {
            var baseDir = AppDomain.CurrentDomain.BaseDirectory;
            var iconPath = Path.Combine(baseDir, "Assets", "Icons", "static_logo.ico");
            if (File.Exists(iconPath))
            {
                return new Icon(iconPath);
            }
        }
        catch
        {
        }

        return SystemIcons.Application;
    }

    private ContextMenu BuildTrayMenu()
    {
        var menu = new ContextMenu();
        var showItem = new MenuItem { Header = "显示窗口" };
        showItem.Click += (_, _) => RestoreMainWindow();
        var exitItem = new MenuItem { Header = "退出" };
        exitItem.Click += (_, _) => ExitApplication();
        menu.Items.Add(showItem);
        menu.Items.Add(new Separator());
        menu.Items.Add(exitItem);
        return menu;
    }

    private void OnTaskListPropertyChanged(object? sender, PropertyChangedEventArgs e)
    {
        if (e.PropertyName == nameof(TaskListViewModel.UnreadCount))
        {
            UpdateMiniUnread(_viewModel.TaskList.UnreadCount);
        }
    }

    private void UpdateMiniUnread(int unreadCount)
    {
        if (_miniWindow != null)
        {
            _miniWindow.SetUnreadCount(unreadCount);
        }
    }

    private void ShowMiniWindow()
    {
        if (_miniWindow == null)
        {
            _miniWindow = new MiniWindow();
            _miniWindow.RestoreRequested += OnMiniWindowRestoreRequested;
            _miniWindow.PositionChanged += OnMiniWindowPositionChanged;
            _miniWindow.Closed += (_, _) => _miniWindow = null;
            ApplyMiniWindowPosition(_miniWindow);
        }

        _miniWindow.SetUnreadCount(_viewModel.TaskList.UnreadCount);
        if (!_miniWindow.IsVisible)
        {
            _miniWindow.Show();
        }
    }

    private void ApplyMiniWindowPosition(Window window)
    {
        var position = _settings.MiniWindowPosition;
        if (position != null)
        {
            window.Left = position.X;
            window.Top = position.Y;
            return;
        }

        var workArea = SystemParameters.WorkArea;
        window.Left = workArea.Right - window.Width - 24;
        window.Top = workArea.Bottom - window.Height - 24;
    }

    private void OnMiniWindowPositionChanged(object? sender, WindowPoint e)
    {
        _pendingPosition = e;
        _saveTimer.Stop();
        _saveTimer.Start();
    }

    private void OnMiniWindowRestoreRequested(object? sender, EventArgs e)
    {
        RestoreMainWindow();
    }

    private async Task SaveMiniWindowPositionAsync()
    {
        if (_pendingPosition == null)
        {
            return;
        }

        _settings.MiniWindowPosition = _pendingPosition;
        await _settingsStore.SaveAsync(_settings);
    }

    private void RestoreMainWindow()
    {
        _mainWindow.Show();
        _mainWindow.WindowState = WindowState.Normal;
        _mainWindow.Activate();
        _mainWindow.Focus();
        CloseMiniWindow();
    }

    private void ExitApplication()
    {
        _exitRequested = true;
        CloseMiniWindow();
        DisposeTrayIcon();
        _mainWindow.Close();
        Application.Current.Shutdown();
    }

    private void CloseMiniWindow()
    {
        if (_miniWindow == null)
        {
            return;
        }

        _miniWindow.PositionChanged -= OnMiniWindowPositionChanged;
        _miniWindow.RestoreRequested -= OnMiniWindowRestoreRequested;
        _miniWindow.Close();
        _miniWindow = null;
    }

    private void DisposeTrayIcon()
    {
        if (_trayIcon == null)
        {
            return;
        }

        _trayIcon.Dispose();
        _trayIcon = null;
    }
}
