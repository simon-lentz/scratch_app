import 'package:checkplan/core/database/tables/checklists.dart';
import 'package:drift/drift.dart';

/// A single to-do item belonging to exactly one checklist.
///
/// An item may have its own subtasks.
///
/// DateTime values are stored as ISO-8601 text.
///
/// An item's completion status ([isDone]) is independent of its subtasks.
@TableIndex(name: 'task_checklist_order', columns: {#checklistId, #position})
@TableIndex(name: 'task_due', columns: {#dueDay})
class Tasks extends Table {
  /// Surrogate PK.
  IntColumn get id => integer().autoIncrement()();

  /// Owning checklist.
  IntColumn get checklistId =>
      integer().references(Checklists, #id, onDelete: KeyAction.cascade)();

  /// Display title.
  TextColumn get title => text().withLength(min: 1, max: 200)();

  /// Optional notes.
  TextColumn get notes => text().nullable()();

  /// Task completion flag, defaults to false.
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();

  /// Optional due date.
  IntColumn get dueDay => integer().nullable()();

  /// Position of the task within its checklist.
  IntColumn get position => integer()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime()();

  /// Last updated timestamp.
  DateTimeColumn get updatedAt => dateTime()();
}
