using System;
using System.Globalization;
using System.Windows.Data;
using System.Windows.Media;
using ChatDesktop.Core.Enums;

namespace ChatDesktop.App.Converters;

/// <summary>
/// 优先级颜色转换
/// </summary>
public sealed class PriorityToBrushConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
    {
        if (value is not Priority priority)
        {
            return new SolidColorBrush(Color.FromRgb(251, 140, 0));
        }

        return priority switch
        {
            Priority.Low => new SolidColorBrush(Color.FromRgb(67, 160, 71)),
            Priority.High => new SolidColorBrush(Color.FromRgb(229, 57, 53)),
            _ => new SolidColorBrush(Color.FromRgb(251, 140, 0)),
        };
    }

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
    {
        throw new NotSupportedException();
    }
}
