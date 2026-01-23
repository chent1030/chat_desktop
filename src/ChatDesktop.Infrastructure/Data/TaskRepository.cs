using System.Text;
using ChatDesktop.Core.Enums;
using ChatDesktop.Core.Interfaces;
using ChatDesktop.Core.Models;
using ChatDesktop.Core.Queries;
using Dapper;

namespace ChatDesktop.Infrastructure.Data;

/// <summary>
/// 任务仓储实现
/// </summary>
public sealed class TaskRepository : ITaskRepository
{
    private readonly SqliteConnectionFactory _factory;

    public TaskRepository(SqliteConnectionFactory factory)
    {
        _factory = factory;
        DapperTypeHandlers.Register();
    }

    public async Task<int> CreateAsync(TaskItem task, CancellationToken cancellationToken = default)
    {
        const string sql = @"
INSERT INTO tasks (
  task_uid, title, description, priority, is_completed, is_read, due_date,
  created_at, updated_at, source, created_by_agent_id, completed_at, tags,
  is_synced, last_synced_at, assigned_to, assigned_to_type, assigned_by, assigned_at, allow_dispatch
)
VALUES (
  @TaskUid, @Title, @Description, @Priority, @IsCompleted, @IsRead, @DueDate,
  @CreatedAt, @UpdatedAt, @Source, @CreatedByAgentId, @CompletedAt, @Tags,
  @IsSynced, @LastSyncedAt, @AssignedTo, @AssignedToType, @AssignedBy, @AssignedAt, @AllowDispatch
);
SELECT last_insert_rowid();
";

        await using var connection = _factory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        var id = await connection.ExecuteScalarAsync<long>(sql, task);
        return (int)id;
    }

    public async Task UpdateAsync(TaskItem task, CancellationToken cancellationToken = default)
    {
        const string sql = @"
UPDATE tasks SET
  task_uid = @TaskUid,
  title = @Title,
  description = @Description,
  priority = @Priority,
  is_completed = @IsCompleted,
  is_read = @IsRead,
  due_date = @DueDate,
  created_at = @CreatedAt,
  updated_at = @UpdatedAt,
  source = @Source,
  created_by_agent_id = @CreatedByAgentId,
  completed_at = @CompletedAt,
  tags = @Tags,
  is_synced = @IsSynced,
  last_synced_at = @LastSyncedAt,
  assigned_to = @AssignedTo,
  assigned_to_type = @AssignedToType,
  assigned_by = @AssignedBy,
  assigned_at = @AssignedAt,
  allow_dispatch = @AllowDispatch
WHERE id = @Id;
";

        await using var connection = _factory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await connection.ExecuteAsync(sql, task);
    }

    public async Task DeleteAsync(int taskId, CancellationToken cancellationToken = default)
    {
        const string sql = "DELETE FROM tasks WHERE id = @taskId;";
        await using var connection = _factory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await connection.ExecuteAsync(sql, new { taskId });
    }

    public async Task<TaskItem?> GetByIdAsync(int taskId, CancellationToken cancellationToken = default)
    {
        const string sql = "SELECT * FROM tasks WHERE id = @taskId;";
        await using var connection = _factory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<TaskItem>(sql, new { taskId });
    }

    public async Task<TaskItem?> GetByTaskUidAsync(string taskUid, CancellationToken cancellationToken = default)
    {
        const string sql = "SELECT * FROM tasks WHERE task_uid = @taskUid;";
        await using var connection = _factory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        return await connection.QuerySingleOrDefaultAsync<TaskItem>(sql, new { taskUid });
    }

    public async Task<IReadOnlyList<TaskItem>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        const string sql = "SELECT * FROM tasks;";
        await using var connection = _factory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        var result = await connection.QueryAsync<TaskItem>(sql);
        return result.ToList();
    }

    public async Task<IReadOnlyList<TaskItem>> QueryAsync(TaskQuery query, CancellationToken cancellationToken = default)
    {
        var sql = new StringBuilder("SELECT * FROM tasks");
        var clauses = new List<string>();
        var parameters = new DynamicParameters();

        ApplyFilter(query.Filter, clauses, parameters);

        if (!string.IsNullOrWhiteSpace(query.SearchKeyword))
        {
            clauses.Add("(title LIKE @keyword OR description LIKE @keyword)");
            parameters.Add("keyword", $"%{query.SearchKeyword.Trim()}%");
        }

        if (clauses.Count > 0)
        {
            sql.Append(" WHERE ").Append(string.Join(" AND ", clauses));
        }

        sql.Append(" ORDER BY ").Append(GetOrderBy(query.SortOrder));

        await using var connection = _factory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        var result = await connection.QueryAsync<TaskItem>(sql.ToString(), parameters);
        return result.ToList();
    }

    public async Task<int> CountAsync(CancellationToken cancellationToken = default)
    {
        const string sql = "SELECT COUNT(1) FROM tasks;";
        await using var connection = _factory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        return await connection.ExecuteScalarAsync<int>(sql);
    }

    public async Task<int> CountIncompleteAsync(CancellationToken cancellationToken = default)
    {
        const string sql = "SELECT COUNT(1) FROM tasks WHERE is_completed = 0;";
        await using var connection = _factory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        return await connection.ExecuteScalarAsync<int>(sql);
    }

    public async Task<int> CountCompletedAsync(CancellationToken cancellationToken = default)
    {
        const string sql = "SELECT COUNT(1) FROM tasks WHERE is_completed = 1;";
        await using var connection = _factory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        return await connection.ExecuteScalarAsync<int>(sql);
    }

    public async Task<int> DeleteCompletedAsync(CancellationToken cancellationToken = default)
    {
        const string sql = "DELETE FROM tasks WHERE is_completed = 1;";
        await using var connection = _factory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        return await connection.ExecuteAsync(sql);
    }

    private static void ApplyFilter(TaskFilter filter, List<string> clauses, DynamicParameters parameters)
    {
        var now = DateTime.Now;
        switch (filter)
        {
            case TaskFilter.All:
                return;
            case TaskFilter.Incomplete:
                clauses.Add("is_completed = 0");
                return;
            case TaskFilter.Completed:
                clauses.Add("is_completed = 1");
                return;
            case TaskFilter.Overdue:
                clauses.Add("is_completed = 0 AND due_date IS NOT NULL AND due_date < @now");
                parameters.Add("now", now);
                return;
            case TaskFilter.DueSoon:
                clauses.Add("is_completed = 0 AND due_date IS NOT NULL AND due_date BETWEEN @now AND @soon");
                parameters.Add("now", now);
                parameters.Add("soon", now.AddHours(24));
                return;
            case TaskFilter.Today:
                var start = now.Date;
                var end = start.AddDays(1).AddSeconds(-1);
                clauses.Add("due_date IS NOT NULL AND due_date BETWEEN @start AND @end");
                parameters.Add("start", start);
                parameters.Add("end", end);
                return;
        }
    }

    private static string GetOrderBy(TaskSortOrder sortOrder)
    {
        return sortOrder switch
        {
            TaskSortOrder.CreatedAtAsc => "created_at ASC",
            TaskSortOrder.DueDateAsc => "due_date ASC",
            TaskSortOrder.DueDateDesc => "due_date DESC",
            TaskSortOrder.PriorityAsc => "priority ASC",
            TaskSortOrder.PriorityDesc => "priority DESC",
            TaskSortOrder.TitleAsc => "title ASC",
            _ => "created_at DESC",
        };
    }
}
