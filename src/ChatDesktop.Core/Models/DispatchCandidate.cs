namespace ChatDesktop.Core.Models;

/// <summary>
/// 派发候选
/// </summary>
public sealed class DispatchCandidate
{
    public string EmpName { get; set; } = string.Empty;
    public string EmpNo { get; set; } = string.Empty;
    public string? WorkGroup { get; set; }
    public string? AccessGroup { get; set; }
}
