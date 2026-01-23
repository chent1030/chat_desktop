using System.IO;
using System.Windows;
using ChatDesktop.App.ViewModels;
using ChatDesktop.Core.Services;
using ChatDesktop.Infrastructure.Config;
using ChatDesktop.Infrastructure.Data;
using ChatDesktop.Infrastructure.Paths;
using ChatDesktop.Infrastructure.Unify;
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

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        EnvConfig.Load();

        var connectionFactory = new SqliteConnectionFactory(AppPaths.DatabasePath);
        var schemaPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Schema.sql");
        var schemaInitializer = new SchemaInitializer(connectionFactory, schemaPath);
        _ = schemaInitializer.InitializeAsync();

        var settingsStore = new LocalSettingsStore();
        var settingsService = new AppSettingsService(settingsStore);
        var settings = settingsService.LoadAsync().GetAwaiter().GetResult();
        var empNo = settings.EmpNo ?? string.Empty;

        var remoteService = new UnifyTaskApiService();
        var taskRepository = new TaskRepository(connectionFactory);
        var taskActionRepository = new TaskActionRepository(connectionFactory);
        var taskService = new TaskService(taskRepository, taskActionRepository, remoteService);
        _taskService = taskService;

        var conversationRepository = new ConversationRepository(connectionFactory);
        var messageRepository = new MessageRepository(connectionFactory);
        var conversationService = new ConversationService(conversationRepository, messageRepository);

        var window = new MainWindow();

        while (string.IsNullOrWhiteSpace(empNo))
        {
            var empVm = new EmpNoViewModel(remoteService, settingsStore);
            var empWindow = new EmpNoWindow(empVm)
            {
                Owner = window
            };
            empWindow.ShowDialog();
            settings = settingsService.LoadAsync().GetAwaiter().GetResult();
            empNo = settings.EmpNo ?? string.Empty;
        }

        var viewModel = MainViewModel.CreateDefault(taskService, remoteService, empNo, conversationService);
        _mainViewModel = viewModel;
        window.DataContext = viewModel;
        window.Show();
        _ = viewModel.TaskList.LoadAsync();
        _ = viewModel.Chat.LoadConversationsAsync();
        _ = InitializeMqttAsync(empNo);
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
                await _mqttService.DisconnectAsync();
            }

            var mqttService = new Infrastructure.Mqtt.MqttService(_taskService);
            mqttService.TaskChanged += OnMqttTaskChanged;
            _mqttService = mqttService;

            await mqttService.ConnectAsync(
                EnvConfig.MqttBrokerHost,
                EnvConfig.MqttBrokerPort,
                empNo,
                EnvConfig.MqttUsername,
                EnvConfig.MqttPassword);
        }).Task;
    }

    private void OnMqttTaskChanged()
    {
        if (_mainViewModel == null)
        {
            return;
        }

        Dispatcher.InvokeAsync(() => _ = _mainViewModel.TaskList.LoadAsync());
    }
}
