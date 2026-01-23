using System.Globalization;
using System.Windows;

namespace ChatDesktop.App.Views;

/// <summary>
/// 日期时间选择窗口
/// </summary>
public partial class DateTimePickerWindow : Window
{
    public DateTimePickerWindow(DateTime? initialDateTime = null, string? title = null)
    {
        InitializeComponent();

        if (!string.IsNullOrWhiteSpace(title))
        {
            Title = title;
        }

        InitializeOptions(initialDateTime);
    }

    public DateTime? SelectedDateTime { get; private set; }

    private void InitializeOptions(DateTime? initialDateTime)
    {
        for (var hour = 0; hour < 24; hour++)
        {
            HourComboBox.Items.Add(hour.ToString("00", CultureInfo.InvariantCulture));
        }

        for (var minute = 0; minute < 60; minute++)
        {
            MinuteComboBox.Items.Add(minute.ToString("00", CultureInfo.InvariantCulture));
        }

        if (initialDateTime.HasValue)
        {
            DatePicker.SelectedDate = initialDateTime.Value.Date;
            HourComboBox.SelectedItem = initialDateTime.Value.Hour.ToString("00", CultureInfo.InvariantCulture);
            MinuteComboBox.SelectedItem = initialDateTime.Value.Minute.ToString("00", CultureInfo.InvariantCulture);
        }
        else
        {
            var now = DateTime.Now;
            HourComboBox.SelectedItem = now.Hour.ToString("00", CultureInfo.InvariantCulture);
            MinuteComboBox.SelectedItem = now.Minute.ToString("00", CultureInfo.InvariantCulture);
        }
    }

    private void OnConfirmClicked(object sender, RoutedEventArgs e)
    {
        if (DatePicker.SelectedDate == null)
        {
            SelectedDateTime = null;
            DialogResult = true;
            return;
        }

        var hour = ParseInt(HourComboBox.SelectedItem?.ToString());
        var minute = ParseInt(MinuteComboBox.SelectedItem?.ToString());
        var date = DatePicker.SelectedDate.Value.Date;
        SelectedDateTime = date.AddHours(hour).AddMinutes(minute);
        DialogResult = true;
    }

    private void OnClearClicked(object sender, RoutedEventArgs e)
    {
        SelectedDateTime = null;
        DialogResult = true;
    }

    private void OnCancelClicked(object sender, RoutedEventArgs e)
    {
        DialogResult = false;
    }

    private static int ParseInt(string? text)
    {
        return int.TryParse(text, out var value) ? value : 0;
    }
}
