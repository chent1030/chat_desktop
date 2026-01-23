using ChatDesktop.Core.Interfaces;
using ChatDesktop.Core.Models;
using Dapper;

namespace ChatDesktop.Infrastructure.Data;

/// <summary>
/// 任务操作记录仓储实现
/// </summary>
public sealed class TaskActionRepository : ITaskActionRepository
{
    private readonly SqliteConnectionFactory _factory;

    public TaskActionRepository(SqliteConnectionFactory factory)
    {
        _factory = factory;
        DapperTypeHandlers.Register();
    }

    public async Task<int> CreateAsync(TaskAction action, CancellationToken cancellationToken = default)
    {
        const string sql = @"
INSERT INTO task_actions (
  task_id, action_type, timestamp, performed_by, changes, description, can_undo
)
VALUES (
  @TaskId, @ActionType, @Timestamp, @PerformedBy, @Changes, @Description, @CanUndo
);
SELECT last_insert_rowid();
";

        await using var connection = _factory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        var id = await connection.ExecuteScalarAsync<long>(sql, action);
        return (int)id;
    }

    public async Task<IReadOnlyList<TaskAction>> GetByTaskIdAsync(int taskId, CancellationToken cancellationToken = default)
    {
        const string sql = "SELECT * FROM task_actions WHERE task_id = @taskId ORDER BY timestamp DESC;";
        await using var connection = _factory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        var result = await connection.QueryAsync<TaskAction>(sql, new { taskId });
        return result.ToList();
    }
}
