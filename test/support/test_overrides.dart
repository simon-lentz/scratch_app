import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/core/time/current_day.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:flutter_riverpod/misc.dart';
import 'memory_db.dart';

/// The provider overrides shared by the widget-test pump helpers.
///
/// Pins `appDatabaseProvider` to a fresh in-memory database ([db] or a new
/// [memoryDb]) and `currentDayProvider` to a fixed day ([today], default
/// 2026-01-01). Overriding `currentDayProvider` arms no midnight `Timer`, so
/// any helper built on this is timer-safe by construction. Centralizes the
/// database override and the default-day policy in one place.
List<Override> baseTestOverrides({AppDatabase? db, EpochDay? today}) {
  // Build the database once so invalidating appDatabaseProvider re-reads the
  // same instance instead of a fresh empty one.
  final database = db ?? memoryDb();
  return [
    appDatabaseProvider.overrideWith((ref) => database),
    currentDayProvider.overrideWith(
      (ref) => today ?? EpochDay.fromDateTime(DateTime(2026)),
    ),
  ];
}
