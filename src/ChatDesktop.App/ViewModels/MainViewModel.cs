using ChatDesktop.Core.Interfaces;
using ChatDesktop.Core.Services;
using ChatDesktop.Infrastructure.AI;
using ChatDesktop.Infrastructure.Http;

namespace ChatDesktop.App.ViewModels;

/// <summary>
/// 主窗口 ViewModel
/// </summary>
public sealed class MainViewModel : ViewModelBase
{
    public TaskService TaskListService { get; }
    public ITaskRemoteService TaskRemoteService { get; }
    private string _currentEmpNo;

    public string CurrentEmpNo
    {
        get => _currentEmpNo;
        set
        {
            if (_currentEmpNo == value)
            {
                return;
            }

            _currentEmpNo = value;
            RaisePropertyChanged();
        }
    }
    public TaskListViewModel TaskList { get; }
    public ChatViewModel Chat { get; }

    public MainViewModel(TaskService taskService, ITaskRemoteService taskRemoteService, string currentEmpNo, TaskListViewModel taskList, ChatViewModel chat)
    {
        TaskListService = taskService;
        TaskRemoteService = taskRemoteService;
        _currentEmpNo = currentEmpNo;
        TaskList = taskList;
        Chat = chat;
    }

    public static MainViewModel CreateDefault(TaskService taskService, ITaskRemoteService taskRemoteService, string currentEmpNo, ConversationService conversationService)
    {
        var taskList = new TaskListViewModel(taskService);
        var aiChatService = new AiChatService(new SseClient());
        var aiConfigService = new AiConfigService();
        var chat = new ChatViewModel(conversationService, aiChatService, aiConfigService);
        return new MainViewModel(taskService, taskRemoteService, currentEmpNo, taskList, chat);
    }
}
