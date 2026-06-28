import 'package:checkplan/core/result.dart';
import 'package:checkplan/features/checklists/application/checklist_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';
import '../../../support/pump_archived_checklists_screen.dart';

/// A controller whose restore/delete fail, to drive the archive view's error
/// feedback. Reads still come from the real in-memory DB, so a row renders to
/// act on.
class _FailingController extends ChecklistController {
  static Err<T> _boom<T>() => Err(Exception('boom'));

  @override
  Future<Result<void>> restore(int id) async => _boom();
  @override
  Future<Result<void>> delete(int id) async => _boom();
}

void main() {
  testWidgets('lists archived checklists with their colour', (tester) async {
    final db = memoryDb();
    final id = await db.checklistDao.create('Old project');
    final colorValue = Colors.red.toARGB32();
    await db.checklistDao.setColor(id, colorValue);
    await db.checklistDao.archive(id);
    await pumpArchivedChecklistsScreen(tester, db: db);

    expect(find.text('Old project'), findsOneWidget);
    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
    expect(avatar.backgroundColor, Color(colorValue));
  });

  testWidgets('shows the empty state when nothing is archived', (tester) async {
    final db = memoryDb();
    await db.checklistDao.create('Still active'); // active, not archived
    await pumpArchivedChecklistsScreen(tester, db: db);

    expect(find.text('Nothing archived'), findsOneWidget);
  });

  testWidgets('Restore removes it from the archived list', (tester) async {
    final db = memoryDb();
    final id = await db.checklistDao.create('Revive me');
    await db.checklistDao.archive(id);
    await pumpArchivedChecklistsScreen(tester, db: db);
    expect(find.text('Revive me'), findsOneWidget);

    await tester.tap(find.byTooltip('Restore'));
    await tester.pumpAndSettle();

    // The reactive archived stream re-emits without it.
    expect(find.text('Revive me'), findsNothing);
  });

  testWidgets('Delete asks for confirmation then removes the row', (
    tester,
  ) async {
    final db = memoryDb();
    final id = await db.checklistDao.create('Trash');
    await db.checklistDao.archive(id);
    await pumpArchivedChecklistsScreen(tester, db: db);

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Trash'), findsNothing);
  });

  testWidgets('Restore failure shows an error and keeps the row', (
    tester,
  ) async {
    final db = memoryDb();
    final id = await db.checklistDao.create('Stuck');
    await db.checklistDao.archive(id);
    await pumpArchivedChecklistsScreen(
      tester,
      db: db,
      overrides: [
        checklistControllerProvider.overrideWith(_FailingController.new),
      ],
    );

    await tester.tap(find.byTooltip('Restore'));
    await tester.pumpAndSettle();

    expect(find.text('Could not restore the checklist'), findsOneWidget);
    expect(find.text('Stuck'), findsOneWidget); // row stays (DB untouched)
  });

  testWidgets('Delete failure shows an error and keeps the row', (
    tester,
  ) async {
    final db = memoryDb();
    final id = await db.checklistDao.create('Stuck');
    await db.checklistDao.archive(id);
    await pumpArchivedChecklistsScreen(
      tester,
      db: db,
      overrides: [
        checklistControllerProvider.overrideWith(_FailingController.new),
      ],
    );

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Could not delete the checklist'), findsOneWidget);
    expect(find.text('Stuck'), findsOneWidget); // row stays (DB untouched)
  });
}
