import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:checkplan/features/tasks/presentation/widgets/task_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';
import '../../../support/seed_reads.dart';

void main() {
  final today = EpochDay.fromDateTime(DateTime(2026, 6, 20));

  testWidgets('shows a subtask hint only when subtasks exist', (tester) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('L');
    await db.taskDao.add(list, 'Task');
    final task = await db.readSingleTask();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TaskTile(
                today: today,
                expanded: false,
                onToggleExpanded: () {},
                onEdit: () {},
                view: TaskView(task: task, subtaskProgress: (0, 0)),
                onToggleDone: (_) {},
              ),
              TaskTile(
                today: today,
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

  testWidgets('shows a due-date chip when the task has a due date', (
    tester,
  ) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('L');
    final id = await db.taskDao.add(list, 'Task');
    await db.taskDao.setDueDate(
      id,
      EpochDay.fromDateTime(DateTime(2026, 6, 18)),
    );
    final task = await db.readSingleTask();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskTile(
            today: today, // 2026-06-20, two days after the due date
            expanded: false,
            onToggleExpanded: () {},
            onEdit: () {},
            view: TaskView(task: task, subtaskProgress: (0, 0)),
            onToggleDone: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Overdue 2d'), findsOneWidget);
  });
}
