import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/features/tasks/presentation/checklist_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'memory_db.dart';

/// Pumps [ChecklistDetailScreen] for [checklistId] inside a `ProviderScope` +
/// `MaterialApp`, then settles.
///
/// Backs it with a fresh in-memory database from [memoryDb] unless [db] is
/// supplied, i.e. pass a pre-seeded database to render existing tasks. Extra
/// [overrides] layer on top of the database override.
Future<void> pumpChecklistDetailScreen(
  WidgetTester tester, {
  required int checklistId,
  AppDatabase? db,
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db ?? memoryDb()),
        ...overrides,
      ],
      child: MaterialApp(home: ChecklistDetailScreen(checklistId: checklistId)),
    ),
  );
  await tester.pumpAndSettle();
}
