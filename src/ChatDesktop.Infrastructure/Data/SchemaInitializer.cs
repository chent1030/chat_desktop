using System.Text;

namespace ChatDesktop.Infrastructure.Data;

/// <summary>
/// 数据库初始化
/// </summary>
public sealed class SchemaInitializer
{
    private readonly SqliteConnectionFactory _factory;
    private readonly string _schemaPath;

    public SchemaInitializer(SqliteConnectionFactory factory, string schemaPath)
    {
        _factory = factory;
        _schemaPath = schemaPath;
    }

    public async Task InitializeAsync(CancellationToken cancellationToken = default)
    {
        if (!File.Exists(_schemaPath))
        {
            throw new FileNotFoundException("未找到 Schema.sql", _schemaPath);
        }

        var sql = await File.ReadAllTextAsync(_schemaPath, Encoding.UTF8, cancellationToken);
        await using var connection = _factory.CreateConnection();
        await connection.OpenAsync(cancellationToken);
        await using var command = connection.CreateCommand();
        command.CommandText = sql;
        await command.ExecuteNonQueryAsync(cancellationToken);
    }
}
