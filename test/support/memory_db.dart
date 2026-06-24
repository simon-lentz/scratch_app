import 'package:checkplan/core/database/app_database.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
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
