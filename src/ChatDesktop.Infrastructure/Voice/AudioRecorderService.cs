using NAudio.Wave;

namespace ChatDesktop.Infrastructure.Voice;

/// <summary>
/// 录音服务
/// </summary>
public sealed class AudioRecorderService
{
    private WaveInEvent? _waveIn;
    private WaveFileWriter? _writer;
    private string? _currentPath;

    public bool IsRecording { get; private set; }

    public Task<string> StartAsync()
    {
        if (IsRecording)
        {
            throw new InvalidOperationException("正在录音中");
        }

        var fileName = $"voice_{DateTime.Now:yyyyMMdd_HHmmss}.wav";
        var path = Path.Combine(Path.GetTempPath(), fileName);

        _waveIn = new WaveInEvent
        {
            WaveFormat = new WaveFormat(44100, 1)
        };

        _writer = new WaveFileWriter(path, _waveIn.WaveFormat);
        _waveIn.DataAvailable += (_, args) => _writer?.Write(args.Buffer, 0, args.BytesRecorded);
        _waveIn.RecordingStopped += (_, _) => _writer?.Dispose();

        _waveIn.StartRecording();
        _currentPath = path;
        IsRecording = true;
        return Task.FromResult(path);
    }

    public Task<string?> StopAsync()
    {
        if (!IsRecording)
        {
            return Task.FromResult<string?>(null);
        }

        _waveIn?.StopRecording();
        _waveIn?.Dispose();
        _waveIn = null;
        _writer = null;
        IsRecording = false;

        return Task.FromResult(_currentPath);
    }

    public Task CancelAsync()
    {
        if (IsRecording)
        {
            _waveIn?.StopRecording();
            _waveIn?.Dispose();
            _waveIn = null;
            _writer = null;
            IsRecording = false;
        }

        if (!string.IsNullOrWhiteSpace(_currentPath) && File.Exists(_currentPath))
        {
            File.Delete(_currentPath);
        }

        _currentPath = null;
        return Task.CompletedTask;
    }
}
