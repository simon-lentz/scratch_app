import 'package:checkplan/core/database/daos/settings_dao.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/core/result.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_providers.g.dart';

/// The settings key under which the app theme mode is persisted.
const themeModeKey = 'theme_mode';

/// Maps a persisted theme-mode name to a [ThemeMode]; an absent or unrecognised
/// value defaults to [ThemeMode.system] (the app's launch default).
ThemeMode themeModeFromName(String? name) => switch (name) {
  'light' => ThemeMode.light,
  'dark' => ThemeMode.dark,
  _ => ThemeMode.system,
};

/// The persisted name for [mode] (the inverse of [themeModeFromName]).
String themeModeName(ThemeMode mode) => switch (mode) {
  ThemeMode.light => 'light',
  ThemeMode.dark => 'dark',
  ThemeMode.system => 'system',
};

/// Accessor for the [SettingsDao], backed by the shared database.
@Riverpod(keepAlive: true)
SettingsDao settingsDao(Ref ref) => ref.watch(appDatabaseProvider).settingsDao;

/// The app theme mode, resolved from the persisted setting and defaulting to
/// [ThemeMode.system]. Re-emits whenever the stored value changes.
@Riverpod(keepAlive: true)
Stream<ThemeMode> themeMode(Ref ref) => ref
    .watch(settingsDaoProvider)
    .watchValue(themeModeKey)
    .map(themeModeFromName);

/// Write commands for app settings.
///
/// Holds no state of its own — the database is the state. Each command returns
/// a [Result]: caught exceptions become [Err]; programming bugs (`Error`)
/// propagate.
@Riverpod(keepAlive: true)
class SettingsController extends _$SettingsController {
  @override
  void build() {}

  SettingsDao get _dao => ref.read(settingsDaoProvider);

  /// Persists the app theme [mode].
  Future<Result<void>> setThemeMode(ThemeMode mode) => Result.guard(() async {
    await _dao.setValue(themeModeKey, themeModeName(mode));
  });
}
