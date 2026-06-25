import 'package:checkplan/core/result.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:checkplan/features/tasks/application/subtask_providers.dart';
import 'package:checkplan/features/tasks/application/task_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';
import '../../../support/pump_checklist_detail_screen.dart';

/// Task commands all fail, to drive the detail screen's error feedback while
/// reads still come from a real in-memory DB so rows render to act on.
class _FailingTaskController extends TaskController {
  static Err<T> _boom<T>() => Err(Exception('boom'));

  @override
  Future<Result<int>> add(int checklistId, String title) async => _boom();
  @override
  Future<Result<void>> edit(
    int id, {
    required String title,
    String? notes,
    EpochDay? dueDay,
  }) async => _boom();
  @override
  Future<Result<void>> setDone(int id, {required bool isDone}) async => _boom();
  @override
  Future<Result<void>> delete(int id) async => _boom();
  @override
  Future<Result<void>> reorder(int checklistId, List<int> orderedIds) async =>
      _boom();
}

/// Subtask commands all fail, to drive the inline subtask error feedback.
class _FailingSubtaskController extends SubtaskController {
  static Err<T> _boom<T>() => Err(Exception('boom'));

  @override
  Future<Result<int>> add(int taskId, String title) async => _boom();
  @override
  Future<Result<void>> setDone(int id, {required bool isDone}) async => _boom();
  @override
  Future<Result<void>> delete(int id) async => _boom();
}

void main() {
  testWidgets('add-task failure shows an error', (tester) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('List');
    await pumpChecklistDetailScreen(
      tester,
      db: db,
      checklistId: list,
      overrides: [
        taskControllerProvider.overrideWith(_FailingTaskController.new),
      ],
    );
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Sweep');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('Could not add the task'), findsOneWidget);
  });

  testWidgets('toggle-task failure shows an error', (tester) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('List');
    await db.taskDao.add(list, 'Task');
    await pumpChecklistDetailScreen(
      tester,
      db: db,
      checklistId: list,
      overrides: [
        taskControllerProvider.overrideWith(_FailingTaskController.new),
      ],
    );
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(find.text('Could not update the task'), findsOneWidget);
  });

  testWidgets('edit-task failure shows an error', (tester) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('List');
    await db.taskDao.add(list, 'Task');
    await pumpChecklistDetailScreen(
      tester,
      db: db,
      checklistId: list,
      overrides: [
        taskControllerProvider.overrideWith(_FailingTaskController.new),
      ],
    );
    await tester.tap(find.text('Task'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Could not save the task'), findsOneWidget);
  });

  testWidgets('delete-task failure shows an error and keeps the row', (
    tester,
  ) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('List');
    await db.taskDao.add(list, 'Doomed');
    await pumpChecklistDetailScreen(
      tester,
      db: db,
      checklistId: list,
      overrides: [
        taskControllerProvider.overrideWith(_FailingTaskController.new),
      ],
    );
    await tester.drag(find.text('Doomed'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Could not delete the task'), findsOneWidget);
    expect(find.text('Doomed'), findsOneWidget); // delete failed -> row stays
  });

  testWidgets('reorder-task failure shows an error', (tester) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('List');
    await db.taskDao.add(list, 'A');
    await db.taskDao.add(list, 'B');
    await pumpChecklistDetailScreen(
      tester,
      db: db,
      checklistId: list,
      overrides: [
        taskControllerProvider.overrideWith(_FailingTaskController.new),
      ],
    );
    final reorderable = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    reorderable.onReorderItem!(0, 1);
    await tester.pumpAndSettle();
    expect(find.text('Could not reorder the tasks'), findsOneWidget);
  });

  testWidgets('add-subtask failure shows an error', (tester) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('List');
    await db.taskDao.add(list, 'Task');
    await pumpChecklistDetailScreen(
      tester,
      db: db,
      checklistId: list,
      overrides: [
        subtaskControllerProvider.overrideWith(_FailingSubtaskController.new),
      ],
    );
    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Add subtask'), 'a');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Could not add the subtask'), findsOneWidget);
  });

  testWidgets('toggle-subtask failure shows an error', (tester) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('List');
    final taskId = await db.taskDao.add(list, 'Task');
    await db.subtaskDao.add(taskId, 'Step'); // a real subtask to act on
    await pumpChecklistDetailScreen(
      tester,
      db: db,
      checklistId: list,
      overrides: [
        subtaskControllerProvider.overrideWith(_FailingSubtaskController.new),
      ],
    );
    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).last); // the subtask's checkbox
    await tester.pumpAndSettle();
    expect(find.text('Could not update the subtask'), findsOneWidget);
  });

  testWidgets('delete-subtask failure shows an error', (tester) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('List');
    final taskId = await db.taskDao.add(list, 'Task');
    await db.subtaskDao.add(taskId, 'Step');
    await pumpChecklistDetailScreen(
      tester,
      db: db,
      checklistId: list,
      overrides: [
        subtaskControllerProvider.overrideWith(_FailingSubtaskController.new),
      ],
    );
    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close)); // the subtask's delete button
    await tester.pumpAndSettle();
    expect(find.text('Could not delete the subtask'), findsOneWidget);
  });
}
