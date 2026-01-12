import 'task.dart';

/// 任务分页返回（Unify API）
class TaskPageResult {
  final int totalPages;
  final int totalElements;
  final int numberOfElements;
  final int size;
  final int number; // 当前页号（后端返回，0 开始）
  final List<Task> content;

  const TaskPageResult({
    required this.totalPages,
    required this.totalElements,
    required this.numberOfElements,
    required this.size,
    required this.number,
    required this.content,
  });
}

