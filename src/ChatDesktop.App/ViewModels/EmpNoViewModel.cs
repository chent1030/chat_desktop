using ChatDesktop.Core.Interfaces;
using ChatDesktop.Infrastructure.Config;

namespace ChatDesktop.App.ViewModels;

/// <summary>
/// 工号输入 ViewModel
/// </summary>
public sealed class EmpNoViewModel : ViewModelBase
{
    private readonly ITaskRemoteService _remoteService;
    private readonly LocalSettingsStore _settingsStore;

    private string _empNo = string.Empty;
    private bool _isProcessing;
    private string? _error;

    public EmpNoViewModel(ITaskRemoteService remoteService, LocalSettingsStore settingsStore)
    {
        _remoteService = remoteService;
        _settingsStore = settingsStore;
        ConfirmCommand = new AsyncRelayCommand(ConfirmAsync, () => !string.IsNullOrWhiteSpace(EmpNo) && !IsProcessing);
    }

    public event Action? CloseRequested;

    public string EmpNo
    {
        get => _empNo;
        set
        {
            if (_empNo == value)
            {
                return;
            }

            _empNo = value;
            RaisePropertyChanged();
            ConfirmCommand.RaiseCanExecuteChanged();
        }
    }

    public bool IsProcessing
    {
        get => _isProcessing;
        private set
        {
            _isProcessing = value;
            RaisePropertyChanged();
            ConfirmCommand.RaiseCanExecuteChanged();
        }
    }

    public string? Error
    {
        get => _error;
        private set
        {
            _error = value;
            RaisePropertyChanged();
        }
    }

    public AsyncRelayCommand ConfirmCommand { get; }

    private async Task ConfirmAsync()
    {
        var value = EmpNo.Trim();
        if (string.IsNullOrWhiteSpace(value))
        {
            Error = "工号不能为空";
            return;
        }

        try
        {
            IsProcessing = true;
            Error = null;
            var ok = await _remoteService.VerifyEmpNoAsync(value);
            if (!ok)
            {
                Error = "工号校验失败";
                return;
            }

            var settings = await _settingsStore.LoadAsync();
            settings.EmpNo = value;
            await _settingsStore.SaveAsync(settings);
            CloseRequested?.Invoke();
        }
        catch (Exception ex)
        {
            Error = ex.Message;
        }
        finally
        {
            IsProcessing = false;
        }
    }
}
