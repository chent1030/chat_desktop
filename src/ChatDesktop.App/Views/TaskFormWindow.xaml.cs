using System.Windows;
using ChatDesktop.App.ViewModels;
using ChatDesktop.Core.Services.Voice;
using ChatDesktop.Infrastructure.AI;
using ChatDesktop.Infrastructure.Http;
using ChatDesktop.Infrastructure.Voice;

namespace ChatDesktop.App.Views;

/// <summary>
/// 任务表单窗口
/// </summary>
public partial class TaskFormWindow : Window
{
    public TaskFormWindow(TaskFormViewModel viewModel)
    {
        InitializeComponent();
        DataContext = viewModel;
        viewModel.CloseRequested += OnCloseRequested;
    }

    private async void OnLoaded(object sender, RoutedEventArgs e)
    {
        if (DataContext is TaskFormViewModel viewModel)
        {
            await viewModel.InitializeAsync();
        }
    }

    private void OnCloseRequested()
    {
        Close();
    }

    private void OnVoiceTitleClicked(object sender, RoutedEventArgs e)
    {
        _ = ApplyVoiceInputAsync(isTitle: true);
    }

    private void OnVoiceDescriptionClicked(object sender, RoutedEventArgs e)
    {
        _ = ApplyVoiceInputAsync(isTitle: false);
    }

    private Task ApplyVoiceInputAsync(bool isTitle)
    {
        if (DataContext is not TaskFormViewModel viewModel)
        {
            return Task.CompletedTask;
        }

        var recorder = new AudioRecorderService();
        var speechService = new SpeechToTextService();
        var inputVm = new VoiceInputViewModel(recorder, speechService);
        var window = new VoiceInputWindow(inputVm)
        {
            Owner = this
        };
        window.ShowDialog();

        if (!string.IsNullOrWhiteSpace(inputVm.ResultText))
        {
            if (isTitle)
            {
                viewModel.Title = inputVm.ResultText!;
            }
            else
            {
                viewModel.Description = inputVm.ResultText!;
            }
        }

        return Task.CompletedTask;
    }

    private void OnPickDueDateTimeClicked(object sender, RoutedEventArgs e)
    {
        if (DataContext is not TaskFormViewModel viewModel)
        {
            return;
        }

        var window = new DateTimePickerWindow(viewModel.DueDate, "选择截止时间")
        {
            Owner = this
        };
        if (window.ShowDialog() == true)
        {
            viewModel.DueDate = window.SelectedDateTime;
        }
    }

    private void OnVoiceCreateClicked(object sender, RoutedEventArgs e)
    {
        if (DataContext is not TaskFormViewModel viewModel || viewModel.IsEditing)
        {
            return;
        }

        var recorder = new AudioRecorderService();
        var speechService = new SpeechToTextService();
        var extractor = new TaskVoiceExtractionService();
        var workflowService = new AiWorkflowService(new SseClient());
        var configService = new AiConfigService();

        var draftVm = new VoiceTaskViewModel(
            recorder,
            speechService,
            viewModel.TaskService,
            extractor,
            workflowService,
            configService,
            viewModel.RemoteService,
            viewModel.CurrentEmpNo,
            isDraftMode: true);

        VoiceTaskDraft? appliedDraft = null;
        draftVm.DraftApplied += draft => appliedDraft = draft;

        var window = new VoiceTaskWindow(draftVm)
        {
            Owner = this
        };
        window.ShowDialog();

        if (appliedDraft == null)
        {
            return;
        }

        viewModel.Title = appliedDraft.Title;
        viewModel.Description = appliedDraft.Description;
        viewModel.DueDate = appliedDraft.DueDate;

        if (!string.IsNullOrWhiteSpace(appliedDraft.AssignedToType))
        {
            viewModel.AssignedToType = appliedDraft.AssignedToType;
        }

        if (appliedDraft.AssignedToType == "用户")
        {
            viewModel.SelectedUserEmpNo = appliedDraft.AssignedToEmpNo ?? appliedDraft.AssignedTo;
        }
        else if (appliedDraft.AssignedToType == "团队")
        {
            viewModel.SelectedTeam = appliedDraft.AssignedTo;
        }
    }
}
