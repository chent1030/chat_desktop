using ChatDesktop.Core.Interfaces;
using ChatDesktop.Core.Models;

namespace ChatDesktop.Core.Services;

/// <summary>
/// 会话服务
/// </summary>
public sealed class ConversationService
{
    private readonly IConversationRepository _conversationRepository;
    private readonly IMessageRepository _messageRepository;

    public ConversationService(IConversationRepository conversationRepository, IMessageRepository messageRepository)
    {
        _conversationRepository = conversationRepository;
        _messageRepository = messageRepository;
    }

    public Task<int> CreateAsync(Conversation conversation, CancellationToken cancellationToken = default)
    {
        return _conversationRepository.CreateAsync(conversation, cancellationToken);
    }

    public Task UpdateAsync(Conversation conversation, CancellationToken cancellationToken = default)
    {
        conversation.Touch();
        return _conversationRepository.UpdateAsync(conversation, cancellationToken);
    }

    public Task SoftDeleteAsync(int conversationId, CancellationToken cancellationToken = default)
    {
        return _conversationRepository.SoftDeleteAsync(conversationId, cancellationToken);
    }

    public Task DeleteAsync(int conversationId, CancellationToken cancellationToken = default)
    {
        return _conversationRepository.DeleteAsync(conversationId, cancellationToken);
    }

    public Task<Conversation?> GetByIdAsync(int conversationId, CancellationToken cancellationToken = default)
    {
        return _conversationRepository.GetByIdAsync(conversationId, cancellationToken);
    }

    public Task<IReadOnlyList<Conversation>> GetActiveAsync(CancellationToken cancellationToken = default)
    {
        return _conversationRepository.GetActiveAsync(cancellationToken);
    }

    public Task<IReadOnlyList<Conversation>> GetPinnedAsync(CancellationToken cancellationToken = default)
    {
        return _conversationRepository.GetPinnedAsync(cancellationToken);
    }

    public Task<IReadOnlyList<Conversation>> SearchAsync(string keyword, CancellationToken cancellationToken = default)
    {
        return _conversationRepository.SearchAsync(keyword, cancellationToken);
    }

    public async Task<int> AddMessageAsync(Message message, CancellationToken cancellationToken = default)
    {
        var id = await _messageRepository.CreateAsync(message, cancellationToken);
        var conversation = await _conversationRepository.GetByIdAsync(message.ConversationId, cancellationToken);
        if (conversation != null)
        {
            conversation.IncrementMessageCount();
            conversation.UpdateLastMessage(message.Content);
            await _conversationRepository.UpdateAsync(conversation, cancellationToken);
        }

        return id;
    }

    public Task UpdateMessageAsync(Message message, CancellationToken cancellationToken = default)
    {
        message.Touch();
        return _messageRepository.UpdateAsync(message, cancellationToken);
    }

    public Task<IReadOnlyList<Message>> GetMessagesAsync(int conversationId, CancellationToken cancellationToken = default)
    {
        return _messageRepository.GetByConversationAsync(conversationId, cancellationToken);
    }

    public Task<IReadOnlyList<Message>> GetRecentMessagesAsync(int conversationId, int limit, CancellationToken cancellationToken = default)
    {
        return _messageRepository.GetRecentByConversationAsync(conversationId, limit, cancellationToken);
    }
}
