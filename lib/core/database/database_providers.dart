import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/connection.dart';
import 'package:checkplan/core/database/database_reset.dart' as reset;
import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database_providers.g.dart';

/// The single [AppDatabase] instance for the whole app.
///
/// Declared to throw so it must be provided explicitly: `main` overrides it
/// with `openAppDatabase`'s result, and tests override it with an in-memory
/// database. One shared instance is what makes drift's `.watch()` streams
/// re-emit for every write.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) =>
    throw UnimplementedError('appDatabaseProvider must be overridden');

/// The production override for [appDatabaseProvider].
///
/// Builds the database **in the provider body** (not as a fixed value), so
/// `ref.invalidate(appDatabaseProvider)` disposes the current instance and
/// re-runs [open] — re-attempting a failed open. [open] defaults to
/// [openAppDatabase]; tests pass a factory that fails once, then succeeds.
///
/// Disposal swallows a failed instance's close exception: drift re-raises a
/// failed `open()` from `close()`, and that failure is already surfaced via the
/// error view, so Retry never emits an unhandled async error (a genuine `Error`
/// still propagates).
Override appDatabaseOverride([AppDatabase Function() open = openAppDatabase]) =>
    appDatabaseProvider.overrideWith((ref) {
      final db = open();
      ref.onDispose(() async {
        try {
          await db.close();
        } on Exception catch (_) {
          // drift's `LazyDatabase.close()` awaits its open future, so closing a
          // database whose `open()` threw re-raises that exception. It is
          // already surfaced via the error view, so it is dropped on disposal.
        }
      });
      return db;
    });

/// The database-file deletion used by [resetDatabase], injected so tests can
/// override it and touch no real files. Defaults to the platform
/// [reset.deleteAppDatabase] (an unsupported-throwing stub on web, where reset
/// is never offered).
@Riverpod(keepAlive: true)
Future<void> Function() deleteAppDatabase(Ref ref) => reset.deleteAppDatabase;

/// Recovers from an unrecoverable open failure by erasing the database: closes
/// the current connection, deletes the on-disk file via
/// [deleteAppDatabaseProvider], then invalidates [appDatabaseProvider] so it
/// re-opens an empty database and every screen re-renders.
Future<void> resetDatabase(WidgetRef ref) async {
  final database = ref.read(appDatabaseProvider);
  try {
    await database.close();
  } on Exception catch (_) {
    // A failed open re-raises from close(); the file was never locked, so the
    // delete below still proceeds.
  }
  await ref.read(deleteAppDatabaseProvider)();
  ref.invalidate(appDatabaseProvider);
}
