import 'package:checkplan/app/app.dart';
import 'package:checkplan/core/database/database_providers.dart';
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
  });
}
