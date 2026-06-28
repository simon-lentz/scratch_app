import 'package:checkplan/core/time/current_day.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:checkplan/features/tasks/presentation/widgets/task_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';
import '../../../support/seed_reads.dart';

void main() {
  final today = EpochDay.fromDateTime(DateTime(2026, 6, 15));

  testWidgets('edits title and notes and returns the draft', (tester) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('L');
    await db.taskDao.add(list, 'Old');
    final task = await db.readSingleTask();

    TaskDraft? draft;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentDayProvider.overrideWith((ref) => today)],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async =>
                    draft = await showTaskEditorSheet(context, task: task),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Title'), 'New');
    await tester.enterText(find.widgetWithText(TextField, 'Notes'), 'a note');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(draft?.title, 'New');
    expect(draft?.notes, 'a note');
  });

  testWidgets('picking a due date returns it in the draft', (tester) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('L');
    await db.taskDao.add(list, 'Task');
    final task = await db.readSingleTask();

    TaskDraft? draft;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentDayProvider.overrideWith((ref) => today)],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async =>
                    draft = await showTaskEditorSheet(context, task: task),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add due date'));
    await tester.pumpAndSettle();
    // Accept the pre-selected initialDate, which is `today` (read from
    // currentDayProvider at pick time).
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(draft?.dueDay, today);
  });

  testWidgets('clearing a due date returns null in the draft', (tester) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('L');
    final id = await db.taskDao.add(list, 'Task');
    await db.taskDao.setDueDate(
      id,
      EpochDay.fromDateTime(DateTime(2026, 6, 20)),
    );
    final task = await db.readSingleTask();

    TaskDraft? draft;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentDayProvider.overrideWith((ref) => today)],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async =>
                    draft = await showTaskEditorSheet(context, task: task),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Clear due date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(draft?.dueDay, isNull);
  });
}
