using System.Windows;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Media.Animation;
using ChatDesktop.Core.Models;
using WpfAnimatedGif;

namespace ChatDesktop.App.Views;

/// <summary>
/// 小窗模式：仅展示 GIF 动图
/// </summary>
public partial class MiniWindow : Window
{
    private static readonly Uri DynamicGifUri =
        new("pack://siteoforigin:,,,/Assets/Media/dynamic_logo.gif");
    private static readonly Uri UnreadGifUri =
        new("pack://siteoforigin:,,,/Assets/Media/unread_logo.gif");

    private bool _hasUnread;
    public MiniWindow()
    {
        InitializeComponent();
        LogoImage.SizeChanged += (_, _) => UpdateClip();
        SetUnreadCount(0);
    }

    public event EventHandler? RestoreRequested;
    public event EventHandler<WindowPoint>? PositionChanged;

    public void SetUnreadCount(int unreadCount)
    {
        var hasUnread = unreadCount > 0;
        if (_hasUnread == hasUnread && LogoImage.Source != null)
        {
            return;
        }

        _hasUnread = hasUnread;
        UpdateGif();
    }

    private void UpdateGif()
    {
        var target = _hasUnread ? DynamicGifUri : UnreadGifUri;
        var image = new BitmapImage();
        image.BeginInit();
        image.UriSource = target;
        image.CacheOption = BitmapCacheOption.OnLoad;
        image.EndInit();
        ImageBehavior.SetAnimatedSource(LogoImage, image);
        ImageBehavior.SetRepeatBehavior(LogoImage, RepeatBehavior.Forever);
        UpdateClip();
    }

    private void OnMouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        if (e.ClickCount == 2)
        {
            RestoreRequested?.Invoke(this, EventArgs.Empty);
            return;
        }

        try
        {
            DragMove();
        }
        catch
        {
        }
    }

    protected override void OnLocationChanged(EventArgs e)
    {
        base.OnLocationChanged(e);
        PositionChanged?.Invoke(this, new WindowPoint { X = Left, Y = Top });
    }

    private void UpdateClip()
    {
        var size = Math.Min(LogoImage.ActualWidth, LogoImage.ActualHeight);
        if (size <= 0)
        {
            return;
        }

        var radius = size / 2;
        LogoImage.Clip = new EllipseGeometry(new Point(radius, radius), radius, radius);
    }
}
