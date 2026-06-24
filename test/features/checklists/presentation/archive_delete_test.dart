import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';
import '../../../support/pump_checklists_screen.dart';

void main() {
  testWidgets('archive removes the row and Undo restores it', (tester) async {
    final db = memoryDb();
    await db.checklistDao.create('Temp');
    await pumpChecklistsScreen(tester, db: db);

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
    await pumpChecklistsScreen(tester, db: db);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Doomed'), findsNothing);
  });
}
