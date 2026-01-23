using Microsoft.Data.Sqlite;

namespace ChatDesktop.Infrastructure.Data;

/// <summary>
/// SQLite 连接工厂
/// </summary>
public sealed class SqliteConnectionFactory
{
    private readonly string _databasePath;

    public SqliteConnectionFactory(string databasePath)
    {
        _databasePath = databasePath;
    }

    public SqliteConnection CreateConnection()
    {
        return new SqliteConnection($"Data Source={_databasePath}");
    }
}
