using ChatDesktop.Core.Enums;

namespace ChatDesktop.App.ViewModels;

/// <summary>
/// 聊天消息 ViewModel
/// </summary>
public sealed class ChatMessageViewModel : ViewModelBase
{
    private string _content;
    private MessageStatus _status;

    public ChatMessageViewModel(int id, MessageRole role, string content, MessageStatus status)
    {
        Id = id;
        Role = role;
        _content = content;
        _status = status;
    }

    public int Id { get; }
    public MessageRole Role { get; }
    public bool IsUser => Role == MessageRole.User;
    public string RoleLabel => Role == MessageRole.User ? "用户" : "AI";

    public string Content
    {
        get => _content;
        set
        {
            if (_content == value)
            {
                return;
            }

            _content = value;
            RaisePropertyChanged();
        }
    }

    public MessageStatus Status
    {
        get => _status;
        set
        {
            if (_status == value)
            {
                return;
            }

            _status = value;
            RaisePropertyChanged();
        }
    }
}
