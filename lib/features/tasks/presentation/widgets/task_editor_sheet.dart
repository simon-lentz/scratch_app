import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/validation.dart';
import 'package:flutter/material.dart';

/// The edited fields returned by [showTaskEditorSheet].
class TaskDraft {
  /// Wraps the validated, trimmed [title] and optional [notes].
  const TaskDraft({required this.title, this.notes});

  /// The new title (already trimmed and validated).
  final String title;

  /// The new notes, or null to clear them.
  final String? notes;
}

/// Shows the task editor as a modal bottom sheet, pre-filled from [task].
///
/// Returns the edited [TaskDraft] on save, or null if dismissed. Save is
/// disabled while the title is empty or over-length (see: [titleError]).
Future<TaskDraft?> showTaskEditorSheet(
  BuildContext context, {
  required Task task,
}) {
  return showModalBottomSheet<TaskDraft>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _TaskEditorSheet(task: task),
  );
}

class _TaskEditorSheet extends StatefulWidget {
  const _TaskEditorSheet({required this.task});

  final Task task;

  @override
  State<_TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<_TaskEditorSheet> {
  late final TextEditingController _title = TextEditingController(
    text: widget.task.title,
  );
  late final TextEditingController _notes = TextEditingController(
    text: widget.task.notes,
  );

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = titleError(_title.text);
    // Inset by the keyboard so the fields stay visible.
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _title,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Title',
                errorText: _title.text.isEmpty ? null : error,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              decoration: const InputDecoration(labelText: 'Notes'),
              minLines: 1,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: error == null ? _save : null,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final notes = _notes.text.trim();
    Navigator.of(context).pop(
      TaskDraft(
        title: _title.text.trim(),
        notes: notes.isEmpty ? null : notes,
      ),
    );
  }
}
