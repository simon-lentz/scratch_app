import 'package:checkplan/core/database/app_database.dart';

/// A `(done, total)` count pair.
typedef Progress = (int done, int total);

/// A checklist plus its task-completion progress from an aggregate query.
class ChecklistSummary {
  /// Pairs a checklist row with its computed task progress.
  const ChecklistSummary({required this.checklist, required this.progress});

  /// The checklist row this summary describes.
  final Checklist checklist;

  /// Tasks done out of total for the checklist.
  final Progress progress;
}

/// A task plus its subtask `(done, total)` counts
///
/// `(0, 0)` indicates no subtasks.
class TaskView {
  /// Pairs a task row with its computed subtask progress.
  const TaskView({required this.task, required this.subtaskProgress});

  /// The task row this view describes.
  final Task task;

  /// Subtasks done out of total for the task.
  final Progress subtaskProgress;
}

/// A due task surfaced in the Today view, with its parent checklist's title.
class TodayTask {
  /// Pairs a due task with the title of its owning checklist.
  const TodayTask({required this.task, required this.checklistTitle});

  /// The due task surfaced in the Today view.
  final Task task;

  /// Title of the checklist that owns the task.
  final String checklistTitle;
}

/// Incomplete due tasks partitioned by the Today boundary.
class TodayBuckets {
  /// Groups due tasks into overdue and due-today partitions.
  const TodayBuckets({required this.overdue, required this.dueToday});

  /// Tasks whose due date is before today.
  final List<TodayTask> overdue;

  /// Tasks whose due date is today.
  final List<TodayTask> dueToday;
}
