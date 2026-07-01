import 'package:drift/drift.dart';

/// A key-value store for app-wide preferences — the theme mode today, and later
/// other UI toggles and per-device sync state. One row per setting [key].
///
/// Deliberately generic (`String` value) and Flutter-free: it sits in the
/// `@DriftDatabase` graph, which the migration CLI analyses under the Dart VM,
/// so no `ThemeMode`/widget types leak in — typed mapping lives in the feature
/// layer.
class Settings extends Table {
  /// The setting's unique key (its primary key).
  TextColumn get key => text()();

  /// The setting's value, serialized as text by the feature layer.
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
