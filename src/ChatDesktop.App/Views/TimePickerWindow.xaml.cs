using System.Globalization;
using System.Windows;

namespace ChatDesktop.App.Views;

/// <summary>
/// 时间选择窗口
/// </summary>
public partial class TimePickerWindow : Window
{
    public TimePickerWindow(string? initialTimeText = null)
    {
        InitializeComponent();
        InitializeOptions();
        ApplyInitialValue(initialTimeText);
    }

    public string? SelectedTimeText { get; private set; }

    private void InitializeOptions()
    {
        for (var i = 0; i < 24; i++)
        {
            HourComboBox.Items.Add(i.ToString("D2", CultureInfo.InvariantCulture));
        }

        for (var i = 0; i < 60; i++)
        {
            MinuteComboBox.Items.Add(i.ToString("D2", CultureInfo.InvariantCulture));
        }
    }

    private void ApplyInitialValue(string? text)
    {
        if (string.IsNullOrWhiteSpace(text))
        {
            HourComboBox.SelectedIndex = 0;
            MinuteComboBox.SelectedIndex = 0;
            return;
        }

        if (TimeSpan.TryParse(text.Trim(), out var time))
        {
            HourComboBox.SelectedIndex = time.Hours;
            MinuteComboBox.SelectedIndex = time.Minutes;
            return;
        }

        HourComboBox.SelectedIndex = 0;
        MinuteComboBox.SelectedIndex = 0;
    }

    private void OnConfirmClicked(object sender, RoutedEventArgs e)
    {
        if (HourComboBox.SelectedItem is string hour && MinuteComboBox.SelectedItem is string minute)
        {
            SelectedTimeText = $"{hour}:{minute}";
        }

        DialogResult = true;
        Close();
    }

    private void OnCancelClicked(object sender, RoutedEventArgs e)
    {
        DialogResult = false;
        Close();
    }
}
