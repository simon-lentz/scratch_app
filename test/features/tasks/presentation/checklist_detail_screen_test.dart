import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/features/tasks/application/task_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';
import '../../../support/pump_checklist_detail_screen.dart';

void main() {
  testWidgets('shows the empty state when the checklist has no tasks', (
    tester,
  ) async {
    final db = memoryDb();
    final id = await db.checklistDao.create('List');
    await pumpChecklistDetailScreen(tester, db: db, checklistId: id);
    expect(find.text('No tasks yet'), findsOneWidget);
  });

  testWidgets('shows the checklist title and its tasks', (tester) async {
    final db = memoryDb();
    final id = await db.checklistDao.create('Chores');
    await db.taskDao.add(id, 'Sweep');
    await pumpChecklistDetailScreen(tester, db: db, checklistId: id);

    expect(find.widgetWithText(AppBar, 'Chores'), findsOneWidget);
    expect(find.text('Sweep'), findsOneWidget);
  });

  testWidgets('shows the error state when the stream fails', (tester) async {
    // A real (empty) DB backs the title lookup; the tasks read is overridden to
    // error so the body renders the error view.
    await pumpChecklistDetailScreen(
      tester,
      checklistId: 1,
      overrides: [
        tasksForChecklistProvider.overrideWith(
          (ref, id) => Stream<List<TaskView>>.error(Exception('boom')),
        ),
      ],
    );
    expect(find.textContaining('Something went wrong'), findsOneWidget);
  });
}
