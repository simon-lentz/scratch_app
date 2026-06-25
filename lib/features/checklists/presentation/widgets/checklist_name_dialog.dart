import 'package:checkplan/core/widgets/name_dialog.dart';
import 'package:flutter/material.dart';

/// Shows a dialog to create or rename a checklist.
///
/// Returns the validated, trimmed title, or null if the user cancels. Pass
/// [initialTitle] to pre-fill the field (rename); omit it to create.
Future<String?> showChecklistNameDialog(
  BuildContext context, {
  String? initialTitle,
}) {
  final isRename = initialTitle != null;
  return showNameDialog(
    context,
    title: isRename ? 'Rename checklist' : 'New checklist',
    submitLabel: isRename ? 'Save' : 'Add',
    initialValue: initialTitle,
  );
}
