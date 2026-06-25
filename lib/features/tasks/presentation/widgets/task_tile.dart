import 'package:checkplan/core/database/summaries.dart';
import 'package:flutter/material.dart';

/// A single task row: a done checkbox, the title, and a subtask-progress hint
/// when the task has subtasks.
///
/// A leaf widget that takes its data and callbacks as parameters and reads no
/// providers.
class TaskTile extends StatelessWidget {
  /// Creates a task row from [view] and its toggle callback.
  const TaskTile({
    required this.view,
    required this.onToggleDone,
    required this.onEdit,
    required this.expanded,
    required this.onToggleExpanded,
    super.key,
  });

  /// The task and its subtask progress.
  final TaskView view;

  /// Invoked with the new done-state when the checkbox is toggled.
  final ValueChanged<bool> onToggleDone;

  /// Invoked when the user taps the row to edit the task.
  final VoidCallback onEdit;

  /// Whether this task's subtasks are currently expanded.
  final bool expanded;

  /// Invoked when the user toggles the expand affordance.
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final (done, total) = view.subtaskProgress;
    return ListTile(
      onTap: onEdit,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
            onPressed: onToggleExpanded,
          ),
          Checkbox(
            value: view.task.isDone,
            onChanged: (value) => onToggleDone(value ?? false),
          ),
        ],
      ),
      title: Text(view.task.title),
      // (0, 0) -> no subtasks -> no hint.
      trailing: total == 0 ? null : Text('$done/$total'),
    );
  }
}
