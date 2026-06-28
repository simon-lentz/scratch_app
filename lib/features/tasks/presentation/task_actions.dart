import 'package:checkplan/core/result.dart';
import 'package:checkplan/core/widgets/error_snackbar.dart';
import 'package:checkplan/features/tasks/application/task_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Toggles task [id]'s done state, surfacing a failure as an error `SnackBar`,
/// and resolving to whether the write succeeded.
///
/// Shared by the checklist-detail and Today task rows: both flip a task's done
/// flag through [taskControllerProvider] and report the same failure the same
/// way. The Today row uses the result to restore itself when a completion it
/// has already animated out turns out to have failed. Guards `context.mounted`
/// before touching [context].
Future<bool> toggleTaskDone(
  BuildContext context,
  WidgetRef ref,
  int id, {
  required bool isDone,
}) async {
  final result = await ref
      .read(taskControllerProvider.notifier)
      .setDone(id, isDone: isDone);
  final ok = switch (result) {
    Ok() => true,
    Err() => false,
  };
  if (context.mounted && !ok) {
    showErrorSnackBar(context, 'Could not update the task');
  }
  return ok;
}
