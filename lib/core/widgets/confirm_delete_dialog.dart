import 'package:flutter/material.dart';

/// Shows a confirmation dialog for an irreversible delete.
///
/// Returns true only if the user confirms; Cancel or a barrier dismiss
/// returns false. [title] heads the dialog and [message] explains what is
/// removed. The destructive button is labelled [confirmLabel].
Future<bool> showConfirmDeleteDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
