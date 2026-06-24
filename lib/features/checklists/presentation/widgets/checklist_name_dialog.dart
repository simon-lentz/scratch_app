import 'package:checkplan/core/validation.dart';
import 'package:flutter/material.dart';

/// Shows a dialog to create or rename a checklist.
///
/// Returns the validated, trimmed title, or null if the user cancels. Pass
/// [initialTitle] to pre-fill the field (rename); omit it to create.
Future<String?> showChecklistNameDialog(
  BuildContext context, {
  String? initialTitle,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _ChecklistNameDialog(initialTitle: initialTitle),
  );
}

class _ChecklistNameDialog extends StatefulWidget {
  const _ChecklistNameDialog({this.initialTitle});

  final String? initialTitle;

  @override
  State<_ChecklistNameDialog> createState() => _ChecklistNameDialogState();
}

class _ChecklistNameDialogState extends State<_ChecklistNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialTitle,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRename = widget.initialTitle != null;
    final error = titleError(_controller.text);
    return AlertDialog(
      title: Text(isRename ? 'Rename checklist' : 'New checklist'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Title',
          errorText: _controller.text.isEmpty ? null : error,
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(error),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: error == null ? () => _submit(error) : null,
          child: Text(isRename ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  void _submit(String? error) {
    if (error != null) return;
    Navigator.of(context).pop(_controller.text.trim());
  }
}
