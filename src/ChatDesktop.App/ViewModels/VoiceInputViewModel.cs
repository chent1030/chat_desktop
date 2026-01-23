using ChatDesktop.Infrastructure.Voice;

namespace ChatDesktop.App.ViewModels;

/// <summary>
/// 语音输入 ViewModel
/// </summary>
public sealed class VoiceInputViewModel : ViewModelBase
{
    private readonly AudioRecorderService _recorder;
    private readonly SpeechToTextService _speechService;
    private bool _isRecording;
    private bool _isProcessing;
    private string _transcript = string.Empty;
    private string? _error;

    public VoiceInputViewModel(AudioRecorderService recorder, SpeechToTextService speechService)
    {
        _recorder = recorder;
        _speechService = speechService;

        StartRecordCommand = new AsyncRelayCommand(StartRecordAsync, () => !IsRecording && !IsProcessing);
        StopRecordCommand = new AsyncRelayCommand(StopRecordAsync, () => IsRecording);
        ConfirmCommand = new RelayCommand(_ => Confirm());
        CancelCommand = new RelayCommand(_ => Cancel());
    }

    public event Action? CloseRequested;

    public string? ResultText { get; private set; }

    public bool IsRecording
    {
        get => _isRecording;
        private set
        {
            if (_isRecording == value)
            {
                return;
            }

            _isRecording = value;
            RaisePropertyChanged();
            StartRecordCommand.RaiseCanExecuteChanged();
            StopRecordCommand.RaiseCanExecuteChanged();
        }
    }

    public bool IsProcessing
    {
        get => _isProcessing;
        private set
        {
            if (_isProcessing == value)
            {
                return;
            }

            _isProcessing = value;
            RaisePropertyChanged();
            StartRecordCommand.RaiseCanExecuteChanged();
            StopRecordCommand.RaiseCanExecuteChanged();
        }
    }

    public string Transcript
    {
        get => _transcript;
        private set
        {
            if (_transcript == value)
            {
                return;
            }

            _transcript = value;
            RaisePropertyChanged();
        }
    }

    public string? Error
    {
        get => _error;
        private set
        {
            if (_error == value)
            {
                return;
            }

            _error = value;
            RaisePropertyChanged();
        }
    }

    public AsyncRelayCommand StartRecordCommand { get; }
    public AsyncRelayCommand StopRecordCommand { get; }
    public RelayCommand ConfirmCommand { get; }
    public RelayCommand CancelCommand { get; }

    private async Task StartRecordAsync()
    {
        Error = null;
        await _recorder.StartAsync();
        IsRecording = true;
    }

    private async Task StopRecordAsync()
    {
        Error = null;
        IsProcessing = true;

        var path = await _recorder.StopAsync();
        IsRecording = false;

        if (string.IsNullOrWhiteSpace(path))
        {
            IsProcessing = false;
            return;
        }

        try
        {
            var text = await _speechService.UploadAndTranscribeAsync(
                path,
                "https://ipaas.catl.com/gateway/outside/ipaas/LY_BASIC/outer_LY_BASIC_voiceToText");
            Transcript = text.Trim();
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

    private void Confirm()
    {
        ResultText = Transcript;
        CloseRequested?.Invoke();
    }

    private void Cancel()
    {
        ResultText = null;
        CloseRequested?.Invoke();
    }
}
