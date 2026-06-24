import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/features/checklists/presentation/checklists_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'memory_db.dart';

/// Pumps [ChecklistsScreen] inside a `ProviderScope` + `MaterialApp`, then
/// settles.
///
/// Backs it with a fresh in-memory database from [memoryDb] unless [db] is
/// supplied — pass a pre-seeded database to render existing rows. Extra
/// [overrides] layer on top of the database override (e.g. a fake controller
/// for failure tests).
Future<void> pumpChecklistsScreen(
  WidgetTester tester, {
  AppDatabase? db,
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db ?? memoryDb()),
        ...overrides,
      ],
      child: const MaterialApp(home: ChecklistsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}
