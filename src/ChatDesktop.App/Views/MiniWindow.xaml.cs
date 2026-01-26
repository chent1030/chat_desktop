using System.Windows;
using System.Windows.Input;
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
    private bool _dragPending;
    private Point _dragStart;

    public MiniWindow()
    {
        InitializeComponent();
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
    }

    protected override void OnLocationChanged(EventArgs e)
    {
        base.OnLocationChanged(e);
        PositionChanged?.Invoke(this, new WindowPoint { X = Left, Y = Top });
    }

    private void OnMouseLeftButtonDown(object sender, MouseButtonEventArgs e)
    {
        _dragPending = true;
        _dragStart = e.GetPosition(this);
        CaptureMouse();
    }

    private void OnMouseMove(object sender, MouseEventArgs e)
    {
        if (!_dragPending || e.LeftButton != MouseButtonState.Pressed)
        {
            return;
        }

        var current = e.GetPosition(this);
        if (Math.Abs(current.X - _dragStart.X) < SystemParameters.MinimumHorizontalDragDistance &&
            Math.Abs(current.Y - _dragStart.Y) < SystemParameters.MinimumVerticalDragDistance)
        {
            return;
        }

        _dragPending = false;
        ReleaseMouseCapture();
        try
        {
            DragMove();
        }
        catch
        {
        }
    }

    private void OnMouseLeftButtonUp(object sender, MouseButtonEventArgs e)
    {
        if (_dragPending)
        {
            _dragPending = false;
            ReleaseMouseCapture();
        }

        if (e.ClickCount == 2)
        {
            RestoreRequested?.Invoke(this, EventArgs.Empty);
        }
    }
}
