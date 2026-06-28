import 'package:checkplan/app/app.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/core/time/current_day.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';

void main() {
  testWidgets('a due task surfaces in the Today tab', (tester) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('Errands');
    final id = await db.taskDao.add(list, 'Call dentist');
    final today = EpochDay.fromDateTime(DateTime(2026, 6, 25));
    await db.taskDao.setDueDate(id, today); // due today

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => db),
          currentDayProvider.overrideWith((ref) => today),
        ],
        child: const CheckPlanApp(),
      ),
    );
    await tester.pumpAndSettle();

    // The app opens on Lists; switch to Today.
    await tester.tap(find.byIcon(Icons.today));
    await tester.pumpAndSettle();

    expect(find.text('Call dentist'), findsOneWidget);
    expect(find.text('Errands'), findsWidgets); // parent checklist subtitle
  });
}
