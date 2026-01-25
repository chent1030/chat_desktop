using System.Collections.Specialized;
using System.ComponentModel;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Threading;
using ChatDesktop.App.ViewModels;
using ChatDesktop.App.Views;
using ChatDesktop.Infrastructure.Config;
using Markdig;
using System.Linq;

namespace ChatDesktop.App;

/// <summary>
/// 主窗口
/// </summary>
public partial class MainWindow : Window
{
    private INotifyCollectionChanged? _chatMessages;
    private bool _chatRenderPending;
    private bool _chatNeedsScroll;
    private readonly DispatcherTimer _chatRenderTimer = new();
    private readonly MarkdownPipeline _markdownPipeline = new MarkdownPipelineBuilder().UseAdvancedExtensions().Build();

    public MainWindow()
    {
        InitializeComponent();
        _chatRenderTimer.Interval = TimeSpan.FromMilliseconds(200);
        _chatRenderTimer.Tick += (_, _) =>
        {
            _chatRenderTimer.Stop();
            _chatRenderPending = false;
            RenderChatHtml();
        };
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

        InitializeChatWebView(mainViewModel);
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

    private async void InitializeChatWebView(MainViewModel viewModel)
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

        foreach (var message in viewModel.Chat.Messages)
        {
            message.PropertyChanged += OnChatMessagePropertyChanged;
        }

        ChatWebView.NavigationCompleted -= OnChatWebNavigationCompleted;
        ChatWebView.NavigationCompleted += OnChatWebNavigationCompleted;

        await ChatWebView.EnsureCoreWebView2Async();
        RenderChatHtml();
    }

    private void OnChatMessagesChanged(object? sender, NotifyCollectionChangedEventArgs e)
    {
        if (e.NewItems != null)
        {
            foreach (var item in e.NewItems.OfType<ChatMessageViewModel>())
            {
                item.PropertyChanged += OnChatMessagePropertyChanged;
            }
        }

        if (e.OldItems != null)
        {
            foreach (var item in e.OldItems.OfType<ChatMessageViewModel>())
            {
                item.PropertyChanged -= OnChatMessagePropertyChanged;
            }
        }

        ScheduleChatRender();
    }

    private void OnChatMessagePropertyChanged(object? sender, PropertyChangedEventArgs e)
    {
        if (e.PropertyName == nameof(ChatMessageViewModel.Content))
        {
            ScheduleChatRender();
        }
    }

    private void ScheduleChatRender()
    {
        _chatNeedsScroll = true;
        if (_chatRenderPending)
        {
            return;
        }

        _chatRenderPending = true;
        _chatRenderTimer.Stop();
        _chatRenderTimer.Start();
    }

    private void RenderChatHtml()
    {
        if (DataContext is not MainViewModel viewModel)
        {
            return;
        }

        var sb = new StringBuilder();
        sb.Append("<!doctype html><html><head><meta charset=\"utf-8\" />");
        sb.Append("<style>");
        sb.Append("body{font-family:'Segoe UI',sans-serif;background:#F4F6FA;margin:0;padding:12px;}");
        sb.Append(".msg{display:flex;margin:10px 0;}");
        sb.Append(".bubble{max-width:560px;padding:10px 12px;border-radius:12px;border:1px solid #E5E8F0;background:#fff;}");
        sb.Append(".user{justify-content:flex-end;}");
        sb.Append(".user .bubble{background:#E3F2FD;border-color:#BBDEFB;}");
        sb.Append(".role{font-size:11px;color:#8A9099;margin-bottom:6px;}");
        sb.Append("</style></head><body>");

        foreach (var message in viewModel.Chat.Messages)
        {
            var css = message.IsUser ? "msg user" : "msg";
            var markdown = message.Content ?? string.Empty;
            var html = Markdown.ToHtml(markdown, _markdownPipeline);
            sb.Append($"<div class=\"{css}\"><div class=\"bubble\"><div class=\"role\">{message.RoleLabel}</div>{html}</div></div>");
        }

        sb.Append("</body></html>");
        _chatNeedsScroll = true;
        ChatWebView.NavigateToString(sb.ToString());
    }

    private async void OnChatWebNavigationCompleted(object? sender, Microsoft.Web.WebView2.Core.CoreWebView2NavigationCompletedEventArgs e)
    {
        if (!_chatNeedsScroll)
        {
            return;
        }

        _chatNeedsScroll = false;
        try
        {
            await ChatWebView.ExecuteScriptAsync("window.scrollTo(0, document.body.scrollHeight);");
        }
        catch
        {
        }
    }
}
