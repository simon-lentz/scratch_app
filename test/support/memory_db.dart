import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens a fresh in-memory [AppDatabase] for a widget test and registers its
/// `close()` as a tear-down.
///
/// The executor is a private in-memory [NativeDatabase] wrapped in a
/// [DatabaseConnection] with `closeStreamsSynchronously: true`, so drift tears
/// its stream queries down synchronously and no stray timer fires after the
/// test completes.
///
/// The baked-in `addTearDown(db.close)` is load-bearing: a `ProviderScope`
/// `overrideWithValue` does not dispose the value it is handed, so without it
/// each widget test would leak its database. A leaked instance also trips
/// drift's debug-only multiple-database warning, which counts live
/// [AppDatabase] instances per test isolate and only decrements that count
/// on `close()`.
AppDatabase memoryDb() {
  final db = AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
  addTearDown(db.close);
  return db;
}

/// An [appDatabaseProvider] override backed by a fresh in-memory database that
/// the provider container owns and closes via `ref.onDispose`.
///
/// The `ProviderContainer.test` counterpart to [memoryDb] (which is
/// widget-scoped via `addTearDown`); `overrideWithValue` would leak the DB.
/// Like [memoryDb], it sets `closeStreamsSynchronously: true` so a disposed
/// test's stream queries tear down synchronously and no late drift callback
/// can fire during a concurrent test.
Override memoryDbOverride() => appDatabaseProvider.overrideWith((ref) {
  final db = AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
  ref.onDispose(db.close);
  return db;
});
