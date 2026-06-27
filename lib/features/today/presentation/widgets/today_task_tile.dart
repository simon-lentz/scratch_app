import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/model/due_status.dart';
import 'package:checkplan/core/widgets/due_date_chip.dart';
import 'package:flutter/material.dart';

/// A single Today row: a done checkbox, the task title, its parent checklist,
/// and an optional due-date chip. Checking it off completes the task, which
/// removes it from Today.
///
/// A leaf widget that takes its data and callback as parameters and reads no
/// providers.
class TodayTaskTile extends StatelessWidget {
  /// Creates a Today row from [entry], with an optional due-[status] chip.
  const TodayTaskTile({
    required this.entry,
    required this.onToggleDone,
    this.status,
    super.key,
  });

  /// The due task and the title of its parent checklist.
  final TodayTask entry;

  /// Invoked with the new done-state when the checkbox is toggled.
  final ValueChanged<bool> onToggleDone;

  /// The due status to show as a chip, or null to omit it — the Today section
  /// omits the chip because its header already says the tasks are due today.
  final DueStatus? status;

  @override
  Widget build(BuildContext context) {
    final status = this.status;
    return ListTile(
      leading: MergeSemantics(
        child: Semantics(
          label: 'Toggle "${entry.task.title}" done',
          child: Checkbox(
            value: entry.task.isDone,
            onChanged: (value) => onToggleDone(value ?? false),
          ),
        ),
      ),
      title: Text(entry.task.title),
      subtitle: Text(entry.checklistTitle),
      trailing: status == null ? null : DueDateChip(status: status),
    );
  }
}
