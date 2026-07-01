import 'package:checkplan/core/time/epoch_day.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';
import '../../../support/pump_checklist_detail_screen.dart';
import '../../../support/seed_reads.dart';

void main() {
  testWidgets('editing a task through the sheet sets its due date', (
    tester,
  ) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('L');
    await db.taskDao.add(list, 'Task');
    final today = EpochDay.fromDateTime(DateTime(2026, 6, 15));
    await pumpChecklistDetailScreen(
      tester,
      checklistId: list,
      db: db,
      today: today,
    );

    await tester.tap(find.text('Task')); // opens the editor sheet
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add due date'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK')); // accept the initial date (= today)
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final task = await db.readSingleTask();
    expect(task.dueDay, today);
  });
}
