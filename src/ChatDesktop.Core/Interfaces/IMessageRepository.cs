using ChatDesktop.Core.Models;

namespace ChatDesktop.Core.Interfaces;

/// <summary>
/// 消息仓储
/// </summary>
public interface IMessageRepository
{
    Task<int> CreateAsync(Message message, CancellationToken cancellationToken = default);
    Task UpdateAsync(Message message, CancellationToken cancellationToken = default);
    Task DeleteAsync(int messageId, CancellationToken cancellationToken = default);

    Task<Message?> GetByIdAsync(int messageId, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<Message>> GetByConversationAsync(int conversationId, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<Message>> GetRecentByConversationAsync(int conversationId, int limit, CancellationToken cancellationToken = default);
}
