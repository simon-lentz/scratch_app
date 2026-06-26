import 'package:checkplan/app/app.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';
import '../../../support/test_overrides.dart';

void main() {
  testWidgets('the task editor modal covers the bottom nav bar', (
    tester,
  ) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('Groceries');
    await db.taskDao.add(list, 'Buy milk');
    await tester.pumpWidget(
      ProviderScope(
        overrides: baseTestOverrides(
          db: db,
          today: EpochDay.fromDateTime(DateTime(2026, 6, 18)),
        ),
        child: const CheckPlanApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Groceries')); // open the detail screen
    await tester.pumpAndSettle();
    // The nav bar is reachable on the detail screen before the editor opens.
    expect(find.byIcon(Icons.today).hitTestable(), findsOneWidget);

    await tester.tap(find.text('Buy milk')); // open the task editor sheet
    await tester.pumpAndSettle();
    expect(find.text('Save'), findsOneWidget);

    // The sheet opens on the root navigator, so its barrier covers the bottom
    // nav bar: it stays mounted but can no longer be tapped, so a tab switch
    // can't abandon the in-progress edit.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byIcon(Icons.today).hitTestable(), findsNothing);
  });
}
