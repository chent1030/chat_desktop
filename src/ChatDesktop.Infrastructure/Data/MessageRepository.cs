using ChatDesktop.Core.Interfaces;
using ChatDesktop.Core.Models;
using Dapper;

namespace ChatDesktop.Infrastructure.Data;

/// <summary>
/// 消息仓储实现
/// </summary>
public sealed class MessageRepository : IMessageRepository
{
    private readonly SqliteConnectionFactory _factory;

    public MessageRepository(SqliteConnectionFactory factory)
    {
        _factory = factory;
        DapperTypeHandlers.Register();
    }

    public async Task<int> CreateAsync(Message message, CancellationToken cancellationToken = default)
    {
        const string sql = @"
INSERT INTO messages (
  conversation_id, agent_id, role, content, status, created_at, updated_at, error, token_count, metadata
)
VALUES (
  @ConversationId, @AgentId, @Role, @Content, @Status, @CreatedAt, @UpdatedAt, @Error, @TokenCount, @Metadata
);
SELECT last_insert_rowid();
";

        await using var connection = _factory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        var id = await connection.ExecuteScalarAsync<long>(sql, message);
        return (int)id;
    }

    public async Task UpdateAsync(Message message, CancellationToken cancellationToken = default)
    {
        const string sql = @"
UPDATE messages SET
  conversation_id = @ConversationId,
  agent_id = @AgentId,
  role = @Role,
  content = @Content,
  status = @Status,
  created_at = @CreatedAt,
  updated_at = @UpdatedAt,
  error = @Error,
  token_count = @TokenCount,
  metadata = @Metadata
WHERE id = @Id;
";

        await using var connection = _factory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await connection.ExecuteAsync(sql, message);
    }

    public async Task DeleteAsync(int messageId, CancellationToken cancellationToken = default)
    {
        const string sql = "DELETE FROM messages WHERE id = @messageId;";
        await using var connection = _factory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await connection.ExecuteAsync(sql, new { messageId });
    }

    public async Task<Message?> GetByIdAsync(int messageId, CancellationToken cancellationToken = default)
    {
        const string sql = "SELECT * FROM messages WHERE id = @messageId;";
        await using var connection = _factory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<Message>(sql, new { messageId });
    }

    public async Task<IReadOnlyList<Message>> GetByConversationAsync(int conversationId, CancellationToken cancellationToken = default)
    {
        const string sql = "SELECT * FROM messages WHERE conversation_id = @conversationId ORDER BY created_at ASC;";
        await using var connection = _factory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        var result = await connection.QueryAsync<Message>(sql, new { conversationId });
        return result.ToList();
    }

    public async Task<IReadOnlyList<Message>> GetRecentByConversationAsync(int conversationId, int limit, CancellationToken cancellationToken = default)
    {
        const string sql = @"
SELECT * FROM messages
WHERE conversation_id = @conversationId
ORDER BY created_at DESC
LIMIT @limit;
";

        await using var connection = _factory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        var result = await connection.QueryAsync<Message>(sql, new { conversationId, limit });
        return result.Reverse().ToList();
    }
}
