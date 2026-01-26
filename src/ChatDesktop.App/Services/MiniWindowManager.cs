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

    public void ShowNotification(string title, string message)
    {
        if (_trayIcon == null)
        {
            return;
        }

        _trayIcon.Dispatcher.InvokeAsync(() =>
        {
            if (_trayIcon == null)
            {
                return;
            }

            var safeTitle = string.IsNullOrWhiteSpace(title) ? "任务提醒" : title;
            var safeMessage = string.IsNullOrWhiteSpace(message) ? "收到任务变更" : message;

            if (TryShowTrayNotification(_trayIcon, safeTitle, safeMessage))
            {
                return;
            }

            _trayIcon.ToolTipText = $"{safeTitle} - {safeMessage}";
        });
    }

    private static bool TryShowTrayNotification(TaskbarIcon trayIcon, string title, string message)
    {
        var trayType = trayIcon.GetType();
        var showNotification = trayType.GetMethod("ShowNotification", new[] { typeof(string), typeof(string) });
        if (showNotification != null)
        {
            showNotification.Invoke(trayIcon, new object?[] { title, message });
            return true;
        }

        var notificationType = trayType.Assembly.GetType("H.NotifyIcon.Notification");
        if (notificationType != null)
        {
            var notification = Activator.CreateInstance(notificationType);
            if (notification != null)
            {
                SetNotificationProperty(notificationType, notification, "Title", title);
                if (!SetNotificationProperty(notificationType, notification, "Message", message))
                {
                    SetNotificationProperty(notificationType, notification, "Text", message);
                }
                SetNotificationIcon(notificationType, notification);

                var showNotificationByType = trayType.GetMethod("ShowNotification", new[] { notificationType });
                if (showNotificationByType != null)
                {
                    showNotificationByType.Invoke(trayIcon, new[] { notification });
                    return true;
                }
            }
        }

        var showBalloon = trayType.GetMethod("ShowBalloonTip", new[] { typeof(string), typeof(string) });
        if (showBalloon != null)
        {
            showBalloon.Invoke(trayIcon, new object?[] { title, message });
            return true;
        }

        foreach (var method in trayType.GetMethods())
        {
            if (!string.Equals(method.Name, "ShowBalloonTip", StringComparison.Ordinal))
            {
                continue;
            }

            var parameters = method.GetParameters();
            if (parameters.Length != 4)
            {
                continue;
            }

            if (parameters[0].ParameterType != typeof(int) ||
                parameters[1].ParameterType != typeof(string) ||
                parameters[2].ParameterType != typeof(string))
            {
                continue;
            }

            var iconValue = GetEnumValue(parameters[3].ParameterType, "Info", "Information", "None");
            if (iconValue == null && parameters[3].ParameterType.IsValueType)
            {
                iconValue = Activator.CreateInstance(parameters[3].ParameterType);
            }

            method.Invoke(trayIcon, new object?[] { 3000, title, message, iconValue });
            return true;
        }

        return false;
    }

    private static bool SetNotificationProperty(Type notificationType, object instance, string name, object? value)
    {
        var property = notificationType.GetProperty(name);
        if (property == null || !property.CanWrite)
        {
            return false;
        }

        property.SetValue(instance, value);
        return true;
    }

    private static void SetNotificationIcon(Type notificationType, object instance)
    {
        var iconProperty = notificationType.GetProperty("Icon");
        if (iconProperty == null || !iconProperty.CanWrite)
        {
            return;
        }

        var iconType = iconProperty.PropertyType;
        if (!iconType.IsEnum)
        {
            return;
        }

        var iconValue = GetEnumValue(iconType, "Info", "Information", "None");
        if (iconValue != null)
        {
            iconProperty.SetValue(instance, iconValue);
        }
    }

    private static object? GetEnumValue(Type enumType, params string[] names)
    {
        var enumNames = Enum.GetNames(enumType);
        foreach (var target in names)
        {
            foreach (var name in enumNames)
            {
                if (string.Equals(name, target, StringComparison.OrdinalIgnoreCase))
                {
                    return Enum.Parse(enumType, name);
                }
            }
        }

        return null;
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
