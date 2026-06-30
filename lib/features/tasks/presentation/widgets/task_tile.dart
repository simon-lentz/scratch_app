import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/model/due_status.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:checkplan/core/widgets/due_date_chip.dart';
import 'package:checkplan/core/widgets/labeled_checkbox.dart';
import 'package:checkplan/core/widgets/notes_preview.dart';
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
    this.dragHandle,
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

  /// An optional drag affordance rendered after the progress hint — supplied by
  /// a reorderable parent (a [ReorderableDragStartListener]) on platforms that
  /// need a visible handle; null when the row drags by long-press.
  final Widget? dragHandle;

  @override
  Widget build(BuildContext context) {
    final (done, total) = view.subtaskProgress;
    final status = dueStatusFor(view.task.dueDay, today);
    final notes = displayNotes(view.task.notes);
    return ListTile(
      onTap: onEdit,
      isThreeLine: notes.isNotEmpty,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
            tooltip: expanded ? 'Hide subtasks' : 'Show subtasks',
            onPressed: onToggleExpanded,
          ),
          LabeledCheckbox(
            label: toggleDoneLabel(view.task.title),
            value: view.task.isDone,
            onChanged: onToggleDone,
          ),
        ],
      ),
      title: Text(view.task.title),
      subtitle: _subtitle(status, notes),
      trailing: _trailing(done, total),
    );
  }

  // The subtask-progress hint (none when the task has no subtasks), plus an
  // optional drag grip from a reorderable parent. With no grip — every golden
  // seed — this returns exactly the prior trailing (null or the lone hint), so
  // the tile goldens are unchanged.
  Widget? _trailing(int done, int total) {
    final hint = total == 0 ? null : Text('$done/$total');
    final handle = dragHandle;
    if (handle == null) return hint;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [?hint, handle],
    );
  }

  // The due chip (when present) plus a one-line notes preview. With no notes
  // it returns exactly the prior subtitle (null or the lone chip), so the
  // existing tile goldens render unchanged.
  Widget? _subtitle(DueStatus status, String notes) {
    final dueChip = status is NoDueDate
        ? null
        : Align(
            alignment: Alignment.centerLeft,
            child: DueDateChip(status: status),
          );
    if (notes.isEmpty) return dueChip;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ?dueChip,
        NotesPreview(notes),
      ],
    );
  }
}
