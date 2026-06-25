import 'package:checkplan/core/database/daos/task_dao.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/result.dart';
import 'package:checkplan/core/validation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

/// Accessor for the [TaskDao], backed by the shared database.
final taskDaoProvider = Provider<TaskDao>(
  (ref) => ref.watch(appDatabaseProvider).taskDao,
);

/// Reactive list of a checklist's tasks, each with its subtask progress.
///
/// Keyed by checklist id and `autoDispose` so a closed detail screen's stream
/// is torn down. Re-emits whenever the checklist's tasks or their subtasks
/// change.
final StreamProviderFamily<List<TaskView>, int> tasksForChecklistProvider =
    StreamProvider.autoDispose.family<List<TaskView>, int>(
      (ref, checklistId) =>
          ref.watch(taskDaoProvider).watchForChecklist(checklistId),
    );

/// Write commands for tasks.
///
/// Holds no state of its own — the database is the state. Each command returns
/// a [Result]: rejected input and caught exceptions become [Err]; programming
/// bugs (`Error`) propagate.
class TaskController extends Notifier<void> {
  @override
  void build() {}

  TaskDao get _dao => ref.read(taskDaoProvider);

  /// Adds a task to checklist [checklistId] from the (trimmed) [title].
  /// The [Ok] value is the new task's id.
  /// Rejects an empty or over-length [title].
  Future<Result<int>> add(int checklistId, String title) {
    final error = titleError(title);
    if (error != null) return Future.value(Err(ValidationException(error)));
    return Result.guard(() => _dao.add(checklistId, title.trim()));
  }

  /// Sets task [id]'s title and notes from the editor draft (a full write).
  /// Rejects an empty or over-length [title]; `notes: null` clears the notes.
  Future<Result<void>> edit(int id, {required String title, String? notes}) {
    final error = titleError(title);
    if (error != null) return Future.value(Err(ValidationException(error)));
    return Result.guard(() async {
      await _dao.edit(id, title: title.trim(), notes: notes);
    });
  }

  /// Sets task [id]'s own completion flag.
  Future<Result<void>> setDone(int id, {required bool isDone}) =>
      Result.guard(() async {
        await _dao.setDone(id, isDone: isDone);
      });

  /// Permanently deletes task [id], cascading to its subtasks.
  Future<Result<void>> delete(int id) => Result.guard(() async {
    await _dao.deleteById(id);
  });

  /// Rewrites task positions within [checklistId] to match [orderedIds].
  Future<Result<void>> reorder(int checklistId, List<int> orderedIds) =>
      Result.guard(() async {
        await _dao.reorder(checklistId, orderedIds);
      });
}

/// Exposes [TaskController] for task write commands.
final taskControllerProvider = NotifierProvider<TaskController, void>(
  TaskController.new,
);
