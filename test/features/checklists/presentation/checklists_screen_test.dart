import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/features/checklists/application/checklist_providers.dart';
import 'package:checkplan/features/checklists/presentation/checklists_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';

Widget wrap(AppDatabase db) => ProviderScope(
  overrides: [appDatabaseProvider.overrideWithValue(db)],
  child: const MaterialApp(home: ChecklistsScreen()),
);

void main() {
  testWidgets('shows the empty state when there are no checklists', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(memoryDb()));
    await tester.pumpAndSettle();
    expect(find.text('No checklists yet'), findsOneWidget);
  });

  testWidgets('shows checklists with their progress', (tester) async {
    final db = memoryDb();
    await db.checklistDao.create('Groceries');
    await tester.pumpWidget(wrap(db));
    await tester.pumpAndSettle();

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
}
