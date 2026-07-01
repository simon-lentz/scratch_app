import 'package:checkplan/core/database/tables/tasks.dart';
import 'package:drift/drift.dart';

/// A lean child item of a single task: title and done-state only (no notes or
/// due date).
///
/// DateTime values are stored as ISO-8601 text.
///
/// Deleting the parent task cascades to its subtasks.
@TableIndex(name: 'subtask_task_order', columns: {#taskId, #rank})
class Subtasks extends Table {
  /// Surrogate PK.
  IntColumn get id => integer().autoIncrement()();

  /// Owning task.
  IntColumn get taskId =>
      integer().references(Tasks, #id, onDelete: KeyAction.cascade)();

  /// Display title.
  TextColumn get title => text().withLength(min: 1, max: 200)();

  /// Subtask completion flag, defaults to false.
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();

  /// Fractional sort key within the owning task (see core/database/rank.dart).
  TextColumn get rank => text()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime()();

  /// Last modified timestamp.
  DateTimeColumn get updatedAt => dateTime()();
}
