import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/features/tasks/presentation/widgets/task_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';

void main() {
  testWidgets('shows a subtask hint only when subtasks exist', (tester) async {
    // Build real Task rows via the DAO so the row class is authentic.
    final db = memoryDb();
    final list = await db.checklistDao.create('L');
    await db.taskDao.add(list, 'Task');
    // One-shot read of the persisted row. Awaiting a drift `.watch()` stream
    // in a widget-test body hangs: the frozen fake-async clock never
    // delivers its first emission.
    final task = (await db.select(db.tasks).get()).single;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TaskTile(
                view: TaskView(task: task, subtaskProgress: (0, 0)),
                onToggleDone: (_) {},
              ),
              TaskTile(
                view: TaskView(task: task, subtaskProgress: (1, 3)),
                onToggleDone: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('1/3'), findsOneWidget); // hint for the (1,3) tile
    expect(find.text('0/0'), findsNothing); // no hint for (0,0)
  });
}
