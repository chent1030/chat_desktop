using System.Collections.ObjectModel;
using System.Linq;
using ChatDesktop.Core.Enums;
using ChatDesktop.Core.Models;
using ChatDesktop.Core.Services;
using ChatDesktop.Infrastructure.AI;
using ChatDesktop.Infrastructure.Logging;
using ChatDesktop.Infrastructure.Paths;
using System.Windows;

namespace ChatDesktop.App.ViewModels;

/// <summary>
/// AI 对话 ViewModel
/// </summary>
public sealed class ChatViewModel : ViewModelBase
{
    private readonly ConversationService _conversationService;
    private readonly AiChatService _aiChatService;
    private readonly AiConfigService _configService;
    private readonly LogService _logService = new();
    private CancellationTokenSource? _chatCts;

    private int? _currentConversationId;
    private string? _backendConversationId;
    private string _inputText = string.Empty;
    private bool _isLoading;
    private bool _isStreaming;
    private string? _error;
    private string? _requestStatus;
    private Conversation? _selectedConversation;
    private string _selectedConversationTitle = string.Empty;
    private string _assistantKey = "xin_service";
    private bool _isEditingTitle;

    public ChatViewModel(
        ConversationService conversationService,
        AiChatService aiChatService,
        AiConfigService configService)
    {
        _conversationService = conversationService;
        _aiChatService = aiChatService;
        _configService = configService;

        Messages = new ObservableCollection<ChatMessageViewModel>();
        Conversations = new ObservableCollection<Conversation>();

        SendCommand = new AsyncRelayCommand(SendAsync, () => !IsStreaming && !IsLoading);
        NewConversationCommand = new AsyncRelayCommand(CreateConversationAsync);
        LoadConversationsCommand = new AsyncRelayCommand(LoadConversationsAsync);
        SaveTitleCommand = new AsyncRelayCommand(SaveTitleAsync, () => SelectedConversation != null);
        DeleteConversationCommand = new AsyncRelayCommand(DeleteConversationAsync, () => SelectedConversation != null);
        SelectConversationCommand = new AsyncRelayCommand<Conversation>(SelectConversationAsync);
        DeleteConversationByIdCommand = new AsyncRelayCommand<Conversation>(DeleteConversationByIdAsync);
        StartEditTitleCommand = new RelayCommand(_ => StartEditTitle(), _ => SelectedConversation != null && !IsEditingTitle);
        FinishEditTitleCommand = new AsyncRelayCommand(FinishEditTitleAsync, () => SelectedConversation != null && IsEditingTitle && !string.IsNullOrWhiteSpace(SelectedConversationTitle));
        CancelEditTitleCommand = new RelayCommand(_ => CancelEditTitle(), _ => SelectedConversation != null && IsEditingTitle);

        AssistantOptions = new List<EnumOption<string>>
        {
            new("xin_service", "芯服务"),
            new("local_qa", "本地问答"),
        };
    }

    public ObservableCollection<ChatMessageViewModel> Messages { get; }
    public ObservableCollection<Conversation> Conversations { get; }
    public IReadOnlyList<EnumOption<string>> AssistantOptions { get; }

    public string InputText
    {
        get => _inputText;
        set
        {
            if (_inputText == value)
            {
                return;
            }

            _inputText = value;
            RaisePropertyChanged();
        }
    }

    public bool IsLoading
    {
        get => _isLoading;
        private set
        {
            _isLoading = value;
            RaisePropertyChanged();
        }
    }

    public bool IsStreaming
    {
        get => _isStreaming;
        private set
        {
            _isStreaming = value;
            RaisePropertyChanged();
        }
    }

    public string? Error
    {
        get => _error;
        private set
        {
            _error = value;
            RaisePropertyChanged();
        }
    }

    public string? RequestStatus
    {
        get => _requestStatus;
        private set
        {
            _requestStatus = value;
            RaisePropertyChanged();
        }
    }

    public Conversation? SelectedConversation
    {
        get => _selectedConversation;
        set
        {
            if (_selectedConversation == value)
            {
                return;
            }

            _selectedConversation = value;
            RaisePropertyChanged();

            _currentConversationId = value?.Id;
            _backendConversationId = null;
            SelectedConversationTitle = value?.Title ?? string.Empty;
            IsEditingTitle = false;
            _ = LoadMessagesAsync();
            SaveTitleCommand.RaiseCanExecuteChanged();
            DeleteConversationCommand.RaiseCanExecuteChanged();
            FinishEditTitleCommand.RaiseCanExecuteChanged();
            CancelEditTitleCommand.RaiseCanExecuteChanged();
            StartEditTitleCommand.RaiseCanExecuteChanged();
            RaisePropertyChanged(nameof(CurrentConversationTitle));
            RaisePropertyChanged(nameof(CurrentConversationSubtitle));
            RaisePropertyChanged(nameof(CurrentConversationId));
            RaisePropertyChanged(nameof(IsViewingTitle));
        }
    }

    public string SelectedConversationTitle
    {
        get => _selectedConversationTitle;
        set
        {
            if (_selectedConversationTitle == value)
            {
                return;
            }

            _selectedConversationTitle = value;
            RaisePropertyChanged();
            FinishEditTitleCommand.RaiseCanExecuteChanged();
        }
    }

    public bool IsEditingTitle
    {
        get => _isEditingTitle;
        private set
        {
            if (_isEditingTitle == value)
            {
                return;
            }

            _isEditingTitle = value;
            RaisePropertyChanged();
            RaisePropertyChanged(nameof(IsViewingTitle));
            StartEditTitleCommand.RaiseCanExecuteChanged();
            FinishEditTitleCommand.RaiseCanExecuteChanged();
            CancelEditTitleCommand.RaiseCanExecuteChanged();
        }
    }

    public bool IsViewingTitle => SelectedConversation != null && !IsEditingTitle;

    public string AssistantKey
    {
        get => _assistantKey;
        set
        {
            if (_assistantKey == value)
            {
                return;
            }

            _assistantKey = value;
            RaisePropertyChanged();
            RaisePropertyChanged(nameof(IsXinServiceSelected));
            RaisePropertyChanged(nameof(IsLocalQaSelected));
        }
    }

    public bool IsXinServiceSelected
    {
        get => AssistantKey == "xin_service";
        set
        {
            if (!value)
            {
                return;
            }

            AssistantKey = "xin_service";
        }
    }

    public bool IsLocalQaSelected
    {
        get => AssistantKey == "local_qa";
        set
        {
            if (!value)
            {
                return;
            }

            AssistantKey = "local_qa";
        }
    }

    public string CurrentConversationTitle
    {
        get
        {
            if (SelectedConversation == null)
            {
                return "新会话";
            }

            return string.IsNullOrWhiteSpace(SelectedConversation.Title)
                ? $"会话 {SelectedConversation.Id}"
                : SelectedConversation.Title;
        }
    }

    public int? CurrentConversationId => _currentConversationId;

    public string? CurrentConversationSubtitle
    {
        get
        {
            if (SelectedConversation == null)
            {
                return null;
            }

            return string.IsNullOrWhiteSpace(SelectedConversation.LastMessageContent)
                ? null
                : SelectedConversation.LastMessageContent;
        }
    }

    public AsyncRelayCommand SendCommand { get; }
    public AsyncRelayCommand NewConversationCommand { get; }
    public AsyncRelayCommand LoadConversationsCommand { get; }
    public AsyncRelayCommand SaveTitleCommand { get; }
    public AsyncRelayCommand DeleteConversationCommand { get; }
    public AsyncRelayCommand<Conversation> SelectConversationCommand { get; }
    public AsyncRelayCommand<Conversation> DeleteConversationByIdCommand { get; }
    public RelayCommand StartEditTitleCommand { get; }
    public AsyncRelayCommand FinishEditTitleCommand { get; }
    public RelayCommand CancelEditTitleCommand { get; }

    public async Task LoadConversationsAsync()
    {
        _logService.Info("开始加载历史会话", "CHAT");
        var list = await _conversationService.GetActiveAsync();
        _logService.Info($"加载历史会话={list.Count}，数据库={AppPaths.DatabasePath}", "CHAT");
        Conversations.Clear();
        foreach (var conversation in list)
        {
            Conversations.Add(conversation);
        }

        if (_currentConversationId != null)
        {
            SelectedConversation = Conversations.FirstOrDefault(c => c.Id == _currentConversationId);
            _logService.Info($"保持当前会话 id={_currentConversationId}", "CHAT");
            return;
        }

        if (SelectedConversation != null && Conversations.All(c => c.Id != SelectedConversation.Id))
        {
            SelectedConversation = null;
            RaisePropertyChanged(nameof(CurrentConversationTitle));
            RaisePropertyChanged(nameof(CurrentConversationSubtitle));
            _logService.Info("当前会话已不存在，清空选择", "CHAT");
        }
    }

    public async Task CreateConversationAsync()
    {
        _logService.Info("开始创建新会话", "CHAT");
        var conversation = new Conversation
        {
            AgentId = "default",
            Title = "新对话",
            CreatedAt = DateTime.Now,
            UpdatedAt = DateTime.Now,
        };

        _currentConversationId = await _conversationService.CreateAsync(conversation);
        _logService.Info($"创建会话 id={_currentConversationId}，数据库={AppPaths.DatabasePath}", "CHAT");
        _backendConversationId = null;
        Messages.Clear();
        await LoadConversationsAsync();
        SelectedConversation = Conversations.FirstOrDefault(c => c.Id == _currentConversationId);
        _logService.Info($"创建完成，当前会话 id={_currentConversationId}", "CHAT");
    }

    public async Task SendAsync()
    {
        if (string.IsNullOrWhiteSpace(InputText))
        {
            return;
        }

        try
        {
            _logService.Info("开始发送消息", "CHAT");
            IsLoading = true;
            Error = null;
            RequestStatus = "请求已发送";

            if (_currentConversationId == null)
            {
                await CreateConversationAsync();
            }

            var content = InputText.Trim();
            InputText = string.Empty;
            _logService.Info($"开始请求 AI，对话={_currentConversationId}，助手={AssistantKey}，内容长度={content.Length}", "CHAT");

            var userMessage = new Message
            {
                ConversationId = _currentConversationId!.Value,
                AgentId = "default",
                Role = MessageRole.User,
                Content = content,
                Status = MessageStatus.Sent,
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now,
            };

            var userMessageId = await _conversationService.AddMessageAsync(userMessage);
            _logService.Info($"保存用户消息 id={userMessageId}，会话={_currentConversationId}", "CHAT");
            var userVm = new ChatMessageViewModel(userMessageId, userMessage.Role, userMessage.Content, userMessage.Status);
            Messages.Add(userVm);
            await TryApplyTitleFromFirstMessageAsync(content);

            var assistantMessage = new Message
            {
                ConversationId = _currentConversationId.Value,
                AgentId = "default",
                Role = MessageRole.Assistant,
                Content = string.Empty,
                Status = MessageStatus.Streaming,
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now,
            };

            var assistantMessageId = await _conversationService.AddMessageAsync(assistantMessage);
            _logService.Info($"保存助手消息 id={assistantMessageId}，会话={_currentConversationId}", "CHAT");
            assistantMessage.Id = assistantMessageId;
            var assistantVm = new ChatMessageViewModel(assistantMessageId, assistantMessage.Role, assistantMessage.Content, assistantMessage.Status);
            Messages.Add(assistantVm);

            IsStreaming = true;

            var config = _configService.GetChatConfig(AssistantKey);
            var hasResponse = false;
            _chatCts?.Cancel();
            _chatCts?.Dispose();
            _chatCts = new CancellationTokenSource(TimeSpan.FromSeconds(120));
            var token = _chatCts.Token;
            var dispatcher = Application.Current?.Dispatcher;
            var lastFlush = DateTime.UtcNow;
            var pendingText = string.Empty;
            var chunkCount = 0;
            await Task.Run(async () =>
            {
                await foreach (var response in _aiChatService.SendStreamingAsync(
                                   config,
                                   content,
                                   _backendConversationId,
                                   "unknown",
                                   token))
                {
                    token.ThrowIfCancellationRequested();
                    if (!string.IsNullOrWhiteSpace(response.ConversationId))
                    {
                        _backendConversationId ??= response.ConversationId;
                    }

                    if (!string.IsNullOrWhiteSpace(response.Content))
                    {
                        chunkCount++;
                        if (!hasResponse)
                        {
                            hasResponse = true;
                            if (dispatcher != null)
                            {
                                await dispatcher.InvokeAsync(() => RequestStatus = "收到响应");
                            }
                            else
                            {
                                RequestStatus = "收到响应";
                            }
                        }

                        if (response.IsReplace)
                        {
                            pendingText = response.Content;
                        }
                        else
                        {
                            pendingText += response.Content;
                        }

                        if ((DateTime.UtcNow - lastFlush).TotalMilliseconds >= 120)
                        {
                            var snapshot = pendingText;
                            if (dispatcher != null)
                            {
                                await dispatcher.InvokeAsync(() =>
                                {
                                    assistantMessage.Content = snapshot;
                                    assistantMessage.UpdatedAt = DateTime.Now;
                                    assistantVm.Content = snapshot;
                                });
                            }
                            else
                            {
                                assistantMessage.Content = snapshot;
                                assistantMessage.UpdatedAt = DateTime.Now;
                                assistantVm.Content = snapshot;
                            }
                            lastFlush = DateTime.UtcNow;
                        }
                    }

                    if (response.IsDone)
                    {
                        break;
                    }
                }
            }, token);

            assistantMessage.Status = MessageStatus.Sent;
            await _conversationService.UpdateMessageAsync(assistantMessage);
            _logService.Info($"更新助手消息完成 id={assistantMessage.Id}，会话={_currentConversationId}", "CHAT");
            assistantVm.Status = assistantMessage.Status;
            if (!string.IsNullOrWhiteSpace(pendingText))
            {
                assistantMessage.Content = pendingText;
                assistantMessage.UpdatedAt = DateTime.Now;
                assistantVm.Content = pendingText;
            }
            if (!hasResponse)
            {
                RequestStatus = "无响应";
                _logService.Warning($"AI 无响应，对话={_currentConversationId}，助手={AssistantKey}", "CHAT");
            }
            else
            {
                _logService.Info($"AI 响应完成，对话={_currentConversationId}，分片={chunkCount}", "CHAT");
            }
        }
        catch (OperationCanceledException)
        {
            RequestStatus = "请求取消";
            _logService.Warning("AI 请求已取消或超时", "CHAT");
        }
        catch (Exception ex)
        {
            Error = ex.Message;
            RequestStatus = "请求失败";
            _logService.Error($"AI 请求失败：{ex}", "CHAT");
        }
        finally
        {
            IsLoading = false;
            IsStreaming = false;
            _chatCts?.Dispose();
            _chatCts = null;
            _logService.Info("发送消息流程结束", "CHAT");
        }
    }

    private async Task LoadMessagesAsync()
    {
        Messages.Clear();
        if (_currentConversationId == null)
        {
            return;
        }

        _logService.Info($"加载会话消息，会话={_currentConversationId}", "CHAT");
        var list = await _conversationService.GetMessagesAsync(_currentConversationId.Value);
        foreach (var message in list)
        {
            Messages.Add(new ChatMessageViewModel(message.Id, message.Role, message.Content, message.Status));
        }
        _logService.Info($"加载消息完成，会话={_currentConversationId}，数量={list.Count}", "CHAT");
    }

    private async Task SaveTitleAsync()
    {
        if (SelectedConversation == null)
        {
            return;
        }

        _logService.Info($"保存会话标题，会话={SelectedConversation.Id}", "CHAT");
        await UpdateTitleAsync(SelectedConversationTitle, reloadList: true);
    }

    private async Task DeleteConversationAsync()
    {
        if (SelectedConversation == null)
        {
            return;
        }

        _logService.Info($"删除当前会话，会话={SelectedConversation.Id}", "CHAT");
        await _conversationService.SoftDeleteAsync(SelectedConversation.Id);
        _currentConversationId = null;
        _backendConversationId = null;
        Messages.Clear();
        await LoadConversationsAsync();
    }

    private Task SelectConversationAsync(Conversation? conversation)
    {
        if (conversation == null)
        {
            SelectedConversation = null;
            _currentConversationId = null;
            _backendConversationId = null;
            Messages.Clear();
            RaisePropertyChanged(nameof(CurrentConversationTitle));
            RaisePropertyChanged(nameof(CurrentConversationSubtitle));
            _logService.Info("切换会话为空，清空选择", "CHAT");
            return Task.CompletedTask;
        }

        SelectedConversation = conversation;
        _logService.Info($"切换会话 id={conversation.Id}", "CHAT");
        return Task.CompletedTask;
    }

    private async Task DeleteConversationByIdAsync(Conversation? conversation)
    {
        if (conversation == null)
        {
            return;
        }

        _logService.Info($"删除指定会话，会话={conversation.Id}", "CHAT");
        await _conversationService.SoftDeleteAsync(conversation.Id);

        if (_currentConversationId == conversation.Id)
        {
            _currentConversationId = null;
            _backendConversationId = null;
            SelectedConversation = null;
            Messages.Clear();
        }

        await LoadConversationsAsync();
    }

    private void StartEditTitle()
    {
        if (SelectedConversation == null)
        {
            return;
        }

        IsEditingTitle = true;
    }

    private async Task FinishEditTitleAsync()
    {
        if (SelectedConversation == null)
        {
            return;
        }

        var trimmed = SelectedConversationTitle?.Trim() ?? string.Empty;
        if (string.IsNullOrWhiteSpace(trimmed))
        {
            return;
        }

        await UpdateTitleAsync(trimmed, reloadList: true);
        IsEditingTitle = false;
    }

    private void CancelEditTitle()
    {
        if (SelectedConversation == null)
        {
            return;
        }

        SelectedConversationTitle = SelectedConversation.Title ?? string.Empty;
        IsEditingTitle = false;
    }

    private async Task UpdateTitleAsync(string title, bool reloadList)
    {
        if (SelectedConversation == null)
        {
            return;
        }

        var trimmed = title.Trim();
        if (string.IsNullOrWhiteSpace(trimmed))
        {
            return;
        }

        SelectedConversation.Title = trimmed;
        SelectedConversationTitle = trimmed;
        await _conversationService.UpdateAsync(SelectedConversation);
        if (reloadList)
        {
            await LoadConversationsAsync();
        }

        RaisePropertyChanged(nameof(CurrentConversationTitle));
    }

    private async Task TryApplyTitleFromFirstMessageAsync(string content)
    {
        if (SelectedConversation == null || IsEditingTitle)
        {
            return;
        }

        if (!string.IsNullOrWhiteSpace(SelectedConversation.Title) && SelectedConversation.Title != "新对话")
        {
            return;
        }

        var title = BuildTitleFromContent(content);
        if (string.IsNullOrWhiteSpace(title))
        {
            return;
        }

        _logService.Info($"使用首条问题作为标题，标题={title}", "CHAT");
        await UpdateTitleAsync(title, reloadList: true);
    }

    private static string BuildTitleFromContent(string content)
    {
        var trimmed = content.Trim();
        if (string.IsNullOrWhiteSpace(trimmed))
        {
            return string.Empty;
        }

        var normalized = string.Join(" ", trimmed.Split(new[] { ' ', '\n', '\r', '\t' }, StringSplitOptions.RemoveEmptyEntries));
        const int maxLength = 28;
        return normalized.Length <= maxLength ? normalized : normalized[..maxLength];
    }
}
