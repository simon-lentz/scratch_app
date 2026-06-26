import 'package:checkplan/core/result.dart';
import 'package:checkplan/core/widgets/error_snackbar.dart';
import 'package:checkplan/features/tasks/application/task_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Toggles task [id]'s done state, surfacing a failure as an error `SnackBar`.
///
/// Shared by the checklist-detail and Today task rows: both flip a task's done
/// flag through [taskControllerProvider] and report the same failure the same
/// way. Guards `context.mounted` after the await before touching [context].
Future<void> toggleTaskDone(
  BuildContext context,
  WidgetRef ref,
  int id, {
  required bool isDone,
}) async {
  final result = await ref
      .read(taskControllerProvider.notifier)
      .setDone(id, isDone: isDone);
  if (!context.mounted) return;
  if (result case Err()) {
    showErrorSnackBar(context, 'Could not update the task');
  }
}
