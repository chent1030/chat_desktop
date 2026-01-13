import '../models/dispatch_candidate.dart';
import 'dart:convert';

/// 语音创建任务：抽取结果
class VoiceTaskDraft {
  final String title;
  final String description;
  final DateTime? dueDate; // 本地时区（yyyy-MM-dd HH:mm）
  final bool dispatchNow;
  final String? assignedToType; // 用户 / 团队
  final String? assignedTo; // empName 或 workGroup
  final String? assignedToEmpNo; // 当选择用户时使用
  final String? originalDispatchTarget; // 原始提取的派发对象文本（用于提示）
  final String? ignoredTimeHint; // 如“下午3点”，V1 不入 dueDate

  const VoiceTaskDraft({
    required this.title,
    required this.description,
    this.dueDate,
    this.dispatchNow = false,
    this.assignedToType,
    this.assignedTo,
    this.assignedToEmpNo,
    this.originalDispatchTarget,
    this.ignoredTimeHint,
  });
}

/// 语音创建任务：关键信息抽取（V1）
///
/// 说明：
/// - 优先做可解释的本地规则抽取，用户可在表单里二次修改
/// - `dueDate` 保存到分钟（yyyy-MM-dd HH:mm），若语音仅提到日期则时间默认为 00:00
class TaskVoiceExtractionService {
  static const List<String> _dispatchKeywords = [
    '派发给',
    '派给',
    '分配给',
    '指派给',
    '发给',
    '交给',
  ];

  // 隐式派发：语音里常见“让张三...”“通知李四...”“提醒运维团队...”
  static const List<String> _implicitDispatchKeywords = [
    '让',
    '通知',
    '提醒',
    '叫',
  ];

  /// 规则抽取（无网络/大模型失败时兜底）
  VoiceTaskDraft extractWithRules({
    required String transcript,
    required DateTime now,
    required List<DispatchCandidate> candidates,
  }) {
    final cleaned = transcript.trim();
    final dueDate = _extractDueDate(cleaned, now: now);
    final ignoredTimeHint = _extractTimeHint(cleaned);

    final title = _extractTitle(cleaned);
    var description = _extractDescription(cleaned);

    if (ignoredTimeHint != null && ignoredTimeHint.isNotEmpty) {
      if (!description.contains(ignoredTimeHint)) {
        description =
            '$description\n\n- 截止时间提示：$ignoredTimeHint（当前保存格式 `yyyy-MM-dd HH:mm`）';
      }
    }

    final dispatchTarget = _extractDispatchTarget(cleaned);
    final dispatchMatch = _matchDispatchTarget(dispatchTarget, candidates: candidates);

    return VoiceTaskDraft(
      title: title,
      description: description,
      dueDate: dueDate,
      dispatchNow: dispatchMatch.dispatchNow,
      assignedToType: dispatchMatch.assignedToType,
      assignedTo: dispatchMatch.assignedTo,
      assignedToEmpNo: dispatchMatch.assignedToEmpNo,
      originalDispatchTarget: dispatchTarget,
      ignoredTimeHint: ignoredTimeHint,
    );
  }

  /// 从大模型返回的文本中解析并转换为任务草稿（不在此处发起网络请求）
  VoiceTaskDraft extractFromModelAnswer({
    required String modelAnswer,
    required String transcript,
    required DateTime now,
    required List<DispatchCandidate> candidates,
  }) {
    final json = _extractJsonObject(modelAnswer);
    final fields = _parseLlmFields(json);
    return _convertLlmFieldsToDraft(
      fields,
      transcript: transcript,
      now: now,
      candidates: candidates,
    );
  }

  String _extractJsonObject(String raw) {
    final text = raw.trim();
    if (text.isEmpty) throw const FormatException('大模型返回为空');

    // 直接就是 JSON
    if (text.startsWith('{') && text.endsWith('}')) return text;

    // 从混杂文本中截取第一段 {...}
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw const FormatException('大模型返回中未找到 JSON 对象');
    }
    return text.substring(start, end + 1);
  }

  _LlmFields _parseLlmFields(String jsonText) {
    final decoded = jsonDecode(jsonText);
    if (decoded is! Map) throw const FormatException('大模型 JSON 不是对象');
    final map = Map<String, dynamic>.from(decoded as Map);

    String? stringOrNull(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    bool boolOrFalse(dynamic v) {
      if (v is bool) return v;
      final s = v?.toString().toLowerCase();
      return s == 'true' || s == '1';
    }

    return _LlmFields(
      title: stringOrNull(map['title']),
      description: stringOrNull(map['description']) ?? '',
      dueDate: stringOrNull(map['dueDate']),
      dispatchNow: boolOrFalse(map['dispatchNow']),
      assignedToType: stringOrNull(map['assignedToType']),
      assignedTo: stringOrNull(map['assignedTo']),
      timeHint: stringOrNull(map['timeHint']),
    );
  }

  VoiceTaskDraft _convertLlmFieldsToDraft(
    _LlmFields fields, {
    required String transcript,
    required DateTime now,
    required List<DispatchCandidate> candidates,
  }) {
    final title = (fields.title ?? '').trim();
    final safeTitle = title.isEmpty ? _extractTitle(transcript) : title;

    DateTime? dueDate;
    if (fields.dueDate != null) {
      dueDate = _parseDueDate(fields.dueDate!, fallbackNow: now);
    }

    var description = fields.description;
    if (fields.timeHint != null && fields.timeHint!.isNotEmpty) {
      if (!description.contains(fields.timeHint!)) {
        description =
            '$description\n\n- 截止时间提示：${fields.timeHint}（当前保存格式 `yyyy-MM-dd HH:mm`）';
      }
    }

    // 派发对象：如果模型给了派发对象信息，即使 dispatchNow=false 也优先回填，避免 UI 不展示；
    // 另外语音里常见“给张三创建一个待办”这种表达，模型若漏抽取，也应从原文兜底识别派发对象。
    final fallbackTarget = _extractDispatchTarget(transcript);
    final fallbackMatch =
        _matchDispatchTarget(fallbackTarget, candidates: candidates);
    final shouldDispatch = fields.dispatchNow ||
        ((fields.assignedToType != null &&
                fields.assignedToType!.trim().isNotEmpty) &&
            (fields.assignedTo != null &&
                fields.assignedTo!.trim().isNotEmpty)) ||
        fallbackMatch.dispatchNow;

    // 派发对象：优先使用模型给的 type + target，否则走原先规则抽取
    final dispatchTarget = fields.assignedTo;
    final match = (shouldDispatch && fields.assignedToType != null)
        ? _matchByTypedTarget(
            type: fields.assignedToType!,
            target: dispatchTarget,
            candidates: candidates,
          )
        : _matchDispatchTarget(
            fallbackTarget ?? dispatchTarget,
            candidates: candidates,
          );

    return VoiceTaskDraft(
      title: safeTitle.length <= 50 ? safeTitle : safeTitle.substring(0, 50),
      description: description,
      dueDate: dueDate ?? _extractDueDate(transcript, now: now),
      dispatchNow: shouldDispatch ? match.dispatchNow : false,
      assignedToType: shouldDispatch ? match.assignedToType : null,
      assignedTo: shouldDispatch ? match.assignedTo : null,
      assignedToEmpNo: shouldDispatch ? match.assignedToEmpNo : null,
      originalDispatchTarget: dispatchTarget ?? _extractDispatchTarget(transcript),
      ignoredTimeHint: fields.timeHint,
    );
  }

  _DispatchMatch _matchByTypedTarget({
    required String type,
    required String? target,
    required List<DispatchCandidate> candidates,
  }) {
    final t = target?.trim();
    if (t == null || t.isEmpty) return const _DispatchMatch.none();

    if (type == '团队') {
      final workGroups = candidates
          .map((e) => e.workGroup)
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet();
      if (workGroups.contains(t)) return _DispatchMatch.team(workGroup: t);

      final hit = workGroups.firstWhere(
        (g) => g.contains(t) || t.contains(g),
        orElse: () => '',
      );
      return hit.isNotEmpty ? _DispatchMatch.team(workGroup: hit) : _DispatchMatch.unknown(target: t);
    }

    if (type == '用户') {
      // 兼容：模型可能直接返回工号（empNo）
      final byEmpNo = candidates.where((e) => e.empNo == t).toList();
      if (byEmpNo.length == 1) {
        return _DispatchMatch.user(
          empName: byEmpNo.first.empName,
          empNo: byEmpNo.first.empNo,
        );
      }

      final matched = candidates.where((e) => e.empName == t).toList();
      if (matched.length == 1) {
        return _DispatchMatch.user(empName: matched.first.empName, empNo: matched.first.empNo);
      }
      if (matched.isNotEmpty) {
        return _DispatchMatch.userAmbiguous(empName: t);
      }
      return _DispatchMatch.unknown(target: t);
    }

    return const _DispatchMatch.none();
  }

  String _extractTitle(String transcript) {
    final text = transcript.trim();
    if (text.isEmpty) return '新任务';

    // 取第一句作为标题，去掉常见的口头前缀
    final firstSentence = _splitSentences(text).first.trim();
    final normalized = firstSentence
        .replaceFirst(RegExp(r'^(帮我|请|麻烦|我要|我想|创建|新建)\s*'), '')
        .replaceFirst(RegExp(r'^(一个|一条)?\s*(任务|待办|事项)\s*[:：]?\s*'), '')
        .trim();

    if (normalized.isEmpty) {
      return text.length <= 20 ? text : text.substring(0, 20);
    }
    return normalized.length <= 50 ? normalized : normalized.substring(0, 50);
  }

  String _extractDescription(String transcript) {
    final text = transcript.trim();
    if (text.isEmpty) return '';

    // 如果有“描述/内容/备注”等标记，优先取后面的段落
    final marker = RegExp(r'(描述|内容|备注)\s*[:：]\s*', caseSensitive: false);
    final match = marker.firstMatch(text);
    if (match != null) {
      final desc = text.substring(match.end).trim();
      if (desc.isNotEmpty) return desc;
    }

    return text;
  }

  List<String> _splitSentences(String text) {
    final sentences = text
        .split(RegExp(r'[。！？!\n\r]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    if (sentences.isEmpty) return [text.trim()];
    return sentences;
  }

  DateTime? _extractDueDate(String text, {required DateTime now}) {
    final time = _extractTimeOfDay(text);

    // yyyy-MM-dd / yyyy/MM/dd / yyyy年M月d日
    final full = RegExp(
      r'(\d{4})\s*[-/.年]\s*(\d{1,2})\s*[-/.月]\s*(\d{1,2})\s*(日)?',
    );
    final fullMatch = full.firstMatch(text);
    if (fullMatch != null) {
      final year = int.tryParse(fullMatch.group(1) ?? '');
      final month = int.tryParse(fullMatch.group(2) ?? '');
      final day = int.tryParse(fullMatch.group(3) ?? '');
      if (year != null && month != null && day != null) {
        return DateTime(year, month, day, time?.hour ?? 0, time?.minute ?? 0);
      }
    }

    // M月d日（默认当年）
    final md = RegExp(r'(\d{1,2})\s*月\s*(\d{1,2})\s*日?');
    final mdMatch = md.firstMatch(text);
    if (mdMatch != null) {
      final month = int.tryParse(mdMatch.group(1) ?? '');
      final day = int.tryParse(mdMatch.group(2) ?? '');
      if (month != null && day != null) {
        return DateTime(
          now.year,
          month,
          day,
          time?.hour ?? 0,
          time?.minute ?? 0,
        );
      }
    }

    // 相对日期
    if (text.contains('今天')) {
      return DateTime(now.year, now.month, now.day, time?.hour ?? 0, time?.minute ?? 0);
    }
    if (text.contains('明天')) {
      final d = now.add(const Duration(days: 1));
      return DateTime(d.year, d.month, d.day, time?.hour ?? 0, time?.minute ?? 0);
    }
    if (text.contains('后天')) {
      final d = now.add(const Duration(days: 2));
      return DateTime(d.year, d.month, d.day, time?.hour ?? 0, time?.minute ?? 0);
    }
    if (text.contains('大后天')) {
      final d = now.add(const Duration(days: 3));
      return DateTime(d.year, d.month, d.day, time?.hour ?? 0, time?.minute ?? 0);
    }

    // 周几（默认找最近的未来那一天；如果写了“下周”，则至少+7天）
    final weekdayMatch = RegExp(r'(本周|这周|下周|周|星期)\s*([一二三四五六日天])')
        .firstMatch(text);
    if (weekdayMatch != null) {
      final prefix = weekdayMatch.group(1) ?? '';
      final cn = weekdayMatch.group(2) ?? '';
      final targetWeekday = _cnWeekdayToInt(cn);
      if (targetWeekday != null) {
        final base = DateTime(now.year, now.month, now.day);
        var diff = targetWeekday - base.weekday;
        if (diff <= 0) diff += 7;
        if (prefix.contains('下周')) diff += 7;
        final d = base.add(Duration(days: diff));
        return DateTime(d.year, d.month, d.day, time?.hour ?? 0, time?.minute ?? 0);
      }
    }

    return null;
  }

  DateTime? _parseDueDate(String raw, {required DateTime fallbackNow}) {
    final text = raw.trim();
    // yyyy-MM-dd HH:mm
    final dt = RegExp(r'^(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2})$')
        .firstMatch(text);
    if (dt != null) {
      final year = int.tryParse(dt.group(1)!);
      final month = int.tryParse(dt.group(2)!);
      final day = int.tryParse(dt.group(3)!);
      final hour = int.tryParse(dt.group(4)!);
      final minute = int.tryParse(dt.group(5)!);
      if (year != null &&
          month != null &&
          day != null &&
          hour != null &&
          minute != null) {
        return DateTime(year, month, day, hour, minute);
      }
    }
    // 兼容旧 yyyy-MM-dd
    final d = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
    if (d != null) {
      final year = int.tryParse(d.group(1)!);
      final month = int.tryParse(d.group(2)!);
      final day = int.tryParse(d.group(3)!);
      if (year != null && month != null && day != null) {
        return DateTime(year, month, day, 0, 0);
      }
    }
    // 兜底：尝试按语音规则解析
    return _extractDueDate(text, now: fallbackNow);
  }

  int? _cnWeekdayToInt(String cn) {
    switch (cn) {
      case '一':
        return DateTime.monday;
      case '二':
        return DateTime.tuesday;
      case '三':
        return DateTime.wednesday;
      case '四':
        return DateTime.thursday;
      case '五':
        return DateTime.friday;
      case '六':
        return DateTime.saturday;
      case '日':
      case '天':
        return DateTime.sunday;
      default:
        return null;
    }
  }

  String? _extractTimeHint(String text) {
    // 仅作为描述补充，不入 dueDate
    final m = RegExp(r'((上午|中午|下午|晚上|凌晨)\s*)?(\d{1,2})\s*(点|:)\s*(\d{1,2})?\s*(分)?')
        .firstMatch(text);
    if (m == null) return null;
    return m.group(0)?.trim();
  }

  ({int hour, int minute})? _extractTimeOfDay(String text) {
    final m = RegExp(r'((上午|中午|下午|晚上|凌晨)\s*)?(\d{1,2})\s*(点|:)\s*(\d{1,2})?\s*(分)?')
        .firstMatch(text);
    if (m == null) return null;
    final rawHour = int.tryParse(m.group(3) ?? '');
    final rawMinute = int.tryParse(m.group(5) ?? '') ?? 0;
    if (rawHour == null) return null;
    var hour = rawHour;
    final period = (m.group(2) ?? '').trim();
    if (period == '下午' || period == '晚上') {
      if (hour < 12) hour += 12;
    }
    if (period == '凌晨' && hour == 12) hour = 0;
    if (hour < 0 || hour > 23) return null;
    if (rawMinute < 0 || rawMinute > 59) return null;
    return (hour: hour, minute: rawMinute);
  }

  String? _extractDispatchTarget(String text) {
    // 常见口语：给/帮某人创建待办（例如“给张三创建一个待办”）
    final giveCreate = RegExp(
      r'(给|帮|替)\s*([^\s，。；;,.\\n]{1,20}?)\s*(创建|新建|建|安排)\s*(一个|一条)?\s*(任务|待办|事项)',
    ).firstMatch(text);
    if (giveCreate != null) {
      final token = (giveCreate.group(2) ?? '').trim();
      if (token.isNotEmpty) return token;
    }
    final giveTodo = RegExp(
      r'(给|帮|替)\s*([^\s，。；;,.\\n]{1,20}?)\s*(一个|一条)?\s*(任务|待办|事项)',
    ).firstMatch(text);
    if (giveTodo != null) {
      final token = (giveTodo.group(2) ?? '').trim();
      if (token.isNotEmpty) return token;
    }

    // 隐式派发：让/通知/提醒/叫 + 对象
    for (final keyword in _implicitDispatchKeywords) {
      final idx = text.indexOf(keyword);
      if (idx >= 0) {
        final rest = text.substring(idx + keyword.length).trim();
        final token = _takeTargetToken(rest);
        if (token == null) continue;
        if (token == '我' || token == '自己' || token == '本人') continue;
        return token;
      }
    }

    // 先找明确关键词
    for (final keyword in _dispatchKeywords) {
      final idx = text.indexOf(keyword);
      if (idx >= 0) {
        final rest = text.substring(idx + keyword.length).trim();
        return _takeTargetToken(rest);
      }
    }

    // 兜底：存在“派发”但没写关键词，先不自动派发
    if (text.contains('派发') || text.contains('分配') || text.contains('指派')) {
      return null;
    }

    return null;
  }

  String? _takeTargetToken(String text) {
    if (text.isEmpty) return null;
    // 截断规则：尽可能只保留“目标对象”（人名/团队名/工号），遇到时间/动作/标点就停止
    final stop = RegExp(
      r'(，|。|；|;|,|\.|\n|截止|到期|描述|内容|备注|今天|明天|后天|大后天|本周|这周|下周|周|星期|上午|中午|下午|晚上|凌晨|\d{1,2}\s*(点|:)\s*\d{0,2}|去|来|做|处理|完成|参加|开会|联系|跟进|安排|检查|修复|解决)',
    );
    final match = stop.firstMatch(text);
    final token = (match == null ? text : text.substring(0, match.start)).trim();
    if (token.isEmpty) return null;

    // 去掉常见尾缀
    return token.replaceAll(RegExp(r'^(给|到)\s*'), '').trim();
  }

  _DispatchMatch _matchDispatchTarget(
    String? dispatchTarget, {
    required List<DispatchCandidate> candidates,
  }) {
    if (dispatchTarget == null || dispatchTarget.trim().isEmpty) {
      return const _DispatchMatch.none();
    }

    final target = dispatchTarget.trim();
    final usersByName = <String, List<DispatchCandidate>>{};
    for (final c in candidates) {
      usersByName.putIfAbsent(c.empName, () => []).add(c);
    }

    // 0) 若目标是工号，优先按 empNo 匹配
    final byEmpNo = candidates.where((e) => e.empNo == target).toList();
    if (byEmpNo.length == 1) {
      final u = byEmpNo.first;
      return _DispatchMatch.user(empName: u.empName, empNo: u.empNo);
    }

    // 1) 先按用户姓名精确匹配
    final matchedUsers = usersByName[target];
    if (matchedUsers != null && matchedUsers.isNotEmpty) {
      if (matchedUsers.length == 1) {
        final u = matchedUsers.first;
        return _DispatchMatch.user(empName: u.empName, empNo: u.empNo);
      }
      // 同名：需要用户在下拉里选择具体工号
      return _DispatchMatch.userAmbiguous(empName: target);
    }

    // 2) 再按团队 workGroup 精确匹配
    final workGroups = candidates
        .map((e) => e.workGroup)
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    if (workGroups.contains(target)) {
      return _DispatchMatch.team(workGroup: target);
    }

    // 3) 模糊：如果文本包含“团队/组”，优先尝试团队包含匹配
    if (target.contains('团队') || target.contains('组')) {
      final hit = workGroups.firstWhere(
        (g) => g.contains(target) || target.contains(g),
        orElse: () => '',
      );
      if (hit.isNotEmpty) return _DispatchMatch.team(workGroup: hit);
    }

    // 4) 无法匹配：仍视为用户想派发，但需要手动选择
    return _DispatchMatch.unknown(target: target);
  }
}

class _LlmFields {
  final String? title;
  final String description;
  final String? dueDate;
  final bool dispatchNow;
  final String? assignedToType;
  final String? assignedTo;
  final String? timeHint;

  const _LlmFields({
    required this.title,
    required this.description,
    required this.dueDate,
    required this.dispatchNow,
    required this.assignedToType,
    required this.assignedTo,
    required this.timeHint,
  });
}

class _DispatchMatch {
  final bool dispatchNow;
  final String? assignedToType;
  final String? assignedTo;
  final String? assignedToEmpNo;

  const _DispatchMatch._({
    required this.dispatchNow,
    this.assignedToType,
    this.assignedTo,
    this.assignedToEmpNo,
  });

  const _DispatchMatch.none() : this._(dispatchNow: false);

  factory _DispatchMatch.user({required String empName, required String empNo}) {
    return _DispatchMatch._(
      dispatchNow: true,
      assignedToType: '用户',
      assignedTo: empName,
      assignedToEmpNo: empNo,
    );
  }

  factory _DispatchMatch.userAmbiguous({required String empName}) {
    return _DispatchMatch._(
      dispatchNow: true,
      assignedToType: '用户',
      assignedTo: empName,
      assignedToEmpNo: null,
    );
  }

  factory _DispatchMatch.team({required String workGroup}) {
    return _DispatchMatch._(
      dispatchNow: true,
      assignedToType: '团队',
      assignedTo: workGroup,
      assignedToEmpNo: null,
    );
  }

  factory _DispatchMatch.unknown({required String target}) {
    return _DispatchMatch._(
      dispatchNow: true,
      assignedToType: null,
      assignedTo: null,
      assignedToEmpNo: null,
    );
  }
}
