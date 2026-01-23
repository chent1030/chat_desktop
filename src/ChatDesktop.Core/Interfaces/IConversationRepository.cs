using ChatDesktop.Core.Models;

namespace ChatDesktop.Core.Interfaces;

/// <summary>
/// 会话仓储
/// </summary>
public interface IConversationRepository
{
    Task<int> CreateAsync(Conversation conversation, CancellationToken cancellationToken = default);
    Task UpdateAsync(Conversation conversation, CancellationToken cancellationToken = default);
    Task SoftDeleteAsync(int conversationId, CancellationToken cancellationToken = default);
    Task DeleteAsync(int conversationId, CancellationToken cancellationToken = default);

    Task<Conversation?> GetByIdAsync(int conversationId, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<Conversation>> GetActiveAsync(CancellationToken cancellationToken = default);
    Task<IReadOnlyList<Conversation>> GetPinnedAsync(CancellationToken cancellationToken = default);
    Task<IReadOnlyList<Conversation>> SearchAsync(string keyword, CancellationToken cancellationToken = default);
}
