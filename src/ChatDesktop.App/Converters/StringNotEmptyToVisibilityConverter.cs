using System;
using System.Globalization;
using System.Windows;
using System.Windows.Data;

namespace ChatDesktop.App.Converters;

/// <summary>
/// 字符串是否为空 -> 可见性
/// </summary>
public sealed class StringNotEmptyToVisibilityConverter : IValueConverter
{
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        var text = value?.ToString();
        var isEmpty = string.IsNullOrWhiteSpace(text);
        var invert = parameter?.ToString()?.Equals("Invert", StringComparison.OrdinalIgnoreCase) == true;
        if (invert)
        {
            return isEmpty ? Visibility.Visible : Visibility.Collapsed;
        }
        return isEmpty ? Visibility.Collapsed : Visibility.Visible;
    }

    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        return Binding.DoNothing;
    }
}
