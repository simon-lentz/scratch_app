import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/widgets/labeled_checkbox.dart';
import 'package:flutter/material.dart';

/// A single subtask row: a done checkbox, the title, and a delete button.
///
/// A leaf widget that takes its data and callbacks as parameters.
class SubtaskTile extends StatelessWidget {
  /// Creates a subtask row from [subtask] and its callbacks.
  const SubtaskTile({
    required this.subtask,
    required this.onToggleDone,
    required this.onRename,
    required this.onDelete,
    this.dragHandle,
    super.key,
  });

  /// The subtask row this tile shows.
  final Subtask subtask;

  /// Invoked with the new done-state when the checkbox is toggled.
  final ValueChanged<bool> onToggleDone;

  /// Invoked when the user taps the row to rename the subtask.
  final VoidCallback onRename;

  /// Invoked when the user taps delete.
  final VoidCallback onDelete;

  /// An optional drag affordance rendered before the delete button — supplied
  /// by a reorderable parent (a [ReorderableDragStartListener]); null when the
  /// row is not reorderable.
  final Widget? dragHandle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 32, right: 8),
      onTap: onRename,
      leading: LabeledCheckbox(
        label: toggleDoneLabel(subtask.title),
        value: subtask.isDone,
        onChanged: onToggleDone,
      ),
      title: Text(subtask.title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?dragHandle,
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Delete subtask',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
