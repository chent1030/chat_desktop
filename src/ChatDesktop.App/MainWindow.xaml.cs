using System.Collections.Specialized;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using ChatDesktop.App.ViewModels;
using ChatDesktop.App.Views;
using ChatDesktop.Infrastructure.Config;

namespace ChatDesktop.App;

/// <summary>
/// 主窗口
/// </summary>
public partial class MainWindow : Window
{
    private INotifyCollectionChanged? _chatMessages;
    private ScrollViewer? _chatScrollViewer;

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

        AttachChatAutoScroll(mainViewModel);
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

    private void OnTaskItemClicked(object sender, MouseButtonEventArgs e)
    {
        if (IsClickFromCheckBox(e.OriginalSource as DependencyObject))
        {
            return;
        }

        if (sender is not Border border || border.DataContext is not Core.Models.TaskItem task)
        {
            return;
        }

        if (DataContext is not MainViewModel mainViewModel)
        {
            return;
        }

        mainViewModel.TaskList.OpenDetailCommand.Execute(task);
    }

    private void OnConversationMenuClicked(object sender, RoutedEventArgs e)
    {
        if (sender is not Button button || button.ContextMenu == null)
        {
            return;
        }

        button.ContextMenu.PlacementTarget = button;
        button.ContextMenu.IsOpen = true;
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
        var workflowService = new Infrastructure.AI.AiWorkflowService(new Infrastructure.Http.SseClient());
        var configService = new Infrastructure.AI.AiConfigService();
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

    private static bool IsClickFromCheckBox(DependencyObject? source)
    {
        while (source != null)
        {
            if (source is CheckBox)
            {
                return true;
            }

            source = VisualTreeHelper.GetParent(source);
        }

        return false;
    }

    private void AttachChatAutoScroll(MainViewModel viewModel)
    {
        if (_chatMessages != null)
        {
            _chatMessages.CollectionChanged -= OnChatMessagesChanged;
        }

        if (viewModel.Chat.Messages is INotifyCollectionChanged messages)
        {
            _chatMessages = messages;
            messages.CollectionChanged += OnChatMessagesChanged;
        }

        _chatScrollViewer = FindDescendantScrollViewer(ChatListBox);
    }

    private void OnChatMessagesChanged(object? sender, NotifyCollectionChangedEventArgs e)
    {
        if (ChatListBox.Items.Count == 0)
        {
            return;
        }

        if (_chatScrollViewer != null)
        {
            var nearBottom = _chatScrollViewer.VerticalOffset >= _chatScrollViewer.ScrollableHeight - 40;
            if (!nearBottom)
            {
                return;
            }
        }

        var last = ChatListBox.Items[ChatListBox.Items.Count - 1];
        ChatListBox.ScrollIntoView(last);
    }

    private static ScrollViewer? FindDescendantScrollViewer(DependencyObject? root)
    {
        if (root == null)
        {
            return null;
        }

        if (root is ScrollViewer viewer)
        {
            return viewer;
        }

        var count = VisualTreeHelper.GetChildrenCount(root);
        for (var i = 0; i < count; i++)
        {
            var child = VisualTreeHelper.GetChild(root, i);
            var result = FindDescendantScrollViewer(child);
            if (result != null)
            {
                return result;
            }
        }

        return null;
    }
}
