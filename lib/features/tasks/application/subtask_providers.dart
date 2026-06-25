import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/daos/subtask_dao.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/core/result.dart';
import 'package:checkplan/core/validation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

/// Accessor for the [SubtaskDao], backed by the shared database.
final subtaskDaoProvider = Provider<SubtaskDao>(
  (ref) => ref.watch(appDatabaseProvider).subtaskDao,
);

/// Reactive list of a task's subtasks, keyed by task id and `autoDispose`.
final StreamProviderFamily<List<Subtask>, int> subtasksForTaskProvider =
    StreamProvider.autoDispose.family<List<Subtask>, int>(
      (ref, taskId) => ref.watch(subtaskDaoProvider).watchForTask(taskId),
    );

/// Write commands for subtasks (add / toggle / delete).
///
/// Holds no state of its own, the database is the state. Each command returns
/// a [Result].
class SubtaskController extends Notifier<void> {
  @override
  void build() {}

  SubtaskDao get _dao => ref.read(subtaskDaoProvider);

  /// Adds a subtask to task [taskId] from the (trimmed) [title]; the [Ok] value
  /// is the new subtask's id. Rejects an empty or over-length [title].
  Future<Result<int>> add(int taskId, String title) {
    final error = titleError(title);
    if (error != null) return Future.value(Err(ValidationException(error)));
    return Result.guard(() => _dao.add(taskId, title.trim()));
  }

  /// Sets subtask [id]'s completion flag.
  Future<Result<void>> setDone(int id, {required bool isDone}) =>
      Result.guard(() async {
        await _dao.setDone(id, isDone: isDone);
      });

  /// Permanently deletes subtask [id].
  Future<Result<void>> delete(int id) => Result.guard(() async {
    await _dao.deleteById(id);
  });
}

/// Exposes [SubtaskController] for subtask write commands.
final subtaskControllerProvider = NotifierProvider<SubtaskController, void>(
  SubtaskController.new,
);
