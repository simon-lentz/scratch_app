import 'package:checkplan/core/time/epoch_day.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/a11y.dart';
import '../../../support/memory_db.dart';
import '../../../support/pump_today_screen.dart';

void main() {
  testWidgets('Today meets tap-target and labelled-tappable guidelines', (
    tester,
  ) async {
    final today = EpochDay.fromDateTime(DateTime(2026, 6, 25));
    final db = memoryDb();
    final list = await db.checklistDao.create('Chores');
    final id = await db.taskDao.add(list, 'Sweep');
    await db.taskDao.setDueDate(id, today); // surfaces in the Today bucket
    await pumpTodayScreen(tester, db: db, today: today);

    await expectMeetsTapTargetGuidelines(tester);
  });
}
