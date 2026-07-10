/// Outcome returned by a task page when the user finishes (or bails out).
class TaskResult {
  const TaskResult({required this.completed});

  const TaskResult.success() : completed = true;
  const TaskResult.failed() : completed = false;

  /// True only when the user genuinely completed the task.
  final bool completed;
}
