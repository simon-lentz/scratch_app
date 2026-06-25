import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';
import '../../../support/pump_checklist_detail_screen.dart';

void main() {
  testWidgets('tapping a task edits its title', (tester) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('List');
    await db.taskDao.add(list, 'Old name');
    await pumpChecklistDetailScreen(tester, db: db, checklistId: list);

    await tester.tap(find.text('Old name'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Fresh');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Fresh'), findsOneWidget);
    expect(find.text('Old name'), findsNothing);
  });
}
