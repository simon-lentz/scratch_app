import 'dart:async';

import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/features/checklists/application/checklist_providers.dart';
import 'package:checkplan/features/checklists/presentation/checklists_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';
import '../../../support/pump_checklists_screen.dart';

void main() {
  testWidgets('shows the empty state when there are no checklists', (
    tester,
  ) async {
    await pumpChecklistsScreen(tester);
    expect(find.text('No checklists yet'), findsOneWidget);
  });

  testWidgets('shows checklists with their progress', (tester) async {
    final db = memoryDb();
    await db.checklistDao.create('Groceries');
    await pumpChecklistsScreen(tester, db: db);

    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('No tasks'), findsOneWidget); // total == 0, not "0/0"
  });

  testWidgets('shows the error state when the stream fails', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeChecklistsProvider.overrideWith(
            (ref) => Stream.error(Exception('boom')),
          ),
        ],
        child: const MaterialApp(home: ChecklistsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Something went wrong'), findsOneWidget);
  });

  testWidgets('shows the FAB in the empty state', (tester) async {
    await pumpChecklistsScreen(tester);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('hides the FAB while loading', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeChecklistsProvider.overrideWith(
            // A stream that never emits keeps the provider in AsyncLoading.
            (ref) => Stream<List<ChecklistSummary>>.fromFuture(
              Completer<List<ChecklistSummary>>().future,
            ),
          ),
        ],
        child: const MaterialApp(home: ChecklistsScreen()),
      ),
    );
    await tester.pump(); // one frame; do not settle (the spinner animates)
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('hides the FAB in the error state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeChecklistsProvider.overrideWith(
            (ref) => Stream.error(Exception('boom')),
          ),
        ],
        child: const MaterialApp(home: ChecklistsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('Retry re-runs the read and recovers', (tester) async {
    // Key the failure on the database instance, not a build counter: Riverpod
    // rebuilds a dependent once more right after the provider it watches is
    // first created, so the override body runs twice for the initial database.
    // Retry's invalidate yields a *new* instance, so the read then recovers.
    final databases = <AppDatabase>{};
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          memoryDbOverride(),
          activeChecklistsProvider.overrideWith((ref) {
            databases.add(ref.watch(appDatabaseProvider));
            return databases.length == 1
                ? Stream<List<ChecklistSummary>>.error(Exception('read failed'))
                : Stream.value(const <ChecklistSummary>[]);
          }),
        ],
        child: const MaterialApp(home: ChecklistsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Something went wrong'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Something went wrong'), findsNothing);
    expect(find.text('No checklists yet'), findsOneWidget);
  });
}
