import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';
import '../../../support/pump_checklist_detail_screen.dart';

void main() {
  testWidgets('expanding a task animates its subtasks open', (tester) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('L');
    final task = await db.taskDao.add(list, 'Apples');
    await db.subtaskDao.add(task, 'Granny Smith');
    await pumpChecklistDetailScreen(tester, checklistId: list, db: db);

    expect(find.byType(AnimatedSize), findsOneWidget);
    expect(find.text('Granny Smith'), findsNothing); // collapsed

    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pump(); // start the reveal
    await tester.pump(const Duration(milliseconds: 100)); // mid-animation
    await tester.pumpAndSettle(); // settle it

    expect(find.text('Granny Smith'), findsOneWidget);
  });
}
