import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/tables/settings.dart';
import 'package:drift/drift.dart';

part 'settings_dao.g.dart';

/// Reads and writes app preferences in the key-value [Settings] table.
///
/// Generic and Flutter-free by design (values are opaque `String`s): the typed
/// `ThemeMode` mapping lives in the settings feature layer, keeping the
/// `@DriftDatabase` graph importable under the Dart VM (the migration CLI).
@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  /// Binds the DAO to its attached database.
  SettingsDao(super.attachedDatabase);

  /// The value stored under [key], or `null` if unset; re-emits on every write.
  Stream<String?> watchValue(String key) =>
      (select(settings)..where((s) => s.key.equals(key)))
          .watchSingleOrNull()
          .map((row) => row?.value);

  /// Stores [value] under [key], inserting or replacing the existing row (the
  /// primary key is [key]).
  Future<void> setValue(String key, String value) => into(
    settings,
  ).insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
}
