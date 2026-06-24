import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/features/checklists/presentation/checklists_screen.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AppDatabase memoryDb() => AppDatabase(
  DatabaseConnection(
    NativeDatabase.memory(),
    closeStreamsSynchronously: true,
  ),
);

Future<void> pumpScreen(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const MaterialApp(home: ChecklistsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('archive removes the row and Undo restores it', (tester) async {
    final db = memoryDb();
    await db.checklistDao.create('Temp');
    await pumpScreen(tester, db);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    expect(find.text('Temp'), findsNothing);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Temp'), findsOneWidget);
  });

  testWidgets('delete asks for confirmation then removes the row', (
    tester,
  ) async {
    final db = memoryDb();
    await db.checklistDao.create('Doomed');
    await pumpScreen(tester, db);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Doomed'), findsNothing);
  });
}
