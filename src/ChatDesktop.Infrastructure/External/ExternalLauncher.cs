using System.Diagnostics;
using ChatDesktop.Infrastructure.Config;

namespace ChatDesktop.Infrastructure.External;

/// <summary>
/// 外部应用启动
/// </summary>
public static class ExternalLauncher
{
    public static void OpenOutlook(string? email, string? emailId)
    {
        if (!string.IsNullOrWhiteSpace(emailId))
        {
            TryOpenUri($"outlook:search?text={emailId}");
        }

        if (!string.IsNullOrWhiteSpace(email))
        {
            TryOpenUri($"mailto:{email}");
        }
        else
        {
            TryOpenUri("mailto:");
        }

        if (OperatingSystem.IsWindows())
        {
            var path = EnvConfig.OutlookPathWindows;
            if (!string.IsNullOrWhiteSpace(path))
            {
                TryStartProcess(path);
                return;
            }

            TryOpenUri("outlook:");
        }
        else if (OperatingSystem.IsMacOS())
        {
            TryStartProcess("open", "-a", "Microsoft Outlook");
        }
    }

    public static void OpenDingTalk()
    {
        TryOpenUri("dingtalk://dingtalkclient/action/open");

        if (OperatingSystem.IsWindows())
        {
            var path = EnvConfig.DingTalkPathWindows;
            if (!string.IsNullOrWhiteSpace(path))
            {
                TryStartProcess(path);
                return;
            }

            TryStartProcess("cmd", "/c", "start", "DingTalk");
        }
        else if (OperatingSystem.IsMacOS())
        {
            TryStartProcess("open", "-a", "DingTalk");
        }
    }

    private static void TryOpenUri(string uri)
    {
        try
        {
            var psi = new ProcessStartInfo
            {
                FileName = uri,
                UseShellExecute = true,
            };
            Process.Start(psi);
        }
        catch
        {
        }
    }

    private static void TryStartProcess(params string[] args)
    {
        try
        {
            if (args.Length == 0)
            {
                return;
            }

            var psi = new ProcessStartInfo
            {
                FileName = args[0],
                UseShellExecute = true,
            };

            if (args.Length > 1)
            {
                psi.ArgumentList.AddRange(args.Skip(1));
            }

            Process.Start(psi);
        }
        catch
        {
        }
    }
}
