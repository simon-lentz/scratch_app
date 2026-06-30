import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/dao_support.dart';
import 'package:checkplan/core/database/tables/subtasks.dart';
import 'package:checkplan/core/database/tables/tasks.dart';
import 'package:drift/drift.dart';

part 'subtask_dao.g.dart';

/// Reads and writes subtasks, exposing a reactive per-task list.
@DriftAccessor(tables: [Subtasks, Tasks])
class SubtaskDao extends DatabaseAccessor<AppDatabase>
    with _$SubtaskDaoMixin, PositioningDao {
  /// Binds the DAO to its attached database.
  SubtaskDao(super.attachedDatabase);

  /// A task's subtasks ordered by `rank` (id as a stable tiebreaker);
  /// re-emits on any change.
  Stream<List<Subtask>> watchForTask(int taskId) {
    return (select(subtasks)
          ..where((s) => s.taskId.equals(taskId))
          ..orderBy([
            (s) => OrderingTerm(expression: s.rank),
            (s) => OrderingTerm(expression: s.id),
          ]))
        .watch();
  }

  /// Adds a subtask to the task at the tail of its order, then reconciles the
  /// parent task's completion — a new open subtask reopens an auto-completed
  /// parent (see [_reconcileParentDone]). Rank allocation, insert, and
  /// reconcile run in one transaction, so they are atomic.
  Future<int> add(int taskId, String title) {
    return transaction(() async {
      final now = DateTime.timestamp();
      final id = await into(subtasks).insert(
        SubtasksCompanion.insert(
          taskId: taskId,
          title: title,
          rank: await nextRank(
            subtasks,
            subtasks.rank,
            where: subtasks.taskId.equals(taskId),
          ),
          createdAt: now,
          updatedAt: now,
        ),
      );
      await _reconcileParentDone(taskId, now);
      return id;
    });
  }

  /// Sets subtask [id]'s completion flag, then reconciles its parent task's
  /// completion with the all-subtasks-done rule (see [_reconcileParentDone]),
  /// both in one transaction. The parent id is derived from the row, so callers
  /// pass only the subtask id.
  Future<void> setDone(int id, {required bool isDone}) => transaction(() async {
    final now = DateTime.timestamp();
    final updated = await (update(subtasks)..where((s) => s.id.equals(id)))
        .write(SubtasksCompanion(isDone: Value(isDone), updatedAt: Value(now)));
    // An absent id (e.g. a row already deleted) writes 0 rows: nothing to
    // reconcile.
    if (updated == 0) return;
    final row = await (select(
      subtasks,
    )..where((s) => s.id.equals(id))).getSingle();
    await _reconcileParentDone(row.taskId, now);
  });

  /// Renames the subtask with the given id.
  Future<int> rename(int id, String title) =>
      (update(subtasks)..where((s) => s.id.equals(id))).write(
        SubtasksCompanion(
          title: Value(title),
          updatedAt: Value(DateTime.timestamp()),
        ),
      );

  /// Hard-deletes the subtask, then reconciles its parent task's completion —
  /// removing the last open subtask can complete the parent (see
  /// [_reconcileParentDone]) — both in one transaction.
  Future<int> deleteById(int id) => transaction(() async {
    final row = await (select(
      subtasks,
    )..where((s) => s.id.equals(id))).getSingleOrNull();
    final deleted = await (delete(
      subtasks,
    )..where((s) => s.id.equals(id))).go();
    if (row != null) {
      await _reconcileParentDone(row.taskId, DateTime.timestamp());
    }
    return deleted;
  });

  /// Re-ranks the moved subtask between its new neighbours (null = list end).
  Future<void> reorder(int movedId, int? beforeId, int? afterId) =>
      reorderByRank(
        subtasks,
        movedId: movedId,
        beforeId: beforeId,
        afterId: afterId,
        idColumn: subtasks.id,
        rankColumn: subtasks.rank,
        rowFor: (rank, now) =>
            SubtasksCompanion(rank: Value(rank), updatedAt: Value(now)),
      );

  /// Reconciles [taskId]'s completion flag with its subtasks: with subtasks
  /// present, the task is done iff none are open; with no subtasks, completion
  /// is left to the manual task checkbox. Writes only on a real transition, so
  /// an already-consistent parent gets no redundant write — and so no spurious
  /// stream re-emit or `updatedAt` bump. Call inside the mutating transaction.
  Future<void> _reconcileParentDone(int taskId, DateTime now) async {
    final open = subtasks.id.count(filter: subtasks.isDone.equals(false));
    final total = subtasks.id.count();
    final counts =
        await (selectOnly(subtasks)
              ..addColumns([open, total])
              ..where(subtasks.taskId.equals(taskId)))
            .getSingle();
    // No subtasks: completion is manual, so leave the parent untouched.
    if ((counts.read(total) ?? 0) == 0) return;
    final shouldBeDone = (counts.read(open) ?? 0) == 0;
    // The isDone guard makes this a no-op when the parent already matches.
    final stmt = update(tasks)
      ..where((t) => t.id.equals(taskId) & t.isDone.equals(!shouldBeDone));
    await stmt.write(
      TasksCompanion(isDone: Value(shouldBeDone), updatedAt: Value(now)),
    );
  }
}
