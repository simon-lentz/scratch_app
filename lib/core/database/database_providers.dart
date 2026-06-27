import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/connection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

/// The single [AppDatabase] instance for the whole app.
///
/// Declared to throw so it must be provided explicitly: `main` overrides it
/// with `openAppDatabase`'s result, and tests override it with an in-memory
/// database. One shared instance is what makes drift's `.watch()` streams
/// re-emit for every write.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider must be overridden'),
);

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
