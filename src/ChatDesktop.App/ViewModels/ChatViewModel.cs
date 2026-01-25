using System.Collections.ObjectModel;
using System.Linq;
using ChatDesktop.Core.Enums;
using ChatDesktop.Core.Models;
using ChatDesktop.Core.Services;
using ChatDesktop.Infrastructure.AI;
using ChatDesktop.Infrastructure.Logging;

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
            _ = LoadMessagesAsync();
            SaveTitleCommand.RaiseCanExecuteChanged();
            DeleteConversationCommand.RaiseCanExecuteChanged();
            RaisePropertyChanged(nameof(CurrentConversationTitle));
            RaisePropertyChanged(nameof(CurrentConversationSubtitle));
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
        }
    }

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

    public async Task LoadConversationsAsync()
    {
        var list = await _conversationService.GetActiveAsync();
        Conversations.Clear();
        foreach (var conversation in list)
        {
            Conversations.Add(conversation);
        }

        if (_currentConversationId != null)
        {
            SelectedConversation = Conversations.FirstOrDefault(c => c.Id == _currentConversationId);
            return;
        }

        if (SelectedConversation != null && Conversations.All(c => c.Id != SelectedConversation.Id))
        {
            SelectedConversation = null;
            RaisePropertyChanged(nameof(CurrentConversationTitle));
            RaisePropertyChanged(nameof(CurrentConversationSubtitle));
        }
    }

    public async Task CreateConversationAsync()
    {
        var conversation = new Conversation
        {
            AgentId = "default",
            Title = "新对话",
            CreatedAt = DateTime.Now,
            UpdatedAt = DateTime.Now,
        };

        _currentConversationId = await _conversationService.CreateAsync(conversation);
        _backendConversationId = null;
        Messages.Clear();
        await LoadConversationsAsync();
        SelectedConversation = Conversations.FirstOrDefault(c => c.Id == _currentConversationId);
    }

    public async Task SendAsync()
    {
        if (string.IsNullOrWhiteSpace(InputText))
        {
            return;
        }

        try
        {
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
            var userVm = new ChatMessageViewModel(userMessageId, userMessage.Role, userMessage.Content, userMessage.Status);
            Messages.Add(userVm);

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
            assistantMessage.Id = assistantMessageId;
            var assistantVm = new ChatMessageViewModel(assistantMessageId, assistantMessage.Role, assistantMessage.Content, assistantMessage.Status);
            Messages.Add(assistantVm);

            IsStreaming = true;

            var config = _configService.GetChatConfig(AssistantKey);
            var hasResponse = false;
            await foreach (var response in _aiChatService.SendStreamingAsync(
                config,
                content,
                _backendConversationId,
                "unknown",
                CancellationToken.None))
            {
                if (!string.IsNullOrWhiteSpace(response.ConversationId))
                {
                    _backendConversationId ??= response.ConversationId;
                }

                if (!string.IsNullOrWhiteSpace(response.Content))
                {
                    if (!hasResponse)
                    {
                        hasResponse = true;
                        RequestStatus = "收到响应";
                    }
                    assistantMessage.Content += response.Content;
                    assistantMessage.UpdatedAt = DateTime.Now;
                    assistantVm.Content = assistantMessage.Content;
                }

                if (response.IsDone)
                {
                    break;
                }
            }

            assistantMessage.Status = MessageStatus.Sent;
            await _conversationService.UpdateMessageAsync(assistantMessage);
            assistantVm.Status = assistantMessage.Status;
            if (!hasResponse)
            {
                RequestStatus = "无响应";
                _logService.Warning($"AI 无响应，对话={_currentConversationId}，助手={AssistantKey}", "CHAT");
            }
            else
            {
                _logService.Info($"AI 响应完成，对话={_currentConversationId}", "CHAT");
            }
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
        }
    }

    private async Task LoadMessagesAsync()
    {
        Messages.Clear();
        if (_currentConversationId == null)
        {
            return;
        }

        var list = await _conversationService.GetMessagesAsync(_currentConversationId.Value);
        foreach (var message in list)
        {
            Messages.Add(new ChatMessageViewModel(message.Id, message.Role, message.Content, message.Status));
        }
    }

    private async Task SaveTitleAsync()
    {
        if (SelectedConversation == null)
        {
            return;
        }

        SelectedConversation.Title = SelectedConversationTitle;
        await _conversationService.UpdateAsync(SelectedConversation);
        await LoadConversationsAsync();
    }

    private async Task DeleteConversationAsync()
    {
        if (SelectedConversation == null)
        {
            return;
        }

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
            return Task.CompletedTask;
        }

        SelectedConversation = conversation;
        return Task.CompletedTask;
    }

    private async Task DeleteConversationByIdAsync(Conversation? conversation)
    {
        if (conversation == null)
        {
            return;
        }

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
}
