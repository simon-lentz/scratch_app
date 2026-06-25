import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/features/tasks/presentation/widgets/task_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';
import '../../../support/seed_reads.dart';

void main() {
  testWidgets('shows a subtask hint only when subtasks exist', (tester) async {
    // Build real Task rows via the DAO so the row class is authentic.
    final db = memoryDb();
    final list = await db.checklistDao.create('L');
    await db.taskDao.add(list, 'Task');
    // One-shot seed read; awaiting a drift `.watch()` stream here would hang
    // (the widget-test fake-async clock never delivers its first emission).
    final task = await db.readSingleTask();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TaskTile(
                expanded: false,
                onToggleExpanded: () {},
                onEdit: () {},
                view: TaskView(task: task, subtaskProgress: (0, 0)),
                onToggleDone: (_) {},
              ),
              TaskTile(
                expanded: false,
                onToggleExpanded: () {},
                onEdit: () {},
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
