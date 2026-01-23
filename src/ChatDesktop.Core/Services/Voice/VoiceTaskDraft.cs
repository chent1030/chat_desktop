namespace ChatDesktop.Core.Services.Voice;

/// <summary>
/// 语音任务草稿
/// </summary>
public sealed class VoiceTaskDraft
{
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public DateTime? DueDate { get; set; }
    public bool DispatchNow { get; set; }
    public string? AssignedToType { get; set; }
    public string? AssignedTo { get; set; }
    public string? AssignedToEmpNo { get; set; }
    public string? OriginalDispatchTarget { get; set; }
    public string? IgnoredTimeHint { get; set; }
}
