import 'package:checkplan/features/tasks/presentation/widgets/subtask_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';
import '../../../support/pump_checklist_detail_screen.dart';

void main() {
  testWidgets('expand, add, toggle, and delete a subtask; hint updates', (
    tester,
  ) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('List');
    await db.taskDao.add(list, 'Task');
    await pumpChecklistDetailScreen(tester, db: db, checklistId: list);

    // Expand the task to reveal the inline add field.
    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Add subtask'), 'a');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byType(SubtaskTile), findsOneWidget);
    expect(find.text('0/1'), findsOneWidget); // hint now non-zero

    // Toggle it done -> hint becomes 1/1.
    await tester.tap(find.byType(Checkbox).last);
    await tester.pumpAndSettle();
    expect(find.text('1/1'), findsOneWidget);

    // Delete it -> back to no subtasks, no hint.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(SubtaskTile), findsNothing);
    expect(find.textContaining('/'), findsNothing);
  });
}
