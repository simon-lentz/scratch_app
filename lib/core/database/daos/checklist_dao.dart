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

  /// Non-archived checklists ordered by `position` (id as a stable tiebreaker),
  /// each with its task `(done, total)` counts.
  ///
  /// Re-emits whenever checklists or tasks change.
  Stream<List<ChecklistSummary>> watchActiveSummaries() {
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
      ..where(checklists.archivedAt.isNull())
      ..groupBy([checklists.id])
      ..orderBy([
        OrderingTerm(expression: checklists.position),
        OrderingTerm(expression: checklists.id),
      ]);

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

  /// Creates a checklist with the given title at the next free position.
  ///
  /// Allocating the position and inserting run in one transaction, so the
  /// `MAX(position)+1` read and the insert are atomic.
  Future<int> create(String title) {
    return transaction(() async {
      final now = DateTime.timestamp();
      return into(checklists).insert(
        ChecklistsCompanion.insert(
          title: title,
          position: await nextPosition(checklists, checklists.position.max()),
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
  /// the active order so its stale `position` cannot collide with one taken by
  /// an intervening reorder.
  ///
  /// Reading the next position and writing run in one transaction, matching the
  /// atomicity of [create].
  Future<int> restore(int id) {
    return transaction(() async {
      return (update(checklists)..where((c) => c.id.equals(id))).write(
        ChecklistsCompanion(
          archivedAt: const Value(null),
          position: Value(
            await nextPosition(checklists, checklists.position.max()),
          ),
          updatedAt: Value(DateTime.timestamp()),
        ),
      );
    });
  }

  /// Hard-deletes the checklist, cascading to its tasks.
  Future<int> deleteById(int id) =>
      (delete(checklists)..where((c) => c.id.equals(id))).go();

  /// Rewrites positions so they match the given id order, atomically.
  ///
  /// [orderedIds] must be the full set of non-archived checklist ids.
  Future<void> reorder(List<int> orderedIds) => reorderByPosition(
    checklists,
    orderedIds: orderedIds,
    idColumn: checklists.id,
    rowFor: (index, now) =>
        ChecklistsCompanion(position: Value(index), updatedAt: Value(now)),
    scope: checklists.archivedAt.isNull(),
  );
}
