import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:checkplan/core/validation.dart';
import 'package:flutter/material.dart';

/// The edited fields returned by [showTaskEditorSheet].
class TaskDraft {
  /// Wraps the validated, trimmed [title], optional [notes], and [dueDay].
  const TaskDraft({required this.title, this.notes, this.dueDay});

  /// The new title (already trimmed and validated).
  final String title;

  /// The new notes, or null to clear them.
  final String? notes;

  /// The new due date, or null for no due date.
  final EpochDay? dueDay;
}

/// Shows the task editor as a modal bottom sheet, pre-filled from [task].
///
/// [today] seeds the date picker when the task has no due date yet. Returns the
/// edited [TaskDraft] on save, or null if dismissed. Save is disabled while the
/// title is empty or over-length (see: [titleError]).
Future<TaskDraft?> showTaskEditorSheet(
  BuildContext context, {
  required Task task,
  required EpochDay today,
}) {
  return showModalBottomSheet<TaskDraft>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _TaskEditorSheet(task: task, today: today),
  );
}

class _TaskEditorSheet extends StatefulWidget {
  const _TaskEditorSheet({required this.task, required this.today});

  final Task task;
  final EpochDay today;

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
  EpochDay? _dueDay;

  @override
  void initState() {
    super.initState();
    final due = widget.task.dueDay;
    _dueDay = due == null ? null : EpochDay(due);
  }

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
            const SizedBox(height: 12),
            _dueDateRow(),
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

  Widget _dueDateRow() {
    final due = _dueDay;
    final String label;
    if (due == null) {
      label = 'No due date';
    } else {
      final d = due.toLocalDateTime();
      label = '${d.month}/${d.day}/${d.year}';
    }
    return Row(
      children: [
        Expanded(child: Text(label)),
        if (due != null)
          IconButton(
            icon: const Icon(Icons.clear),
            tooltip: 'Clear due date',
            onPressed: () => setState(() => _dueDay = null),
          ),
        TextButton(
          onPressed: _pickDueDate,
          child: Text(due == null ? 'Add due date' : 'Change'),
        ),
      ],
    );
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (_dueDay ?? widget.today).toLocalDateTime(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _dueDay = EpochDay.fromDateTime(picked));
  }

  void _save() {
    final notes = _notes.text.trim();
    Navigator.of(context).pop(
      TaskDraft(
        title: _title.text.trim(),
        notes: notes.isEmpty ? null : notes,
        dueDay: _dueDay,
      ),
    );
  }
}
