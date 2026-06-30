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
      // The foreign_keys pragma can't toggle inside a transaction, so disable
      // it first, run the steps in one transaction (atomic across all three
      // tables), verify nothing dangles, then re-enable.
      await customStatement('PRAGMA foreign_keys = OFF');
      await transaction(
        () => m.runMigrationSteps(
          from: from,
          to: to,
          steps: migrationSteps(from1To2: _from1To2),
        ),
      );
      // Run the FK check unconditionally (cheap, one-time on a small local DB);
      // the assert is stripped in release. Deliberately avoids kDebugMode so
      // this library stays Flutter-free and the drift schema-dump CLI keeps
      // working without --export-schema-startup-code.
      final violations = await customSelect('PRAGMA foreign_key_check').get();
      assert(
        violations.isEmpty,
        'Foreign-key violations after v$from->v$to migration: '
        '${violations.map((r) => r.data).toList()}',
      );
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
        await db.customUpdate(
          'UPDATE $table SET rank = ? WHERE id = ?',
          variables: [
            Variable<String>(ranks[k - i]),
            Variable<int>(rows[k].read<int>('id')),
          ],
        );
      }
      i = j;
    }

    await m.alterTable(TableMigration(target));
    await m.createIndex(newIndex);
  }
}
