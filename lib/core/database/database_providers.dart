import 'package:checkplan/core/database/app_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The single [AppDatabase] instance for the whole app.
///
/// Declared to throw so it must be provided explicitly: `main` overrides it
/// with `openAppDatabase`'s result, and tests override it with an in-memory
/// database. One shared instance is what makes drift's `.watch()` streams
/// re-emit for every write.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider must be overridden'),
);
