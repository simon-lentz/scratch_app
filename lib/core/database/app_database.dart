import 'package:checkplan/core/database/app_database.steps.dart';
import 'package:checkplan/core/database/converters/epoch_day_converter.dart';
import 'package:checkplan/core/database/daos/checklist_dao.dart';
import 'package:checkplan/core/database/daos/subtask_dao.dart';
import 'package:checkplan/core/database/daos/task_dao.dart';
import 'package:checkplan/core/database/rank.dart';
import 'package:checkplan/core/database/tables/checklists.dart';
import 'package:checkplan/core/database/tables/subtasks.dart';
import 'package:checkplan/core/database/tables/tasks.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:drift/drift.dart';

part 'app_database.g.dart';

/// The single SQLite database for the app: owns the checklist, task, and
/// subtask tables and enables foreign-key cascades on every connection.
@DriftDatabase(
  tables: [Checklists, Tasks, Subtasks],
  daos: [ChecklistDao, TaskDao, SubtaskDao],
)
class AppDatabase extends _$AppDatabase {
  /// Opens the database over the given executor (a native file in the app, an
  /// in-memory executor in tests).
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  /// Schema migrations: see `drift_schemas/README.md`.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // foreign_keys can't toggle inside a transaction, so disable it first,
      // then run the steps and verify inside one transaction (atomic across all
      // three tables). The verify runs in every build, not just debug: a
      // migration that leaves a row referencing a missing parent is data
      // corruption, so a violation throws and rolls the migration back —
      // schemaVersion stays put and the next open retries from a clean v$from,
      // rather than committing the corruption and bumping the version past it.
      // `foreign_key_check` is a read, not a toggle, so it is safe in the
      // transaction.
      await customStatement('PRAGMA foreign_keys = OFF');
      await transaction(() async {
        await m.runMigrationSteps(
          from: from,
          to: to,
          steps: migrationSteps(from1To2: _from1To2),
        );
        final violations = await customSelect('PRAGMA foreign_key_check').get();
        checkNoForeignKeyViolations(
          violations.map((r) => r.data).toList(),
          from,
          to,
        );
      });
      await customStatement('PRAGMA foreign_keys = ON');
    },
    beforeOpen: (details) async {
      // SQLite enforces foreign keys per connection only when asked to;
      // without this, onDelete: cascade is silently ignored.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  // v1 -> v2: replace the dense-integer `position` on each table with a
  // fractional `rank` (TEXT), backfilling each row's rank from its old
  // position order — global for checklists, per checklist_id for tasks, per
  // task_id for subtasks (see core/database/rank.dart).
  Future<void> _from1To2(Migrator m, Schema2 schema) async {
    await _rankifyTable(
      m,
      table: 'checklists',
      scopeColumn: null,
      target: schema.checklists,
      newIndex: schema.checklistActiveOrder,
      oldIndexName: 'checklist_active_order',
    );
    await _rankifyTable(
      m,
      table: 'tasks',
      scopeColumn: 'checklist_id',
      target: schema.tasks,
      newIndex: schema.taskChecklistOrder,
      oldIndexName: 'task_checklist_order',
    );
    await _rankifyTable(
      m,
      table: 'subtasks',
      scopeColumn: 'task_id',
      target: schema.subtasks,
      newIndex: schema.subtaskTaskOrder,
      oldIndexName: 'subtask_task_order',
    );
  }

  // Converts one table's `position` column to a backfilled `rank`. Order is
  // load-bearing: drop the stale (scope, position) index first so
  // [Migrator.alterTable] won't replay its CREATE against the dropped column;
  // add `rank` nullable so existing rows can be filled before it becomes NOT
  // NULL; backfill per scope with the compact ['a0','a1',...] sequence; rebuild
  // to the v2 shape (copies `rank` by name, drops `position`); recreate the
  // order index on (scope, rank). Raw SQL by column name throughout — the typed
  // accessors reflect the v2 schema the table doesn't match until alterTable
  // finalizes it.
  Future<void> _rankifyTable(
    Migrator m, {
    required String table,
    required String? scopeColumn,
    required TableInfo<Table, dynamic> target,
    required Index newIndex,
    required String oldIndexName,
  }) async {
    final db = m.database;
    await db.customStatement('DROP INDEX IF EXISTS $oldIndexName');
    await db.customStatement('ALTER TABLE $table ADD COLUMN rank TEXT');

    final select = scopeColumn == null
        ? 'SELECT id FROM $table ORDER BY position'
        : 'SELECT id, $scopeColumn AS scope FROM $table '
              'ORDER BY $scopeColumn, position';
    final rows = await db.customSelect(select).get();

    // Compute each row's backfilled rank scope by scope, then write them all in
    // one batched pass instead of a statement round-trip per row.
    final backfill = <(int, String)>[];
    var i = 0;
    while (i < rows.length) {
      final scope = scopeColumn == null ? null : rows[i].read<int>('scope');
      var j = i;
      while (j < rows.length &&
          (scopeColumn == null || rows[j].read<int>('scope') == scope)) {
        j++;
      }
      final ranks = ranksBetween(null, null, j - i);
      for (var k = i; k < j; k++) {
        backfill.add((rows[k].read<int>('id'), ranks[k - i]));
      }
      i = j;
    }
    await db.batch((b) {
      for (final (id, rank) in backfill) {
        b.customStatement('UPDATE $table SET rank = ? WHERE id = ?', [
          rank,
          id,
        ]);
      }
    });

    await m.alterTable(TableMigration(target));
    await m.createIndex(newIndex);
  }
}

/// Throws a [StateError] naming the `v[from]->v[to]` migration if [violations]
/// (the rows from `PRAGMA foreign_key_check`) is non-empty.
///
/// Runs in every build, not just debug: a migration that leaves a row
/// referencing a missing parent is data corruption, so it must fail loudly —
/// surfacing the offending rows — rather than ship silently. Kept Flutter-free
/// (a plain `throw`, no `kDebugMode`) so the drift schema-dump CLI can run this
/// library without Flutter bindings.
void checkNoForeignKeyViolations(
  List<Map<String, Object?>> violations,
  int from,
  int to,
) {
  if (violations.isEmpty) return;
  throw StateError(
    'Foreign-key violations after v$from->v$to migration: $violations',
  );
}
