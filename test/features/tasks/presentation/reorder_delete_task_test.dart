import 'package:checkplan/features/tasks/presentation/widgets/task_tile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
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

  testWidgets('a reordered task appears in its new place immediately', (
    tester,
  ) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('List');
    final idA = await db.taskDao.add(list, 'A');
    final idB = await db.taskDao.add(list, 'B');
    await pumpChecklistDetailScreen(tester, db: db, checklistId: list);

    final reorderable = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    reorderable.onReorderItem!(0, 1); // move A to the tail
    // A single frame — before the async write round-trips through the stream.
    await tester.pump();

    final orderedIds = tester
        .widgetList<TaskTile>(find.byType(TaskTile))
        .map((tile) => (tile.key! as ValueKey<int>).value)
        .toList();
    expect(orderedIds, [idB, idA]);
    await tester.pumpAndSettle(); // drain the async write for a clean teardown
  });

  testWidgets("long-pressing an expanded task's subtask does not drag the "
      'parent task', (tester) async {
    // The outer task list reorders by long-press on mobile; the bug was that
    // its long-press region covered an expanded task's subtask rows, so a
    // long-press there hijacked the parent task drag. Force a mobile platform
    // so the default-handle long-press path (not the desktop side-handle) runs.
    // The override is cleared in `finally` (within the body) because the test
    // binding verifies foundation debug vars are unset before tearDowns run.
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      final db = memoryDb();
      final list = await db.checklistDao.create('List');
      final idA = await db.taskDao.add(list, 'A');
      final idB = await db.taskDao.add(list, 'B');
      await db.subtaskDao.add(idA, 'sub');
      await pumpChecklistDetailScreen(tester, db: db, checklistId: list);

      // Expand task A to reveal its subtask row (rendered between A and B).
      await tester.tap(find.byIcon(Icons.expand_more).first);
      await tester.pumpAndSettle();

      // Long-press the subtask row's body (not its grip) and drag down past B.
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('sub')),
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 100));
      await gesture.moveBy(const Offset(0, 60));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 220));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // The parent task order must be unchanged — the long-press on the subtask
      // must not have picked up and reordered task A.
      final order = tester
          .widgetList<TaskTile>(find.byType(TaskTile))
          .map((tile) => (tile.key! as ValueKey<int>).value)
          .toList();
      expect(order, [idA, idB]);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('desktop renders a visible drag grip on each task row', (
    tester,
  ) async {
    // The outer task list disabled the default handle (to scope long-press
    // drags away from nested subtasks), so desktop/web — which has no
    // long-press affordance — needs an explicit grip. Mirrors Flutter's own
    // desktop default-handle rule (grip on linux/windows/macOS).
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      final db = memoryDb();
      final list = await db.checklistDao.create('List');
      await db.taskDao.add(list, 'A');
      await pumpChecklistDetailScreen(tester, db: db, checklistId: list);

      expect(find.byIcon(Icons.drag_handle), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('mobile shows no task drag grip (long-press to reorder)', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      final db = memoryDb();
      final list = await db.checklistDao.create('List');
      await db.taskDao.add(list, 'A');
      await pumpChecklistDetailScreen(tester, db: db, checklistId: list);

      expect(find.byIcon(Icons.drag_handle), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
