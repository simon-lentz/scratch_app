import 'package:checkplan/features/tasks/presentation/widgets/task_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';
import '../../../support/pump_checklist_detail_screen.dart';

void main() {
  testWidgets('reordering rows persists the new order', (tester) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('List');
    final idA = await db.taskDao.add(list, 'A');
    final idB = await db.taskDao.add(list, 'B');
    await pumpChecklistDetailScreen(tester, db: db, checklistId: list);

    // Invoke the callback directly (a bare drag is a long-press gesture the
    // tester does not perform); onReorderItem already adjusts newIndex.
    final reorderable = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    reorderable.onReorderItem!(0, 1);
    await tester.pumpAndSettle();

    final orderedIds = tester
        .widgetList<TaskTile>(find.byType(TaskTile))
        .map((tile) => (tile.key! as ValueKey<int>).value)
        .toList();
    expect(orderedIds, [idB, idA]);
  });

  testWidgets('swipe-to-delete confirms then removes the task', (tester) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('List');
    await db.taskDao.add(list, 'Doomed');
    await pumpChecklistDetailScreen(tester, db: db, checklistId: list);

    await tester.drag(find.text('Doomed'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Doomed'), findsNothing);
  });
}
