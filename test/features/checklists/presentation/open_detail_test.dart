import 'package:checkplan/app/app.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/features/checklists/presentation/widgets/checklist_tile.dart';
import 'package:checkplan/features/tasks/presentation/checklist_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';

void main() {
  testWidgets('tapping a checklist pushes its detail screen', (tester) async {
    final db = memoryDb();
    await db.checklistDao.create('Groceries');
    // The full app (router) is needed: tapping pushes /checklist/:id.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const CheckPlanApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Groceries'));
    await tester.pumpAndSettle();

    // The detail app bar shows the checklist title and its empty state.
    expect(find.widgetWithText(AppBar, 'Groceries'), findsOneWidget);
    expect(find.text('No tasks yet'), findsOneWidget);
    // The detail route is nested under the Lists branch, so it keeps the
    // shell's bottom navigation bar instead of replacing the whole screen.
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('a repeat open is ignored while detail is already up', (
    tester,
  ) async {
    final db = memoryDb();
    final id = await db.checklistDao.create('Groceries');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const CheckPlanApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Groceries')); // first open -> pushes detail
    await tester.pumpAndSettle();
    expect(find.byType(ChecklistDetailScreen), findsOneWidget);

    // The list tile is still mounted (offstage) behind the detail route;
    // re-firing its onOpen must not stack a second detail screen.
    tester
        .widget<ChecklistTile>(find.byKey(ValueKey(id), skipOffstage: false))
        .onOpen();
    await tester.pumpAndSettle();
    expect(find.byType(ChecklistDetailScreen), findsOneWidget); // still one
  });
}
