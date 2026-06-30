import 'package:checkplan/core/database/daos/task_dao.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/result.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:checkplan/core/validation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'task_providers.g.dart';

/// Accessor for the [TaskDao], backed by the shared database.
@Riverpod(keepAlive: true)
TaskDao taskDao(Ref ref) => ref.watch(appDatabaseProvider).taskDao;

/// Reactive list of a checklist's tasks, each with its subtask progress.
///
/// Keyed by checklist id and `autoDispose` so a closed detail screen's stream
/// is torn down. Re-emits whenever the checklist's tasks or their subtasks
/// change.
@riverpod
Stream<List<TaskView>> tasksForChecklist(Ref ref, int checklistId) =>
    ref.watch(taskDaoProvider).watchForChecklist(checklistId);

/// Write commands for tasks.
///
/// Holds no state of its own — the database is the state. Each command returns
/// a [Result]: rejected input and caught exceptions become [Err]; programming
/// bugs (`Error`) propagate.
@Riverpod(keepAlive: true)
class TaskController extends _$TaskController {
  @override
  void build() {}

  TaskDao get _dao => ref.read(taskDaoProvider);

  /// Adds a task to checklist [checklistId] from the (trimmed) [title].
  /// The [Ok] value is the new task's id.
  /// Rejects an empty or over-length [title].
  Future<Result<int>> add(int checklistId, String title) =>
      guardTitle(title, (title) => _dao.add(checklistId, title));

  /// Sets task [id]'s title, notes, and due date from the editor draft (a full
  /// write). Rejects an empty or over-length [title]; a null [notes]/[dueDay]
  /// clears that field.
  Future<Result<void>> edit(
    int id, {
    required String title,
    required EpochDay? dueDay,
    String? notes,
  }) => guardTitle(title, (title) async {
    await _dao.edit(id, title: title, notes: notes, dueDay: dueDay);
  });

  /// Sets task [id]'s own completion flag.
  Future<Result<void>> setDone(int id, {required bool isDone}) =>
      Result.guard(() async {
        await _dao.setDone(id, isDone: isDone);
      });

  /// Permanently deletes task [id], cascading to its subtasks.
  Future<Result<void>> delete(int id) => Result.guard(() async {
    await _dao.deleteById(id);
  });

  /// Re-ranks the moved task between its new neighbours (null = list end).
  Future<Result<void>> reorder(int movedId, int? beforeId, int? afterId) =>
      Result.guard(() async {
        await _dao.reorder(movedId, beforeId, afterId);
      });
}
