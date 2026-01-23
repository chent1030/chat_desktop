using System.Data;
using System.Globalization;
using Dapper;

namespace ChatDesktop.Infrastructure.Data;

/// <summary>
/// Dapper 类型处理
/// </summary>
public static class DapperTypeHandlers
{
    private static bool _registered;

    public static void Register()
    {
        if (_registered)
        {
            return;
        }

        DefaultTypeMap.MatchNamesWithUnderscores = true;
        SqlMapper.AddTypeHandler(new DateTimeHandler());
        SqlMapper.AddTypeHandler(new NullableDateTimeHandler());
        _registered = true;
    }

    private sealed class DateTimeHandler : SqlMapper.TypeHandler<DateTime>
    {
        public override void SetValue(IDbDataParameter parameter, DateTime value)
        {
            parameter.DbType = DbType.String;
            parameter.Value = value.ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture);
        }

        public override DateTime Parse(object value)
        {
            if (value is DateTime dateTime)
            {
                return dateTime;
            }

            var text = value?.ToString();
            if (string.IsNullOrWhiteSpace(text))
            {
                return DateTime.MinValue;
            }

            return DateTime.Parse(text, CultureInfo.InvariantCulture);
        }
    }

    private sealed class NullableDateTimeHandler : SqlMapper.TypeHandler<DateTime?>
    {
        public override void SetValue(IDbDataParameter parameter, DateTime? value)
        {
            parameter.DbType = DbType.String;
            parameter.Value = value == null
                ? DBNull.Value
                : value.Value.ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture);
        }

        public override DateTime? Parse(object value)
        {
            if (value == null || value is DBNull)
            {
                return null;
            }

            if (value is DateTime dateTime)
            {
                return dateTime;
            }

            var text = value.ToString();
            if (string.IsNullOrWhiteSpace(text))
            {
                return null;
            }

            return DateTime.Parse(text, CultureInfo.InvariantCulture);
        }
    }
}
