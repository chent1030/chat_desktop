using System.Collections.Specialized;
using System.ComponentModel;
using System.IO;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Threading;
using ChatDesktop.App.Services;
using ChatDesktop.App.ViewModels;
using ChatDesktop.App.Views;
using ChatDesktop.Core.Enums;
using ChatDesktop.Infrastructure.Config;
using Microsoft.Web.WebView2.Core;
using Markdig;
using System.Linq;

namespace ChatDesktop.App;

/// <summary>
/// 主窗口
/// </summary>
public partial class MainWindow : Window
{
    private INotifyCollectionChanged? _chatMessages;
    private readonly DispatcherTimer _chatUpdateTimer = new();
    private readonly HashSet<int> _pendingUpdateIds = new();
    private bool _chatPendingFullRender;
    private bool _chatReady;
    private readonly MarkdownPipeline _markdownPipeline = new MarkdownPipelineBuilder().UseAdvancedExtensions().Build();
    private static readonly Regex ThinkingRegex = new(
        "<think(?:ing)?>(.*?)</think(?:ing)?>",
        RegexOptions.Singleline | RegexOptions.IgnoreCase);

    public MainWindow()
    {
        InitializeComponent();
        _chatUpdateTimer.Interval = TimeSpan.FromMilliseconds(120);
        _chatUpdateTimer.Tick += (_, _) =>
        {
            _chatUpdateTimer.Stop();
            FlushChatUpdates();
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

        if (Application.Current is App app)
        {
            app.FontChanged -= OnAppFontChanged;
            app.FontChanged += OnAppFontChanged;
        }

        InitializeChatWebView(mainViewModel);
    }

    protected override void OnClosed(EventArgs e)
    {
        if (Application.Current is App app)
        {
            app.FontChanged -= OnAppFontChanged;
        }

        base.OnClosed(e);
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

        button.ContextMenu.DataContext = button.DataContext;
        button.ContextMenu.PlacementTarget = button;
        button.ContextMenu.IsOpen = true;
    }

    private void OnMoreMenuOpened(object sender, RoutedEventArgs e)
    {
        if (FontMenuItem == null)
        {
            return;
        }

        BuildFontMenu(FontMenuItem);
    }

    private static void BuildFontMenu(MenuItem menuItem)
    {
        menuItem.Items.Clear();
        var currentKey = GetCurrentFontKey();

        foreach (var option in AppFontService.Options)
        {
            var item = new MenuItem
            {
                Tag = option.Key,
                IsCheckable = true,
                IsChecked = string.Equals(option.Key, currentKey, StringComparison.OrdinalIgnoreCase),
            };

            var header = new TextBlock { Text = option.Label };
            if (!string.IsNullOrWhiteSpace(option.FamilyName))
            {
                header.FontFamily = AppFontService.GetFontFamily(option.Key);
            }

            item.Header = header;
            item.Click += OnFontMenuItemClicked;
            menuItem.Items.Add(item);
        }
    }

    private static async void OnFontMenuItemClicked(object sender, RoutedEventArgs e)
    {
        if (sender is not MenuItem item || item.Tag is not string key)
        {
            return;
        }

        if (Application.Current is App app)
        {
            await app.SetFontKeyAsync(key);
        }
    }

    private static string GetCurrentFontKey()
    {
        return Application.Current is App app
            ? app.CurrentFontKey
            : AppFontService.DefaultKey;
    }

    private void OnChatInputKeyDown(object sender, KeyEventArgs e)
    {
        if (e.Key != Key.Enter)
        {
            return;
        }

        if (Keyboard.Modifiers.HasFlag(ModifierKeys.Shift))
        {
            return;
        }

        if (DataContext is not MainViewModel mainViewModel)
        {
            return;
        }

        if (mainViewModel.Chat.SendCommand.CanExecute(null))
        {
            mainViewModel.Chat.SendCommand.Execute(null);
            e.Handled = true;
        }
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
        var assetsPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Assets");
        if (Directory.Exists(assetsPath) && ChatWebView.CoreWebView2 != null)
        {
            ChatWebView.CoreWebView2.SetVirtualHostNameToFolderMapping(
                "appassets",
                assetsPath,
                CoreWebView2HostResourceAccessKind.Allow);
        }
        InitializeChatHtml();
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

        if (e.Action == NotifyCollectionChangedAction.Reset)
        {
            _chatPendingFullRender = true;
        }
        else if (e.NewItems != null)
        {
            foreach (var item in e.NewItems.OfType<ChatMessageViewModel>())
            {
                _pendingUpdateIds.Add(item.Id);
            }
        }
        else
        {
            _chatPendingFullRender = true;
        }

        ScheduleChatUpdate();
    }

    private void OnChatMessagePropertyChanged(object? sender, PropertyChangedEventArgs e)
    {
        if (e.PropertyName == nameof(ChatMessageViewModel.Content))
        {
            if (sender is ChatMessageViewModel message)
            {
                _pendingUpdateIds.Add(message.Id);
            }
            ScheduleChatUpdate();
        }
    }

    private void ScheduleChatUpdate()
    {
        if (!_chatReady)
        {
            return;
        }

        _chatUpdateTimer.Stop();
        _chatUpdateTimer.Start();
    }

    private void FlushChatUpdates()
    {
        if (!_chatReady)
        {
            return;
        }

        if (_chatPendingFullRender)
        {
            _chatPendingFullRender = false;
            RenderChatAll();
            return;
        }

        if (DataContext is not MainViewModel viewModel)
        {
            return;
        }

        if (_pendingUpdateIds.Count == 0)
        {
            return;
        }

        var ids = _pendingUpdateIds.ToArray();
        _pendingUpdateIds.Clear();

        foreach (var id in ids)
        {
            var message = viewModel.Chat.Messages.FirstOrDefault(m => m.Id == id);
            if (message == null)
            {
                continue;
            }

            var html = BuildMessageHtml(message);
            ExecuteChatScript("window.updateMessage", message.Id, html, message.IsUser);
        }
    }

    private void InitializeChatHtml()
    {
        var html = BuildChatShellHtml();
        _chatReady = false;
        ChatWebView.NavigateToString(html);
    }

    private async void OnChatWebNavigationCompleted(object? sender, Microsoft.Web.WebView2.Core.CoreWebView2NavigationCompletedEventArgs e)
    {
        _chatReady = true;
        RenderChatAll();
        await ScrollChatToBottom();
    }

    private void RenderChatAll()
    {
        if (DataContext is not MainViewModel viewModel)
        {
            return;
        }

        ExecuteChatScriptRaw("window.clearMessages();");
        foreach (var message in viewModel.Chat.Messages)
        {
            var html = BuildMessageHtml(message);
            ExecuteChatScript("window.appendMessage", message.Id, html, message.IsUser);
        }
    }

    private string BuildChatShellHtml()
    {
        var sb = new StringBuilder();
        sb.Append("<!doctype html><html><head><meta charset=\"utf-8\" />");
        sb.Append("<style>");
        sb.Append(BuildChatFontCss());
        sb.Append("background:#F4F6FA;margin:0;padding:12px;");
        sb.Append("scrollbar-width:thin;scrollbar-color:#C2C9D6 transparent;}");
        sb.Append("body::-webkit-scrollbar{width:10px;}");
        sb.Append("body::-webkit-scrollbar-track{background:transparent;}");
        sb.Append("body::-webkit-scrollbar-thumb{background:#C2C9D6;border-radius:8px;border:2px solid transparent;background-clip:content-box;}");
        sb.Append("body::-webkit-scrollbar-thumb:hover{background:#9AA3B2;background-clip:content-box;}");
        sb.Append(".msg{display:flex;margin:10px 0;}");
        sb.Append(".bubble{max-width:560px;padding:10px 12px;border-radius:12px;border:1px solid #E5E8F0;background:#fff;}");
        sb.Append(".user{justify-content:flex-end;}");
        sb.Append(".user .bubble{background:#E3F2FD;border-color:#BBDEFB;}");
        sb.Append(".role{font-size:11px;color:#8A9099;margin-bottom:6px;}");
        sb.Append(".thinking{background:#F5F7FB;border:1px solid #E3E8F3;border-radius:8px;margin-bottom:10px;}");
        sb.Append(".thinking summary{cursor:pointer;padding:6px 8px;color:#5C6BC0;font-weight:600;}");
        sb.Append(".thinking-body{padding:8px 10px;color:#4B5563;font-style:italic;white-space:pre-wrap;}");
        sb.Append(".divider{height:1px;background:#E5E7EB;margin:8px 0;}");
        sb.Append(".loading{color:#9CA3AF;font-style:italic;}");
        sb.Append("</style></head><body>");
        sb.Append("<div id=\"chat\"></div>");
        sb.Append("<script>");
        sb.Append("function isNearBottom(){return (window.innerHeight+window.scrollY)>=(document.body.scrollHeight-80);}");
        sb.Append("function scrollBottom(){window.scrollTo(0, document.body.scrollHeight);}");
        sb.Append("window.clearMessages=function(){document.getElementById('chat').innerHTML='';};");
        sb.Append("window.appendMessage=function(id, html, isUser){");
        sb.Append("var c=document.getElementById('chat');var near=isNearBottom();");
        sb.Append("var wrap=document.createElement('div');wrap.className='msg'+(isUser?' user':'');wrap.id='msg-'+id;");
        sb.Append("wrap.innerHTML=html;c.appendChild(wrap);if(near){scrollBottom();}};");
        sb.Append("window.updateMessage=function(id, html, isUser){");
        sb.Append("var el=document.getElementById('msg-'+id);var near=isNearBottom();");
        sb.Append("if(!el){window.appendMessage(id, html, isUser);return;}");
        sb.Append("el.className='msg'+(isUser?' user':'');el.innerHTML=html;if(near){scrollBottom();}};");
        sb.Append("</script>");
        sb.Append("</body></html>");
        return sb.ToString();
    }

    private static string BuildChatFontCss()
    {
        var key = GetCurrentFontKey();
        var option = AppFontService.GetOption(key);
        var familyName = string.IsNullOrWhiteSpace(option.FamilyName) ? "Segoe UI" : option.FamilyName;
        var sb = new StringBuilder();
        var fontFileName = AppFontService.GetFontFileName(key);
        var fontPath = AppFontService.GetFontFilePath(key);
        if (!string.IsNullOrWhiteSpace(fontFileName) && !string.IsNullOrWhiteSpace(fontPath))
        {
            sb.Append("@font-face{font-family:'");
            sb.Append(familyName);
            sb.Append("';src:url('");
            sb.Append("https://appassets/Fonts/");
            sb.Append(fontFileName);
            sb.Append("');font-weight:normal;font-style:normal;}");
        }

        sb.Append("body{font-family:'");
        sb.Append(familyName);
        sb.Append("',Segoe UI,sans-serif;");
        return sb.ToString();
    }

    private void OnAppFontChanged(object? sender, EventArgs e)
    {
        if (!IsLoaded)
        {
            return;
        }

        InitializeChatHtml();
    }

    private string BuildMessageHtml(ChatMessageViewModel message)
    {
        var content = message.Content ?? string.Empty;
        var thinkingMatch = ThinkingRegex.Match(content);
        string? thinking = null;
        if (thinkingMatch.Success)
        {
            thinking = thinkingMatch.Groups[1].Value.Trim();
            content = ThinkingRegex.Replace(content, string.Empty).Trim();
        }

        var sb = new StringBuilder();
        sb.Append("<div class=\"bubble\">");
        sb.Append($"<div class=\"role\">{HtmlEncode(message.RoleLabel)}</div>");

        if (!string.IsNullOrWhiteSpace(thinking))
        {
            var thinkingHtml = HtmlEncode(thinking).Replace("\n", "<br/>");
            sb.Append("<details class=\"thinking\"><summary>思维链</summary>");
            sb.Append($"<div class=\"thinking-body\">{thinkingHtml}</div></details>");
            sb.Append("<div class=\"divider\"></div>");
        }

        if (message.Role == MessageRole.Assistant)
        {
            if (message.Status == MessageStatus.Streaming && string.IsNullOrWhiteSpace(content))
            {
                sb.Append("<div class=\"loading\">正在思考...</div>");
            }
            else
            {
                var html = Markdown.ToHtml(content, _markdownPipeline);
                sb.Append(html);
            }
        }
        else
        {
            var html = HtmlEncode(content).Replace("\n", "<br/>");
            sb.Append($"<div>{html}</div>");
        }

        sb.Append("</div>");
        return sb.ToString();
    }

    private void ExecuteChatScript(string functionName, int id, string html, bool isUser)
    {
        var htmlArg = JsonSerializer.Serialize(html);
        var script = $"{functionName}({id},{htmlArg},{isUser.ToString().ToLowerInvariant()});";
        ExecuteChatScriptRaw(script);
    }

    private void ExecuteChatScriptRaw(string script)
    {
        if (!_chatReady)
        {
            return;
        }

        try
        {
            _ = ChatWebView.ExecuteScriptAsync(script);
        }
        catch
        {
        }
    }

    private async Task ScrollChatToBottom()
    {
        try
        {
            await ChatWebView.ExecuteScriptAsync("window.scrollTo(0, document.body.scrollHeight);");
        }
        catch
        {
        }
    }

    private static string HtmlEncode(string input)
    {
        return System.Net.WebUtility.HtmlEncode(input);
    }
}
