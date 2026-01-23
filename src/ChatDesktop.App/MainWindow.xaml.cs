using System.Windows;
using ChatDesktop.App.ViewModels;
using ChatDesktop.App.Views;
using ChatDesktop.Infrastructure.Config;

namespace ChatDesktop.App;

/// <summary>
/// 主窗口
/// </summary>
public partial class MainWindow : Window
{
    public MainWindow()
    {
        InitializeComponent();
    }

    private void OnLoaded(object sender, RoutedEventArgs e)
    {
        if (DataContext is not MainViewModel mainViewModel)
        {
            return;
        }

        mainViewModel.TaskList.DetailRequested -= OnTaskDetailRequested;
        mainViewModel.TaskList.DetailRequested += OnTaskDetailRequested;

        mainViewModel.TaskList.VoiceCreateRequested -= OnVoiceCreateRequested;
        mainViewModel.TaskList.VoiceCreateRequested += OnVoiceCreateRequested;

        mainViewModel.TaskList.CreateRequested -= OnTaskCreateRequested;
        mainViewModel.TaskList.CreateRequested += OnTaskCreateRequested;

        mainViewModel.TaskList.PagedRequested -= OnPagedTaskRequested;
        mainViewModel.TaskList.PagedRequested += OnPagedTaskRequested;

        mainViewModel.TaskList.EditRequested -= OnTaskEditRequested;
        mainViewModel.TaskList.EditRequested += OnTaskEditRequested;

        mainViewModel.TaskList.ClearCompletedRequested -= OnClearCompletedRequested;
        mainViewModel.TaskList.ClearCompletedRequested += OnClearCompletedRequested;

        mainViewModel.TaskList.ChangeEmpNoRequested -= OnChangeEmpNoRequested;
        mainViewModel.TaskList.ChangeEmpNoRequested += OnChangeEmpNoRequested;
    }

    private void OnTaskDetailRequested(Core.Models.TaskItem task)
    {
        if (DataContext is not MainViewModel mainViewModel)
        {
            return;
        }

        var detailVm = new TaskDetailViewModel(task, mainViewModel.TaskListService);
        var window = new TaskDetailWindow(detailVm, mainViewModel.TaskRemoteService, mainViewModel.CurrentEmpNo, () =>
        {
            _ = mainViewModel.TaskList.LoadAsync();
        })
        {
            Owner = this
        };
        window.ShowDialog();
    }

    private void OnVoiceCreateRequested()
    {
        if (DataContext is not MainViewModel mainViewModel)
        {
            return;
        }

        var recorder = new Infrastructure.Voice.AudioRecorderService();
        var speechService = new Infrastructure.Voice.SpeechToTextService();
        var extractor = new Core.Services.Voice.TaskVoiceExtractionService();
        var workflowService = new Core.Services.AI.AiWorkflowService(new Infrastructure.Http.SseClient());
        var configService = new Core.Services.AI.AiConfigService();
        var vm = new VoiceTaskViewModel(
            recorder,
            speechService,
            mainViewModel.TaskListService,
            extractor,
            workflowService,
            configService,
            mainViewModel.TaskRemoteService,
            mainViewModel.CurrentEmpNo);
        var window = new VoiceTaskWindow(vm)
        {
            Owner = this
        };
        window.ShowDialog();
        _ = mainViewModel.TaskList.LoadAsync();
    }

    private void OnTaskCreateRequested()
    {
        if (DataContext is not MainViewModel mainViewModel)
        {
            return;
        }

        var vm = new TaskFormViewModel(mainViewModel.TaskListService, mainViewModel.TaskRemoteService, mainViewModel.CurrentEmpNo, null);
        var window = new TaskFormWindow(vm)
        {
            Owner = this
        };
        window.ShowDialog();
        _ = mainViewModel.TaskList.LoadAsync();
    }

    private void OnTaskEditRequested(Core.Models.TaskItem task)
    {
        if (DataContext is not MainViewModel mainViewModel)
        {
            return;
        }

        var vm = new TaskFormViewModel(mainViewModel.TaskListService, mainViewModel.TaskRemoteService, mainViewModel.CurrentEmpNo, task.Id);
        var window = new TaskFormWindow(vm)
        {
            Owner = this
        };
        window.ShowDialog();
        _ = mainViewModel.TaskList.LoadAsync();
    }

    private void OnPagedTaskRequested()
    {
        if (DataContext is not MainViewModel mainViewModel)
        {
            return;
        }

        var vm = new UnifyTaskListViewModel(mainViewModel.TaskRemoteService, mainViewModel.CurrentEmpNo);
        var window = new UnifyTaskListWindow(vm)
        {
            Owner = this
        };
        window.ShowDialog();
    }

    private async void OnClearCompletedRequested()
    {
        if (DataContext is not MainViewModel mainViewModel)
        {
            return;
        }

        var result = MessageBox.Show(
            "确定要清除所有已完成的任务吗？此操作无法撤销。",
            "确认清除",
            MessageBoxButton.YesNo,
            MessageBoxImage.Warning);

        if (result != MessageBoxResult.Yes)
        {
            return;
        }

        await mainViewModel.TaskList.ClearCompletedAsync();
        MessageBox.Show("已清除所有已完成任务", "完成", MessageBoxButton.OK, MessageBoxImage.Information);
    }

    private void OnChangeEmpNoRequested()
    {
        if (DataContext is not MainViewModel mainViewModel)
        {
            return;
        }

        var store = new LocalSettingsStore();
        var viewModel = new EmpNoViewModel(mainViewModel.TaskRemoteService, store);
        var window = new EmpNoWindow(viewModel)
        {
            Owner = this
        };
        window.ShowDialog();

        var settings = new AppSettingsService(store).LoadAsync().GetAwaiter().GetResult();
        if (!string.IsNullOrWhiteSpace(settings.EmpNo))
        {
            mainViewModel.CurrentEmpNo = settings.EmpNo;
            if (Application.Current is App app)
            {
                _ = app.InitializeMqttAsync(settings.EmpNo);
            }
        }
    }
}
