import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/daos/subtask_dao.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/core/result.dart';
import 'package:checkplan/core/validation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show StreamProvider;
import 'package:flutter_riverpod/misc.dart' show StreamProviderFamily;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'subtask_providers.g.dart';

/// Accessor for the [SubtaskDao], backed by the shared database.
@Riverpod(keepAlive: true)
SubtaskDao subtaskDao(Ref ref) => ref.watch(appDatabaseProvider).subtaskDao;

/// Reactive list of a task's subtasks, keyed by task id and `autoDispose`.
///
/// Hand-written rather than `@riverpod`: this provider's value type names the
/// drift row class [Subtask], which exists only in the generated
/// `app_database.g.dart` part. `riverpod_generator` cannot resolve a type from
/// another file's generated part during its shared-part build phase, so a
/// generated provider here fails with `InvalidTypeException`. The accessor and
/// controller below return hand-written types and are generated normally.
final StreamProviderFamily<List<Subtask>, int> subtasksForTaskProvider =
    StreamProvider.autoDispose.family<List<Subtask>, int>(
      (ref, taskId) => ref.watch(subtaskDaoProvider).watchForTask(taskId),
    );

/// Write commands for subtasks (add / toggle / delete).
///
/// Holds no state of its own, the database is the state. Each command returns
/// a [Result].
@Riverpod(keepAlive: true)
class SubtaskController extends _$SubtaskController {
  @override
  void build() {}

  SubtaskDao get _dao => ref.read(subtaskDaoProvider);

  /// Adds a subtask to task [taskId] from the (trimmed) [title]; the [Ok] value
  /// is the new subtask's id. Rejects an empty or over-length [title].
  Future<Result<int>> add(int taskId, String title) =>
      guardTitle(title, (title) => _dao.add(taskId, title));

  /// Sets subtask [id]'s completion flag; the DAO reconciles its parent task's
  /// completion (the symmetric all-subtasks-done rule).
  Future<Result<void>> setDone(int id, {required bool isDone}) =>
      Result.guard(() async {
        await _dao.setDone(id, isDone: isDone);
      });

  /// Permanently deletes subtask [id].
  Future<Result<void>> delete(int id) => Result.guard(() async {
    await _dao.deleteById(id);
  });

  /// Renames subtask [id] to the (trimmed) [title]. Rejects an empty or
  /// over-length [title].
  Future<Result<void>> rename(int id, String title) =>
      guardTitle(title, (title) async {
        await _dao.rename(id, title);
      });

  /// Re-ranks the moved subtask between its new neighbours (null = list end).
  Future<Result<void>> reorder(int movedId, int? beforeId, int? afterId) =>
      Result.guard(() async {
        await _dao.reorder(movedId, beforeId, afterId);
      });
}
