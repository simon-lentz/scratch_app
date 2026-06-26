import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/model/due_status.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:checkplan/core/widgets/due_date_chip.dart';
import 'package:flutter/material.dart';

/// A single task row: a done checkbox, the title, a due-date chip when the task
/// has a due date, and a subtask-progress hint when it has subtasks.
///
/// A leaf widget that takes its data and callbacks as parameters and reads no
/// providers; [today] is supplied so it can classify the due date.
class TaskTile extends StatelessWidget {
  /// Creates a task row from [view], the current day [today], and callbacks.
  const TaskTile({
    required this.view,
    required this.today,
    required this.onToggleDone,
    required this.onEdit,
    required this.expanded,
    required this.onToggleExpanded,
    super.key,
  });

  /// The task and its subtask progress.
  final TaskView view;

  /// Today's calendar day, used to classify [TaskView.task]'s due date.
  final EpochDay today;

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
    final status = dueStatusFor(view.task.dueDay, today);
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
      // No chip for a task without a due date.
      subtitle: status is NoDueDate
          ? null
          : Align(
              alignment: Alignment.centerLeft,
              child: DueDateChip(status: status),
            ),
      // (0, 0) -> no subtasks -> no hint.
      trailing: total == 0 ? null : Text('$done/$total'),
    );
  }
}
