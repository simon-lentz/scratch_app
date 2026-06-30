import 'package:drift/drift.dart';

/// A named collection of tasks that forms the root of the
/// Checklist/Task/Subtask hierarchy.
///
/// DateTime values are stored as ISO-8601 text.
///
/// Soft deleted via [archivedAt], hard-deleted with a cascade.
@TableIndex(name: 'checklist_active_order', columns: {#archivedAt, #rank})
class Checklists extends Table {
  /// Surrogate PK.
  IntColumn get id => integer().autoIncrement()();

  /// Display title.
  TextColumn get title => text().withLength(min: 1, max: 200)();

  /// Optional theme color
  IntColumn get colorValue => integer().nullable()();

  /// Fractional sort key among checklists; a reorder rewrites only the moved
  /// row's key (see core/database/rank.dart).
  TextColumn get rank => text()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime()();

  /// Last modified timestamp.
  DateTimeColumn get updatedAt => dateTime()();

  /// Archive timestamp.
  DateTimeColumn get archivedAt => dateTime().nullable()();
}
