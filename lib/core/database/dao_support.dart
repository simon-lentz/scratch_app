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
  /// either is null at a list end.
  ///
  /// The common case is a single-row write: the neighbours keep their ranks and
  /// [movedId] takes a fresh key strictly between them, so a reorder is one
  /// `UPDATE`, not a block rewrite. When the target gap is degenerate — the
  /// neighbours share a rank or sit out of order, which a single device never
  /// produces but a sync merge of two devices can — there is no key strictly
  /// between them, so [scopeOf]'s rows are rebalanced instead: rewritten with
  /// fresh, strictly increasing keys in the intended order, which also clears
  /// the duplicate ranks that caused it. The read-decide-write runs in one
  /// transaction so a concurrent ordering write cannot interleave on a stale
  /// neighbour rank.
  ///
  /// [idColumn]/[rankColumn] are the table's primary-key and rank columns;
  /// [rowFor] builds the per-row companion (`rank`/`updatedAt`); [scopeOf] maps
  /// the moved row to the predicate selecting its ordering scope (its siblings)
  /// — e.g. the active checklists, or the tasks of one checklist.
  Future<void> reorderByRank<T extends Table, D>(
    TableInfo<T, D> table, {
    required int movedId,
    required int? beforeId,
    required int? afterId,
    required GeneratedColumn<int> idColumn,
    required GeneratedColumn<String> rankColumn,
    required Insertable<D> Function(String rank, DateTime now) rowFor,
    required Expression<bool> Function(D moved) scopeOf,
  }) {
    return transaction(() async {
      final (:before, :after) = await _neighbourRanks(
        table,
        idColumn: idColumn,
        rankColumn: rankColumn,
        beforeId: beforeId,
        afterId: afterId,
      );
      // A null neighbour is a list end, which rankBetween handles; only two
      // present ranks that tie or invert have no key between them.
      if (before != null && after != null && before.compareTo(after) >= 0) {
        await _rebalanceScope(
          table,
          movedId: movedId,
          beforeId: beforeId,
          afterId: afterId,
          idColumn: idColumn,
          rankColumn: rankColumn,
          rowFor: rowFor,
          scopeOf: scopeOf,
        );
        return;
      }
      await (update(table)..where((_) => idColumn.equals(movedId))).write(
        rowFor(rankBetween(before, after), DateTime.timestamp()),
      );
    });
  }

  /// Reads the ranks of [beforeId] and [afterId] in a single query. A null id
  /// (a list end) reads back as a null rank, as does a neighbour deleted out
  /// from under the reorder.
  Future<({String? before, String? after})> _neighbourRanks<T extends Table, D>(
    TableInfo<T, D> table, {
    required GeneratedColumn<int> idColumn,
    required GeneratedColumn<String> rankColumn,
    required int? beforeId,
    required int? afterId,
  }) async {
    final ids = [?beforeId, ?afterId];
    if (ids.isEmpty) return (before: null, after: null);
    final rows =
        await (selectOnly(table)
              ..addColumns([idColumn, rankColumn])
              ..where(idColumn.isIn(ids)))
            .get();
    final rankById = {
      for (final row in rows) row.read(idColumn)!: row.read(rankColumn),
    };
    return (before: rankById[beforeId], after: rankById[afterId]);
  }

  /// Rewrites every row in the moved row's scope with fresh, strictly
  /// increasing ranks in the intended order: the scope is read in its current
  /// `(rank, id)` order, [movedId] is pulled out and reinserted between its
  /// requested neighbours (falling back toward a list end if a neighbour was
  /// concurrently removed), then the whole scope is re-keyed with
  /// [ranksBetween]. Used when no key fits between the target's neighbours.
  Future<void> _rebalanceScope<T extends Table, D>(
    TableInfo<T, D> table, {
    required int movedId,
    required int? beforeId,
    required int? afterId,
    required GeneratedColumn<int> idColumn,
    required GeneratedColumn<String> rankColumn,
    required Insertable<D> Function(String rank, DateTime now) rowFor,
    required Expression<bool> Function(D moved) scopeOf,
  }) async {
    final moved = await (select(
      table,
    )..where((_) => idColumn.equals(movedId))).getSingleOrNull();
    // The moved row vanished (a concurrent delete): nothing to reorder.
    if (moved == null) return;

    final ordered =
        await (selectOnly(table)
              ..addColumns([idColumn])
              ..where(scopeOf(moved))
              ..orderBy([
                OrderingTerm(expression: rankColumn),
                OrderingTerm(expression: idColumn),
              ]))
            .get();
    final ids = [for (final row in ordered) row.read(idColumn)!]
      ..remove(movedId);

    final beforeIndex = beforeId == null ? -1 : ids.indexOf(beforeId);
    final int insertAt;
    if (beforeIndex >= 0) {
      insertAt = beforeIndex + 1;
    } else {
      final afterIndex = afterId == null ? -1 : ids.indexOf(afterId);
      insertAt = afterIndex >= 0 ? afterIndex : ids.length;
    }
    ids.insert(insertAt, movedId);

    final ranks = ranksBetween(null, null, ids.length);
    final now = DateTime.timestamp();
    await batch((b) {
      for (final (index, id) in ids.indexed) {
        b.update(
          table,
          rowFor(ranks[index], now),
          where: (_) => idColumn.equals(id),
        );
      }
    });
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
