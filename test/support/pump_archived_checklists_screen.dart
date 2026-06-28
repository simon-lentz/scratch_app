import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/features/checklists/presentation/archived_checklists_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'memory_db.dart';

/// Pumps [ArchivedChecklistsScreen] inside a `ProviderScope` + `MaterialApp`,
/// then settles.
///
/// Backs it with a fresh in-memory database from [memoryDb] unless [db] is
/// supplied — pass a pre-seeded database to render existing rows. Extra
/// [overrides] layer on top of the database override.
Future<void> pumpArchivedChecklistsScreen(
  WidgetTester tester, {
  AppDatabase? db,
  List<Override> overrides = const [],
}) async {
  // Build the database once so invalidating appDatabaseProvider re-reads the
  // same instance instead of a fresh empty one.
  final database = db ?? memoryDb();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((ref) => database),
        ...overrides,
      ],
      child: const MaterialApp(home: ArchivedChecklistsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}
