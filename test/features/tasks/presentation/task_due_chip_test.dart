import 'package:checkplan/core/time/epoch_day.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';
import '../../../support/pump_checklist_detail_screen.dart';

void main() {
  testWidgets('the detail screen shows a due-date chip', (tester) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('L');
    final id = await db.taskDao.add(list, 'Task');
    final today = EpochDay.fromDateTime(DateTime(2026, 6, 18));
    await db.taskDao.setDueDate(id, today); // due today

    await pumpChecklistDetailScreen(
      tester,
      checklistId: list,
      db: db,
      today: today,
    );

    expect(find.text('Today'), findsOneWidget);
  });
}
