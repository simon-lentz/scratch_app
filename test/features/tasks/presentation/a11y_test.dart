import 'package:checkplan/features/tasks/presentation/checklist_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/a11y.dart';
import '../../../support/memory_db.dart';
import '../../../support/pump_checklist_detail_screen.dart';
import '../../../support/test_overrides.dart';

void main() {
  testWidgets('Detail meets tap-target and labelled-tappable guidelines', (
    tester,
  ) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('Chores');
    final task = await db.taskDao.add(list, 'Sweep');
    await db.subtaskDao.add(task, 'Kitchen');
    await pumpChecklistDetailScreen(tester, checklistId: list, db: db);

    await tester.tap(find.byTooltip('Show subtasks')); // reveal the subtask row
    await tester.pumpAndSettle();

    await expectMeetsTapTargetGuidelines(tester);
  });

  testWidgets('detail tiles scale with a 2x text scale without overflow', (
    tester,
  ) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('Chores');
    await db.taskDao.add(list, 'Sweep the kitchen floor');

    // Pumped manually (not via pumpChecklistDetailScreen) only to wrap the
    // screen in a MediaQuery with a 2x textScaler; the overrides mirror the
    // helper. A RenderFlex overflow throws in test mode, so takeException being
    // null proves the tiles lay out at the larger scale.
    await tester.pumpWidget(
      ProviderScope(
        overrides: baseTestOverrides(db: db),
        child: MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: ChecklistDetailScreen(checklistId: list),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Sweep the kitchen floor'), findsOneWidget);
  });
}
