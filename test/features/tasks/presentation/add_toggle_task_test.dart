import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';
import '../../../support/pump_checklist_detail_screen.dart';
import '../../../support/seed_reads.dart';

void main() {
  testWidgets('FAB adds a task; the checkbox toggles done', (tester) async {
    final db = memoryDb();
    final id = await db.checklistDao.create('List');
    await pumpChecklistDetailScreen(tester, db: db, checklistId: id);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Sweep');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('Sweep'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    // One-shot seed read — not a `.watch()` stream, which would hang in a
    // widget-test body where the fake-async clock never delivers its first
    // emission.
    final tasks = await db.readTasks();
    expect(tasks.single.isDone, isTrue);
  });
}
