import 'package:checkplan/core/validation.dart';
import 'package:flutter/material.dart';

/// Shows a single-field name editor titled [title], with [submitLabel] on the
/// confirm button.
///
/// Live-validates with [titleError]: the confirm button is disabled and an
/// inline error shows while the trimmed input is empty or over-length. Returns
/// the validated, trimmed value, or null if the user cancels. Pass
/// [initialValue] to pre-fill (e.g. a rename).
Future<String?> showNameDialog(
  BuildContext context, {
  required String title,
  required String submitLabel,
  String? initialValue,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _NameDialog(
      title: title,
      submitLabel: submitLabel,
      initialValue: initialValue,
    ),
  );
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.submitLabel,
    this.initialValue,
  });

  final String title;
  final String submitLabel;
  final String? initialValue;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = titleError(_controller.text);
    return AlertDialog(
      title: Text(widget.title),
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
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }

  void _submit(String? error) {
    if (error != null) return;
    Navigator.of(context).pop(_controller.text.trim());
  }
}
