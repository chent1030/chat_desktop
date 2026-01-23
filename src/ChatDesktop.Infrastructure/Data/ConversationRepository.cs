using ChatDesktop.Core.Interfaces;
using ChatDesktop.Core.Models;
using Dapper;

namespace ChatDesktop.Infrastructure.Data;

/// <summary>
/// 会话仓储实现
/// </summary>
public sealed class ConversationRepository : IConversationRepository
{
    private readonly SqliteConnectionFactory _factory;

    public ConversationRepository(SqliteConnectionFactory factory)
    {
        _factory = factory;
        DapperTypeHandlers.Register();
    }

    public async Task<int> CreateAsync(Conversation conversation, CancellationToken cancellationToken = default)
    {
        const string sql = @"
INSERT INTO conversations (
  agent_id, title, is_active, message_count, created_at, updated_at,
  last_message_content, is_pinned, total_tokens, metadata
)
VALUES (
  @AgentId, @Title, @IsActive, @MessageCount, @CreatedAt, @UpdatedAt,
  @LastMessageContent, @IsPinned, @TotalTokens, @Metadata
);
SELECT last_insert_rowid();
";

        await using var connection = _factory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        var id = await connection.ExecuteScalarAsync<long>(sql, conversation);
        return (int)id;
    }

    public async Task UpdateAsync(Conversation conversation, CancellationToken cancellationToken = default)
    {
        const string sql = @"
UPDATE conversations SET
  agent_id = @AgentId,
  title = @Title,
  is_active = @IsActive,
  message_count = @MessageCount,
  created_at = @CreatedAt,
  updated_at = @UpdatedAt,
  last_message_content = @LastMessageContent,
  is_pinned = @IsPinned,
  total_tokens = @TotalTokens,
  metadata = @Metadata
WHERE id = @Id;
";

        await using var connection = _factory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await connection.ExecuteAsync(sql, conversation);
    }

    public async Task SoftDeleteAsync(int conversationId, CancellationToken cancellationToken = default)
    {
        const string sql = "UPDATE conversations SET is_active = 0 WHERE id = @conversationId;";
        await using var connection = _factory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await connection.ExecuteAsync(sql, new { conversationId });
    }

    public async Task DeleteAsync(int conversationId, CancellationToken cancellationToken = default)
    {
        const string sql = "DELETE FROM conversations WHERE id = @conversationId;";
        await using var connection = _factory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await connection.ExecuteAsync(sql, new { conversationId });
    }

    public async Task<Conversation?> GetByIdAsync(int conversationId, CancellationToken cancellationToken = default)
    {
        const string sql = "SELECT * FROM conversations WHERE id = @conversationId;";
        await using var connection = _factory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<Conversation>(sql, new { conversationId });
    }

    public async Task<IReadOnlyList<Conversation>> GetActiveAsync(CancellationToken cancellationToken = default)
    {
        const string sql = "SELECT * FROM conversations WHERE is_active = 1 ORDER BY updated_at DESC;";
        await using var connection = _factory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        var result = await connection.QueryAsync<Conversation>(sql);
        return result.ToList();
    }

    public async Task<IReadOnlyList<Conversation>> GetPinnedAsync(CancellationToken cancellationToken = default)
    {
        const string sql = "SELECT * FROM conversations WHERE is_active = 1 AND is_pinned = 1 ORDER BY updated_at DESC;";
        await using var connection = _factory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        var result = await connection.QueryAsync<Conversation>(sql);
        return result.ToList();
    }

    public async Task<IReadOnlyList<Conversation>> SearchAsync(string keyword, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(keyword))
        {
            return await GetActiveAsync(cancellationToken);
        }

        const string sql = @"
SELECT * FROM conversations
WHERE is_active = 1 AND (title LIKE @keyword OR last_message_content LIKE @keyword)
ORDER BY updated_at DESC;
";

        await using var connection = _factory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        var result = await connection.QueryAsync<Conversation>(sql, new { keyword = $"%{keyword.Trim()}%" });
        return result.ToList();
    }
}
