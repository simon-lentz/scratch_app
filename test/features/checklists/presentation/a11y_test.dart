import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';
import '../../../support/pump_checklists_screen.dart';

void main() {
  testWidgets('Lists meets tap-target and labelled-tappable guidelines', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final db = memoryDb();
    await db.checklistDao.create('Chores');
    await pumpChecklistsScreen(tester, db: db);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });
}
