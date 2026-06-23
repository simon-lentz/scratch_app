import 'package:drift/drift.dart';

/// A named collection of tasks that forms the root of the
/// Checklist/Task/Subtask hierarchy.
///
/// DateTime values are stored as ISO-8601 text.
///
/// Soft deleted via [archivedAt], hard-deleted with a cascade.
@TableIndex(name: 'checklist_active_order', columns: {#archivedAt, #position})
class Checklists extends Table {
  /// Surrogate PK.
  IntColumn get id => integer().autoIncrement()();

  /// Display title.
  TextColumn get title => text().withLength(min: 1, max: 200)();

  /// Optional theme color
  IntColumn get colorValue => integer().nullable()();

  /// Sort order among active checklists, rewritten as a block on reorder.
  IntColumn get position => integer()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime()();

  /// Last modified timestamp.
  DateTimeColumn get updatedAt => dateTime()();

  /// Archive timestamp.
  DateTimeColumn get archivedAt => dateTime().nullable()();
}
