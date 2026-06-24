import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/summaries.dart';
import 'package:drift/drift.dart';

/// Thrown by [PositioningDao.reorderByPosition] when the requested id set does
/// not match the scope's current ids — a partial, duplicated, or stale set.
///
/// An [Exception], not an [Error]: the realistic cause is a benign race, where
/// a caller dispatches the complete rendered order but a concurrent write
/// changed the scope first. `Result.guard` maps it to an `Err` so the command
/// degrades gracefully; a genuine logic bug in a reorder still surfaces as an
/// uncaught [Error].
class ReorderConflict implements Exception {
  /// Creates a reorder conflict carrying a human-readable [message].
  const ReorderConflict(this.message);

  /// The human-readable reason the requested order was rejected.
  final String message;
}

/// Shared helpers for DAOs whose rows are ordered by a dense integer `position`
/// within a scope (checklists among the active set; tasks within a checklist;
/// subtasks within a task).
mixin PositioningDao on DatabaseAccessor<AppDatabase> {
  /// The next free `position` for [table] — one past the current maximum, or 0
  /// when the scope is empty.
  ///
  /// Pass [maxPosition] as the table's `position.max()` aggregate, and an
  /// optional [where] to scope the maximum to a parent (e.g. one checklist).
  Future<int> nextPosition<T extends HasResultSet, R>(
    ResultSetImplementation<T, R> table,
    Expression<int> maxPosition, {
    Expression<bool>? where,
  }) async {
    final query = selectOnly(table)..addColumns([maxPosition]);
    if (where != null) query.where(where);
    final row = await query.getSingleOrNull();
    return (row?.read(maxPosition) ?? -1) + 1;
  }

  /// Rewrites `position` for [table] so the rows named by [orderedIds] take
  /// dense positions `0..n-1` in that order, in one atomic [batch].
  ///
  /// [orderedIds] must be the complete, duplicate-free id set for the scope: an
  /// omitted id would keep its stale `position` and collide with a freshly
  /// assigned one. The contract is enforced before the rewrite (it reads the
  /// scope's current ids and throws a [ReorderConflict] on a partial,
  /// duplicated, or stale list), so a malformed reorder is rejected instead of
  /// silently scrambling order. Throwing before the [batch] keeps the rewrite
  /// atomic: nothing is written on a violation.
  ///
  /// [idColumn] is the table's primary-key column; [rowFor] builds the per-row
  /// companion (`position`/`updatedAt`); [scope] narrows the update and the
  /// contract check to the orderable subset (e.g. one checklist, or only the
  /// non-archived checklists).
  Future<void> reorderByPosition<T extends Table, D>(
    TableInfo<T, D> table, {
    required List<int> orderedIds,
    required GeneratedColumn<int> idColumn,
    required Insertable<D> Function(int index, DateTime now) rowFor,
    Expression<bool>? scope,
  }) async {
    final idQuery = selectOnly(table)..addColumns([idColumn]);
    if (scope != null) idQuery.where(scope);
    final currentIds = (await idQuery.get())
        .map((row) => row.read(idColumn)!)
        .toSet();
    final requestedIds = orderedIds.toSet();
    if (requestedIds.length != orderedIds.length ||
        requestedIds.length != currentIds.length ||
        !requestedIds.containsAll(currentIds)) {
      throw ReorderConflict(
        'reorder expects the complete, duplicate-free id set for the scope; '
        'got $orderedIds for current ids $currentIds',
      );
    }

    final now = DateTime.timestamp();
    await batch((b) {
      for (final (index, id) in orderedIds.indexed) {
        final matchesRow = idColumn.equals(id);
        b.update(
          table,
          rowFor(index, now),
          where: (_) => scope == null ? matchesRow : scope & matchesRow,
        );
      }
    });
  }
}

/// Adds child `(done, total)` count columns to [query] and returns a reader
/// that maps a result row to its [Progress].
///
/// `(0, 0)` ⇒ the parent has no children. Centralises the
/// progress rollup shared by the checklist- and task-summary queries: pass the
/// child table's id and `isDone` columns, then call the returned reader on each
/// joined result row.
Progress Function(TypedResult row) addProgressCounts(
  JoinedSelectStatement<dynamic, dynamic> query,
  GeneratedColumn<int> childId,
  GeneratedColumn<bool> childIsDone,
) {
  final total = childId.count();
  final done = childId.count(filter: childIsDone.equals(true));
  query.addColumns([total, done]);
  return (row) => (row.read(done) ?? 0, row.read(total) ?? 0);
}
