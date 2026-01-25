using System.Windows;
using System.Windows.Controls;
using ChatDesktop.Core.Models;

namespace ChatDesktop.App.Selectors;

/// <summary>
/// 会话下拉菜单样式选择器
/// </summary>
public sealed class ConversationMenuItemStyleSelector : StyleSelector
{
    public Style? ConversationStyle { get; set; }

    public override Style? SelectStyle(object item, DependencyObject container)
    {
        if (item is Conversation && container is MenuItem)
        {
            return ConversationStyle;
        }

        return null;
    }
}
