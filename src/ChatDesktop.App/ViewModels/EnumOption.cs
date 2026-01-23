namespace ChatDesktop.App.ViewModels;

/// <summary>
/// 枚举选项
/// </summary>
public sealed class EnumOption<T>
{
    public EnumOption(T value, string label)
    {
        Value = value;
        Label = label;
    }

    public T Value { get; }
    public string Label { get; }
}
