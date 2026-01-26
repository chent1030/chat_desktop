using System.IO;
using System.Windows;
using ChatDesktop.App.ViewModels;
using ChatDesktop.Core.Services;
using ChatDesktop.Infrastructure.Config;
using ChatDesktop.Infrastructure.Data;
using ChatDesktop.Infrastructure.Paths;
using ChatDesktop.Infrastructure.Unify;
using ChatDesktop.App.Services;
using ChatDesktop.Core.Models;
using ChatDesktop.App.Views;

namespace ChatDesktop.App;

/// <summary>
/// 应用入口
/// </summary>
public partial class App : Application
{
    private Infrastructure.Mqtt.MqttService? _mqttService;
    private TaskService? _taskService;
    private MainViewModel? _mainViewModel;
    private MiniWindowManager? _miniWindowManager;
    private LocalSettingsStore? _settingsStore;
    private AppSettings? _appSettings;

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);
        ShutdownMode = ShutdownMode.OnExplicitShutdown;

        try
        {
            var connectionFactory = new SqliteConnectionFactory(AppPaths.DatabasePath);
            var schemaPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Schema.sql");
            var schemaInitializer = new SchemaInitializer(connectionFactory, schemaPath);
            schemaInitializer.InitializeAsync().GetAwaiter().GetResult();

            var settingsStore = new LocalSettingsStore();
            _settingsStore = settingsStore;
            var settingsService = new AppSettingsService(settingsStore);
            var settings = settingsService.LoadAsync().GetAwaiter().GetResult();
            _appSettings = settings;
            EnvConfig.Load(settings);
            ApplyFontFromSettings();
            var empNo = settings.EmpNo ?? string.Empty;

            var remoteService = new UnifyTaskApiService();
            var taskRepository = new TaskRepository(connectionFactory);
            var taskActionRepository = new TaskActionRepository(connectionFactory);
            var taskService = new TaskService(taskRepository, taskActionRepository, remoteService);
            _taskService = taskService;

            var conversationRepository = new ConversationRepository(connectionFactory);
            var messageRepository = new MessageRepository(connectionFactory);
            var conversationService = new ConversationService(conversationRepository, messageRepository);

            while (string.IsNullOrWhiteSpace(empNo))
            {
                var empVm = new EmpNoViewModel(remoteService, settingsStore);
                var empWindow = new EmpNoWindow(empVm)
                {
                    Owner = null,
                    WindowStartupLocation = WindowStartupLocation.CenterScreen,
                    Topmost = true,
                    ShowInTaskbar = true
                };
                empWindow.ShowDialog();
                settings = settingsService.LoadAsync().GetAwaiter().GetResult();
                empNo = settings.EmpNo ?? string.Empty;
                EnvConfig.Load(settings);
            }
            _appSettings = settings;

            var window = new MainWindow
            {
                WindowStartupLocation = WindowStartupLocation.CenterScreen
            };
            MainWindow = window;
            var viewModel = MainViewModel.CreateDefault(taskService, remoteService, empNo, conversationService);
            _mainViewModel = viewModel;
            window.DataContext = viewModel;
            window.Show();
            window.Activate();
            ShutdownMode = ShutdownMode.OnMainWindowClose;
            if (_settingsStore != null && _appSettings != null)
            {
                _miniWindowManager = new MiniWindowManager(window, viewModel, _settingsStore, _appSettings);
                _miniWindowManager.Initialize();
            }
            _ = viewModel.TaskList.LoadAsync();
            _ = viewModel.Chat.LoadConversationsAsync();
            _ = InitializeMqttAsync(empNo);
        }
        catch (Exception ex)
        {
            MessageBox.Show($"启动失败：{ex}", "错误", MessageBoxButton.OK, MessageBoxImage.Error);
            Shutdown();
        }
    }

    public Task InitializeMqttAsync(string empNo)
    {
        if (string.IsNullOrWhiteSpace(empNo) || _taskService == null)
        {
            return Task.CompletedTask;
        }

        return Dispatcher.InvokeAsync(async () =>
        {
            if (_mqttService != null)
            {
                _mqttService.TaskChanged -= OnMqttTaskChanged;
                _mqttService.TaskNotification -= OnMqttTaskNotification;
                await _mqttService.DisconnectAsync();
            }

            var mqttService = new Infrastructure.Mqtt.MqttService(_taskService);
            mqttService.TaskChanged += OnMqttTaskChanged;
            mqttService.TaskNotification += OnMqttTaskNotification;
            _mqttService = mqttService;

            await mqttService.ConnectAsync(
                EnvConfig.MqttBrokerHost,
                EnvConfig.MqttBrokerPort,
                empNo,
                EnvConfig.MqttUsername,
                EnvConfig.MqttPassword);
        }).Task;
    }

    public string CurrentFontKey => AppFontService.NormalizeKey(_appSettings?.FontKey);

    public async Task SetFontKeyAsync(string key)
    {
        if (_settingsStore == null || _appSettings == null)
        {
            return;
        }

        var normalized = AppFontService.NormalizeKey(key);
        _appSettings.FontKey = normalized;
        ApplyFont(normalized);
        await _settingsStore.SaveAsync(_appSettings);
    }

    private void ApplyFontFromSettings()
    {
        var normalized = AppFontService.NormalizeKey(_appSettings?.FontKey);
        ApplyFont(normalized);
    }

    private void ApplyFont(string normalizedKey)
    {
        var fontFamily = AppFontService.GetFontFamily(normalizedKey);
        Resources["AppFontFamily"] = fontFamily;
        Resources["MaterialDesignFont"] = fontFamily;
    }

    private void OnMqttTaskChanged()
    {
        if (_mainViewModel == null)
        {
            return;
        }

        Dispatcher.InvokeAsync(() => _ = _mainViewModel.TaskList.LoadAsync());
    }

    private void OnMqttTaskNotification(string title, string message)
    {
        if (_miniWindowManager == null)
        {
            return;
        }

        Dispatcher.InvokeAsync(() => _miniWindowManager.ShowNotification(title, message));
    }

    protected override void OnExit(ExitEventArgs e)
    {
        _miniWindowManager?.Dispose();
        base.OnExit(e);
    }
}
