import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/features/checklists/application/checklist_providers.dart';
import 'package:checkplan/features/checklists/presentation/checklists_screen.dart';
import 'package:drift/drift.dart' show DatabaseConnection, LazyDatabase;
import 'package:drift/native.dart' show NativeDatabase;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a failed open recovers when the user erases and starts over', (
    tester,
  ) async {
    var opens = 0;
    AppDatabase open() {
      opens++;
      if (opens == 1) {
        // The open throws; drift surfaces it on the first query.
        return AppDatabase(LazyDatabase(() => throw Exception('open failed')));
      }
      return AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
    }

    var deleted = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseOverride(open),
          deleteAppDatabaseProvider.overrideWith(
            (ref) => () async {
              deleted++;
            },
          ),
        ],
        child: const MaterialApp(home: ChecklistsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Something went wrong'), findsOneWidget);

    // Erase & start over: confirm the destructive dialog, then recover.
    await tester.tap(find.text('Erase & start over'));
    await tester.pumpAndSettle();
    // This deliberately re-opens the database, so two AppDatabase instances
    // are briefly alive (the old one's close() is async). drift then logs
    // "created the database class AppDatabase multiple times". It is benign:
    // each open builds its own executor (not the shared QueryExecutor the
    // warning guards against) and the old instance is closed on disposal.
    // Debug-only.
    await tester.tap(find.text('Erase'));
    await tester.pumpAndSettle();

    expect(deleted, 1);
    expect(opens, 2);
    expect(find.textContaining('Something went wrong'), findsNothing);
    expect(find.text('No checklists yet'), findsOneWidget);
  });

  testWidgets('dismissing the erase confirmation deletes nothing', (
    tester,
  ) async {
    var deleted = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeChecklistsProvider.overrideWith(
            (ref) => Stream.error(Exception('boom')),
          ),
          deleteAppDatabaseProvider.overrideWith(
            (ref) => () async {
              deleted++;
            },
          ),
        ],
        child: const MaterialApp(home: ChecklistsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Something went wrong'), findsOneWidget);

    await tester.tap(find.text('Erase & start over'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(deleted, 0);
    expect(find.textContaining('Something went wrong'), findsOneWidget);
  });
}
