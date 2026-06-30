import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';
import '../../../support/pump_checklist_detail_screen.dart';

void main() {
  testWidgets('detail resolves an archived checklist title, not the fallback', (
    tester,
  ) async {
    final db = memoryDb();
    final id = await db.checklistDao.create('Old Project');
    await db.checklistDao.archive(id);

    // An archived checklist is absent from the active list; the title must
    // still resolve via the by-id read rather than degrading to 'Checklist'.
    await pumpChecklistDetailScreen(tester, db: db, checklistId: id);

    expect(find.widgetWithText(AppBar, 'Old Project'), findsOneWidget);
  });
}
