import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/rank.dart';
import 'package:checkplan/core/database/summaries.dart';
import 'package:drift/drift.dart';

/// Shared helpers for DAOs whose rows are ordered by a fractional `rank` string
/// within a scope (checklists globally; tasks within a checklist; subtasks
/// within a task). See core/database/rank.dart for the key algorithm.
mixin PositioningDao on DatabaseAccessor<AppDatabase> {
  /// The append rank for [table]: just after the current maximum rank in the
  /// scope, or the first key when the scope is empty.
  ///
  /// Pass [rankColumn] as the table's `rank` column and an optional [where] to
  /// scope the maximum to a parent (e.g. one checklist).
  Future<String> nextRank<T extends HasResultSet, R>(
    ResultSetImplementation<T, R> table,
    GeneratedColumn<String> rankColumn, {
    Expression<bool>? where,
  }) async {
    final maxRank = rankColumn.max();
    final query = selectOnly(table)..addColumns([maxRank]);
    if (where != null) query.where(where);
    final row = await query.getSingleOrNull();
    return rankBetween(row?.read(maxRank), null);
  }

  /// Re-ranks the row [movedId] to sit strictly between its new neighbours
  /// [beforeId] (the row now above it) and [afterId] (the row now below it);
  /// either is null at a list end. A single-row write — the neighbours keep
  /// their ranks, so a reorder is one `UPDATE`, not a block rewrite. Ids are
  /// primary keys, so no scope is needed to resolve the neighbours.
  ///
  /// [idColumn]/[rankColumn] are the table's primary-key and rank columns;
  /// [rowFor] builds the per-row companion (`rank`/`updatedAt`).
  Future<void> reorderByRank<T extends Table, D>(
    TableInfo<T, D> table, {
    required int movedId,
    required int? beforeId,
    required int? afterId,
    required GeneratedColumn<int> idColumn,
    required GeneratedColumn<String> rankColumn,
    required Insertable<D> Function(String rank, DateTime now) rowFor,
  }) async {
    Future<String?> rankOf(int? id) async {
      if (id == null) return null;
      final query = selectOnly(table)
        ..addColumns([rankColumn])
        ..where(idColumn.equals(id));
      return (await query.getSingleOrNull())?.read(rankColumn);
    }

    final newRank = rankBetween(await rankOf(beforeId), await rankOf(afterId));
    await (update(table)..where((_) => idColumn.equals(movedId))).write(
      rowFor(newRank, DateTime.timestamp()),
    );
  }
}

/// Adds child `(done, total)` count columns to [query] and returns a reader
/// that maps a result row to its [Progress].
///
/// `(0, 0)` -> the parent has no children. Centralises the
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
