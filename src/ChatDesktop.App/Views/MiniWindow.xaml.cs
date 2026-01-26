using System.Collections.Generic;
using System.IO;
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
    private static readonly Dictionary<Uri, Vector> OffsetCache = new();

    private bool _hasUnread;
    private Size _sourceSize;
    private Vector _contentOffset;
    public MiniWindow()
    {
        InitializeComponent();
        LogoImage.SizeChanged += (_, _) =>
        {
            UpdateClip();
            UpdateImageLayout();
        };
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
        _sourceSize = image.PixelWidth > 0 && image.PixelHeight > 0
            ? new Size(image.PixelWidth, image.PixelHeight)
            : Size.Empty;
        _contentOffset = GetContentOffset(target);
        UpdateClip();
        UpdateImageLayout();
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

    private void UpdateImageLayout()
    {
        if (_sourceSize.Width <= 0 || _sourceSize.Height <= 0)
        {
            return;
        }

        var width = LogoImage.ActualWidth;
        var height = LogoImage.ActualHeight;
        if (width <= 0 || height <= 0)
        {
            return;
        }

        var scale = Math.Max(width / _sourceSize.Width, height / _sourceSize.Height);
        var offset = new Vector(_contentOffset.X * scale, _contentOffset.Y * scale);
        LogoImage.RenderTransform = new TranslateTransform(offset.X, offset.Y);
    }

    private static Vector GetContentOffset(Uri sourceUri)
    {
        if (OffsetCache.TryGetValue(sourceUri, out var cached))
        {
            return cached;
        }

        try
        {
            var fileName = Path.GetFileName(sourceUri.LocalPath);
            var path = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Assets", "Media", fileName);
            if (!File.Exists(path))
            {
                return Vector.Zero;
            }

            using var stream = File.OpenRead(path);
            var decoder = new GifBitmapDecoder(stream, BitmapCreateOptions.PreservePixelFormat, BitmapCacheOption.OnLoad);
            if (decoder.Frames.Count == 0)
            {
                return Vector.Zero;
            }

            BitmapSource frame = decoder.Frames[0];
            if (frame.Format != PixelFormats.Bgra32)
            {
                frame = new FormatConvertedBitmap(frame, PixelFormats.Bgra32, null, 0);
            }

            var width = frame.PixelWidth;
            var height = frame.PixelHeight;
            if (width <= 0 || height <= 0)
            {
                return Vector.Zero;
            }

            var stride = width * 4;
            var pixels = new byte[stride * height];
            frame.CopyPixels(pixels, stride, 0);

            var minX = width;
            var minY = height;
            var maxX = -1;
            var maxY = -1;
            const byte alphaThreshold = 12;
            for (var y = 0; y < height; y++)
            {
                var row = y * stride;
                for (var x = 0; x < width; x++)
                {
                    var alpha = pixels[row + x * 4 + 3];
                    if (alpha <= alphaThreshold)
                    {
                        continue;
                    }

                    if (x < minX) minX = x;
                    if (y < minY) minY = y;
                    if (x > maxX) maxX = x;
                    if (y > maxY) maxY = y;
                }
            }

            if (maxX < 0 || maxY < 0)
            {
                return Vector.Zero;
            }

            var contentCenterX = (minX + maxX) / 2.0;
            var contentCenterY = (minY + maxY) / 2.0;
            var imageCenterX = width / 2.0;
            var imageCenterY = height / 2.0;
            var offset = new Vector(imageCenterX - contentCenterX, imageCenterY - contentCenterY);
            OffsetCache[sourceUri] = offset;
            return offset;
        }
        catch
        {
            return Vector.Zero;
        }
    }
}
