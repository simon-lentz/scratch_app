import 'dart:async';

import 'package:checkplan/core/result.dart';
import 'package:checkplan/core/validation.dart';
import 'package:checkplan/features/tasks/application/subtask_providers.dart';
import 'package:checkplan/features/tasks/presentation/widgets/subtask_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';
import '../../../support/pump_checklist_detail_screen.dart';

/// A subtask controller whose `add` blocks on [release], so a test can hold the
/// first write in flight and fire a second submit into the gap.
class _BlockingSubtaskController extends SubtaskController {
  final release = Completer<void>();
  int addCalls = 0;

  @override
  Future<Result<int>> add(int taskId, String title) async {
    addCalls++;
    await release.future;
    return Ok(addCalls);
  }
}

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

  testWidgets('a rapid double-submit adds the subtask only once', (
    tester,
  ) async {
    final controller = _BlockingSubtaskController();
    final db = memoryDb();
    final list = await db.checklistDao.create('List');
    await db.taskDao.add(list, 'Task');
    await pumpChecklistDetailScreen(
      tester,
      db: db,
      checklistId: list,
      overrides: [subtaskControllerProvider.overrideWith(() => controller)],
    );

    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Add subtask'),
      'dup',
    );
    await tester.pump();

    // Submit twice while the first add is still in flight (the controller
    // blocks on `release`). Invoke onSubmitted directly to bypass the
    // platform keyboard machinery, as the reorder tests drive onReorderItem.
    // Clearing the field before the await means the second submit reads an
    // empty field and cannot re-add.
    final addField = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Add subtask'),
    );
    addField.onSubmitted!('dup');
    addField.onSubmitted!('dup');

    controller.release.complete();
    await tester.pumpAndSettle();

    expect(controller.addCalls, 1);
  });

  testWidgets('the inline add caps an over-length title instead of dropping '
      'it', (tester) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('List');
    await db.taskDao.add(list, 'Task');
    await pumpChecklistDetailScreen(tester, db: db, checklistId: list);

    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Add subtask'),
      'a' * (maxTitleLength + 50),
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Without the length cap the over-length title is silently dropped and no
    // row is created; with it, the title is capped and the subtask is added.
    final subtasks = await db.select(db.subtasks).get();
    expect(subtasks.single.title.length, maxTitleLength);
  });
}
