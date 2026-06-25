import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';
import '../../../support/pump_checklists_screen.dart';

void main() {
  testWidgets('renames a checklist via the overflow menu', (tester) async {
    final db = memoryDb();
    await db.checklistDao.create('Old name');
    await pumpChecklistsScreen(tester, db: db);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Fresh name');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Fresh name'), findsOneWidget);
    expect(find.text('Old name'), findsNothing);
  });

  testWidgets('recolors via the menu, then Default clears the color', (
    tester,
  ) async {
    final db = memoryDb();
    await db.checklistDao.create('Palette');
    await pumpChecklistsScreen(tester, db: db);

    // setColor is dispatched fire-and-forget by the swatch tap, so assert the
    // reactive result on the rendered tile, not the DB: pumpAndSettle settles
    // the UI, so the tile's avatar color is the deterministic signal (the
    // persisted value itself is covered by the controller test). Recolor rows
    // are labelled by hex; Colors.blue is 0xFF2196F3.
    Color? avatarColor() =>
        tester.widget<CircleAvatar>(find.byType(CircleAvatar)).backgroundColor;

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recolor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('#FF2196F3'));
    await tester.pumpAndSettle();
    expect(avatarColor(), const Color(0xFF2196F3));

    // Default clears back to null (distinct from a dismissed dialog).
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recolor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Default'));
    await tester.pumpAndSettle();
    expect(avatarColor(), isNull);
  });

  testWidgets('renders the progress bar for a checklist with tasks', (
    tester,
  ) async {
    // Seed 1-done-of-2 so watchActiveSummaries reports (1, 2): this exercises
    // the tile's non-zero progress branch (the done/total text + bar), which
    // the create-only flows never reach (they always render "No tasks").
    final db = memoryDb();
    final id = await db.checklistDao.create('Chores');
    final first = await db.taskDao.add(id, 'a');
    await db.taskDao.add(id, 'b');
    await db.taskDao.setDone(first, isDone: true);
    await pumpChecklistsScreen(tester, db: db);

    expect(find.text('1/2'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}
