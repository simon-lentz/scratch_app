import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/dao_support.dart';
import 'package:checkplan/core/database/tables/subtasks.dart';
import 'package:drift/drift.dart';

part 'subtask_dao.g.dart';

/// Reads and writes subtasks, exposing a reactive per-task list.
@DriftAccessor(tables: [Subtasks])
class SubtaskDao extends DatabaseAccessor<AppDatabase>
    with _$SubtaskDaoMixin, PositioningDao {
  /// Binds the DAO to its attached database.
  SubtaskDao(super.attachedDatabase);

  /// A task's subtasks ordered by `position` (id as a stable tiebreaker);
  /// re-emits on any change.
  Stream<List<Subtask>> watchForTask(int taskId) {
    return (select(subtasks)
          ..where((s) => s.taskId.equals(taskId))
          ..orderBy([
            (s) => OrderingTerm(expression: s.position),
            (s) => OrderingTerm(expression: s.id),
          ]))
        .watch();
  }

  /// Adds a subtask to the task at the next free position.
  ///
  /// Allocating the position and inserting run in one transaction, so they are
  /// atomic.
  Future<int> add(int taskId, String title) {
    return transaction(() async {
      final now = DateTime.timestamp();
      return into(subtasks).insert(
        SubtasksCompanion.insert(
          taskId: taskId,
          title: title,
          position: await nextPosition(
            subtasks,
            subtasks.position.max(),
            where: subtasks.taskId.equals(taskId),
          ),
          createdAt: now,
          updatedAt: now,
        ),
      );
    });
  }

  /// Sets the subtask's completion flag.
  Future<int> setDone(int id, {required bool isDone}) =>
      (update(subtasks)..where((s) => s.id.equals(id))).write(
        SubtasksCompanion(
          isDone: Value(isDone),
          updatedAt: Value(DateTime.timestamp()),
        ),
      );

  /// Renames the subtask with the given id.
  Future<int> rename(int id, String title) =>
      (update(subtasks)..where((s) => s.id.equals(id))).write(
        SubtasksCompanion(
          title: Value(title),
          updatedAt: Value(DateTime.timestamp()),
        ),
      );

  /// Hard-deletes the subtask.
  Future<int> deleteById(int id) =>
      (delete(subtasks)..where((s) => s.id.equals(id))).go();

  /// Rewrites positions within a task to match the given id order.
  ///
  /// [orderedIds] must be the full set of subtask ids in [taskId].
  Future<void> reorder(int taskId, List<int> orderedIds) => reorderByPosition(
    subtasks,
    orderedIds: orderedIds,
    idColumn: subtasks.id,
    rowFor: (index, now) =>
        SubtasksCompanion(position: Value(index), updatedAt: Value(now)),
    scope: subtasks.taskId.equals(taskId),
  );
}
