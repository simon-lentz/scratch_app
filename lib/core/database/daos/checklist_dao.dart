import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/dao_support.dart';
import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/database/tables/checklists.dart';
import 'package:checkplan/core/database/tables/tasks.dart';
import 'package:drift/drift.dart';

part 'checklist_dao.g.dart';

/// Reads and writes checklists, exposing reactive task-progress summaries.
@DriftAccessor(tables: [Checklists, Tasks])
class ChecklistDao extends DatabaseAccessor<AppDatabase>
    with _$ChecklistDaoMixin, PositioningDao {
  /// Binds the DAO to its attached database.
  ChecklistDao(super.attachedDatabase);

  /// Non-archived checklists ordered by `rank` (id as a stable tiebreaker),
  /// each with its task `(done, total)` counts.
  ///
  /// Re-emits whenever checklists or tasks change.
  Stream<List<ChecklistSummary>> watchActiveSummaries() => _watchSummaries(
    where: checklists.archivedAt.isNull(),
    orderBy: [
      OrderingTerm(expression: checklists.rank),
      OrderingTerm(expression: checklists.id),
    ],
  );

  /// Archived checklists, most-recently-archived first (id as a stable
  /// tiebreaker), each with its task `(done, total)` counts.
  ///
  /// The mirror of [watchActiveSummaries] for the archive view: same shape, but
  /// it selects the archived rows (`archivedAt` set) and orders by when they
  /// were archived rather than by `rank`.
  Stream<List<ChecklistSummary>> watchArchivedSummaries() => _watchSummaries(
    where: checklists.archivedAt.isNotNull(),
    orderBy: [
      OrderingTerm(expression: checklists.archivedAt, mode: OrderingMode.desc),
      OrderingTerm(expression: checklists.id, mode: OrderingMode.desc),
    ],
  );

  /// The shared task-progress summary query: each checklist matching [where],
  /// ordered by [orderBy], with its task `(done, total)` counts. Backs both
  /// [watchActiveSummaries] and [watchArchivedSummaries], which differ only in
  /// which rows they select and how they order them.
  Stream<List<ChecklistSummary>> _watchSummaries({
    required Expression<bool> where,
    required List<OrderingTerm> orderBy,
  }) {
    final query = select(checklists).join([
      // useColumns: false — read the counts, not the joined rows.
      leftOuterJoin(
        tasks,
        tasks.checklistId.equalsExp(checklists.id),
        useColumns: false,
      ),
    ]);
    final readProgress = addProgressCounts(query, tasks.id, tasks.isDone);
    query
      ..where(where)
      ..groupBy([checklists.id])
      ..orderBy(orderBy);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => ChecklistSummary(
              checklist: row.readTable(checklists),
              progress: readProgress(row),
            ),
          )
          .toList(),
    );
  }

  /// The checklist row with [id], or `null` if none — whether or not it is
  /// archived. A bare single-row read: it re-emits only when the checklist row
  /// itself changes (rename, recolor, archive), not on every task change like
  /// the summary queries. Resolving by id directly (rather than deriving from
  /// [watchActiveSummaries]) covers an archived checklist or a cold deep-link
  /// without waiting on the active list to load. The detail app bar needs only
  /// the title and color, so the task-progress counts are deliberately omitted.
  Stream<Checklist?> watchRowById(int id) =>
      (select(checklists)..where((c) => c.id.equals(id))).watchSingleOrNull();

  /// Creates a checklist with the given title at the tail of the order.
  ///
  /// Allocating the rank and inserting run in one transaction, so the max-rank
  /// read and the insert are atomic.
  Future<int> create(String title) {
    return transaction(() async {
      final now = DateTime.timestamp();
      return into(checklists).insert(
        ChecklistsCompanion.insert(
          title: title,
          rank: await nextRank(checklists, checklists.rank),
          createdAt: now,
          updatedAt: now,
        ),
      );
    });
  }

  /// Renames the checklist with the given id.
  Future<int> rename(int id, String title) =>
      (update(checklists)..where((c) => c.id.equals(id))).write(
        ChecklistsCompanion(
          title: Value(title),
          updatedAt: Value(DateTime.timestamp()),
        ),
      );

  /// Sets or clears the checklist's theme color — an ARGB int, or null to
  /// restore the default.
  Future<int> setColor(int id, int? colorValue) =>
      (update(checklists)..where((c) => c.id.equals(id))).write(
        ChecklistsCompanion(
          colorValue: Value(colorValue),
          updatedAt: Value(DateTime.timestamp()),
        ),
      );

  /// Archives the checklist, hiding it from the active list.
  Future<int> archive(int id) {
    final now = DateTime.timestamp();
    return (update(checklists)..where((c) => c.id.equals(id))).write(
      ChecklistsCompanion(
        archivedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  /// Restores a previously archived checklist, re-appending it to the tail of
  /// the active order so its stale `rank` cannot sort it ahead of a checklist
  /// added or moved while it was archived.
  ///
  /// Reading the next rank and writing run in one transaction, matching the
  /// atomicity of [create].
  Future<int> restore(int id) {
    return transaction(() async {
      return (update(checklists)..where((c) => c.id.equals(id))).write(
        ChecklistsCompanion(
          archivedAt: const Value(null),
          rank: Value(await nextRank(checklists, checklists.rank)),
          updatedAt: Value(DateTime.timestamp()),
        ),
      );
    });
  }

  /// Hard-deletes the checklist, cascading to its tasks.
  Future<int> deleteById(int id) =>
      (delete(checklists)..where((c) => c.id.equals(id))).go();

  /// Re-ranks the moved checklist between its new neighbours (null = list end).
  Future<void> reorder(int movedId, int? beforeId, int? afterId) =>
      reorderByRank(
        checklists,
        movedId: movedId,
        beforeId: beforeId,
        afterId: afterId,
        idColumn: checklists.id,
        rankColumn: checklists.rank,
        rowFor: (rank, now) =>
            ChecklistsCompanion(rank: Value(rank), updatedAt: Value(now)),
      );
}
