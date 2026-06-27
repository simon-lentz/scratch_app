import 'package:flutter_test/flutter_test.dart';
import '../../../support/a11y.dart';
import '../../../support/memory_db.dart';
import '../../../support/pump_checklists_screen.dart';

void main() {
  testWidgets('Lists meets tap-target and labelled-tappable guidelines', (
    tester,
  ) async {
    final db = memoryDb();
    await db.checklistDao.create('Chores');
    await pumpChecklistsScreen(tester, db: db);

    await expectMeetsTapTargetGuidelines(tester);
  });
}
