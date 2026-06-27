import 'dart:io' show Platform;

import 'package:checkplan/app/theme.dart';
import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/model/due_status.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:checkplan/features/checklists/presentation/widgets/checklist_tile.dart';
import 'package:checkplan/features/tasks/presentation/widgets/task_tile.dart';
import 'package:checkplan/features/today/presentation/widgets/today_task_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _instant = DateTime.utc(2026);
final _today = EpochDay.fromDateTime(DateTime(2026, 6, 25));

Checklist _checklist({int? colorValue}) => Checklist(
  id: 1,
  title: 'Groceries',
  colorValue: colorValue,
  position: 1,
  createdAt: _instant,
  updatedAt: _instant,
);

Task _task({bool isDone = false, int? dueDay}) => Task(
  id: 1,
  checklistId: 1,
  title: 'Apples',
  isDone: isDone,
  dueDay: dueDay,
  position: 1,
  createdAt: _instant,
  updatedAt: _instant,
);

Future<void> _pumpGolden(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: lightTheme,
      home: Scaffold(
        body: Center(child: SizedBox(width: 360, child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // Goldens are baselined on Linux (CI); each test below skips off Linux, so a
  // macOS `flutter test` stays green and `--update-goldens` writes no baseline
  // on the wrong platform.
  testWidgets('ChecklistTile — no tasks', (tester) async {
    await _pumpGolden(
      tester,
      ChecklistTile(
        summary: ChecklistSummary(checklist: _checklist(), progress: (0, 0)),
        onRename: () {},
        onRecolor: () {},
        onArchive: () {},
        onDelete: () {},
        onOpen: () {},
      ),
    );
    await expectLater(
      find.byType(ChecklistTile),
      matchesGoldenFile('goldens/checklist_tile_empty.png'),
    );
  }, skip: !Platform.isLinux);

  testWidgets('ChecklistTile — partial progress + colour', (tester) async {
    await _pumpGolden(
      tester,
      ChecklistTile(
        summary: ChecklistSummary(
          checklist: _checklist(colorValue: 0xFF00897B),
          progress: (1, 3),
        ),
        onRename: () {},
        onRecolor: () {},
        onArchive: () {},
        onDelete: () {},
        onOpen: () {},
      ),
    );
    await expectLater(
      find.byType(ChecklistTile),
      matchesGoldenFile('goldens/checklist_tile_progress.png'),
    );
  }, skip: !Platform.isLinux);

  testWidgets('TaskTile — overdue, with a subtask hint', (tester) async {
    await _pumpGolden(
      tester,
      TaskTile(
        view: TaskView(
          task: _task(dueDay: _today.value - 3),
          subtaskProgress: (1, 2),
        ),
        today: _today,
        onToggleDone: (_) {},
        onEdit: () {},
        expanded: false,
        onToggleExpanded: () {},
      ),
    );
    await expectLater(
      find.byType(TaskTile),
      matchesGoldenFile('goldens/task_tile_overdue.png'),
    );
  }, skip: !Platform.isLinux);

  testWidgets('TaskTile — done, no due date', (tester) async {
    await _pumpGolden(
      tester,
      TaskTile(
        view: TaskView(task: _task(isDone: true), subtaskProgress: (0, 0)),
        today: _today,
        onToggleDone: (_) {},
        onEdit: () {},
        expanded: false,
        onToggleExpanded: () {},
      ),
    );
    await expectLater(
      find.byType(TaskTile),
      matchesGoldenFile('goldens/task_tile_done.png'),
    );
  }, skip: !Platform.isLinux);

  testWidgets('TodayTaskTile — overdue row', (tester) async {
    await _pumpGolden(
      tester,
      TodayTaskTile(
        entry: TodayTask(
          task: _task(dueDay: _today.value - 1),
          checklistTitle: 'Groceries',
        ),
        status: const Overdue(1),
        onToggleDone: (_) {},
      ),
    );
    await expectLater(
      find.byType(TodayTaskTile),
      matchesGoldenFile('goldens/today_task_tile.png'),
    );
  }, skip: !Platform.isLinux);
}
