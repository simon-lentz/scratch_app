import 'package:checkplan/core/database/converters/epoch_day_converter.dart';
import 'package:checkplan/core/database/daos/checklist_dao.dart';
import 'package:checkplan/core/database/daos/subtask_dao.dart';
import 'package:checkplan/core/database/daos/task_dao.dart';
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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      // SQLite enforces foreign keys per connection only when asked to;
      // without this, onDelete: cascade is silently ignored.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
