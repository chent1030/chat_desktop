namespace ChatDesktop.Core.Constants;

/// <summary>
/// 环境变量键名
/// </summary>
public static class ConfigKeys
{
    public const string Debug = "DEBUG";

    public const string UnifyApiBaseUrl = "UNIFY_API_BASE_URL";
    public const string UnifyCreateTaskPath = "UNIFY_API_CREATE_TASK_PATH";
    public const string UnifyTaskReadPath = "UNIFY_API_TASK_READ_PATH";
    public const string UnifyTaskCompletePath = "UNIFY_API_TASK_COMPLETE_PATH";
    public const string UnifyTaskListPath = "UNIFY_API_TASK_LIST_PATH";
    public const string UnifyDispatchCandidatesPath = "UNIFY_API_DISPATCH_CANDIDATES_PATH";
    public const string UnifyEmpNoCheckPath = "UNIFY_API_EMP_NO_CHECK_PATH";

    public const string ApiBaseUrl = "API_BASE_URL";
    public const string ApiToken = "API_TOKEN";

    public const string AiApiUrl = "AI_API_URL";
    public const string AiSseUrl = "AI_SSE_URL";
    public const string AiApiKey = "AI_API_KEY";
    public const string AiApiKeyXinService = "AI_API_KEY_XIN_SERVICE";
    public const string AiApiKeyLocalQa = "AI_API_KEY_LOCAL_QA";

    public const string AiTaskExtractApiUrl = "AI_API_URL_TASK_EXTRACT";
    public const string AiTaskExtractSseUrl = "AI_SSE_URL_TASK_EXTRACT";
    public const string AiTaskExtractApiKey = "AI_API_KEY_TASK_EXTRACT";

    public const string MqttBrokerHost = "MQTT_BROKER_HOST";
    public const string MqttBrokerPort = "MQTT_BROKER_PORT";
    public const string MqttUsername = "MQTT_USERNAME";
    public const string MqttPassword = "MQTT_PASSWORD";
    public const string MqttSessionExpirySeconds = "MQTT_SESSION_EXPIRY_SECONDS";
    public const string MqttTopics = "MQTT_TOPICS";

    public const string DeviceId = "DEVICE_ID";
    public const string WebSocketUrl = "WEBSOCKET_URL";
    public const string OutlookPathWindows = "OUTLOOK_PATH_WINDOWS";
    public const string DingTalkPathWindows = "DINGTALK_PATH_WINDOWS";
    public const string OpenAiApiKey = "OPENAI_API_KEY";
    public const string AnthropicApiKey = "ANTHROPIC_API_KEY";
}
