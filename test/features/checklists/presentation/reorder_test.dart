import 'package:checkplan/features/checklists/presentation/widgets/checklist_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';
import '../../../support/pump_checklists_screen.dart';

void main() {
  testWidgets('reordering rows persists the new order', (tester) async {
    final db = memoryDb();
    final idA = await db.checklistDao.create('A');
    final idB = await db.checklistDao.create('B');
    await pumpChecklistsScreen(tester, db: db);

    // Invoke the reorder callback directly instead of simulating a drag: the
    // default ReorderableListView begins a drag from a long-press on mobile,
    // which `tester.drag` does not perform, so a bare drag would be a no-op.
    // This drives _ChecklistList._reorder (index handling + dispatch); the
    // controller's reorder is covered by checklist_controller_test.dart.
    // onReorderItem already adjusts newIndex, so moving row A (index 0) to the
    // tail of a two-row list is newIndex 1.
    final reorderable = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    reorderable.onReorderItem!(0, 1);
    await tester.pumpAndSettle();

    // Assert on the rendered tile order, not a drift .watch() stream. The
    // screen already holds a live watch subscription created under the
    // test's fake-async clock; awaiting a fresh stream inside
    // tester.runAsync never sees the post-write emission across that clock
    // boundary (the write lands, but delivery is starved) — the original
    // hang. pumpAndSettle advances the fake clock, so the one-way loop
    // rebuilds the list from the DB and the rendered order is the persisted
    // order.
    final orderedIds = tester
        .widgetList<ChecklistTile>(find.byType(ChecklistTile))
        .map((tile) => (tile.key! as ValueKey<int>).value)
        .toList();
    expect(orderedIds, [idB, idA]);
  });
}
