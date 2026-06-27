import 'package:checkplan/core/time/epoch_day.dart';
import 'package:checkplan/core/widgets/due_date_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';
import '../../../support/pump_today_screen.dart';

void main() {
  final today = EpochDay.fromDateTime(DateTime(2026, 6, 18));

  testWidgets('groups overdue and due-today tasks into sections', (
    tester,
  ) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('Errands');
    final overdue = await db.taskDao.add(list, 'Pay rent');
    final onToday = await db.taskDao.add(list, 'Call dentist');
    await db.taskDao.setDueDate(
      overdue,
      EpochDay.fromDateTime(DateTime(2026, 6, 17)),
    );
    await db.taskDao.setDueDate(onToday, today);

    await pumpTodayScreen(tester, db: db, today: today);

    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('Pay rent'), findsOneWidget);
    expect(find.text('Call dentist'), findsOneWidget);
    expect(find.text('Errands'), findsWidgets); // parent checklist subtitle
    // The chip shows only under Overdue: the overdue row carries it, the
    // due-today row does not (its section header already says "today").
    expect(find.byType(DueDateChip), findsOneWidget);
    expect(find.text('Overdue 1d'), findsOneWidget);
  });

  testWidgets('shows the empty state when nothing is due', (tester) async {
    await pumpTodayScreen(tester, today: today);
    expect(find.text('Nothing due — nice.'), findsOneWidget);
  });

  testWidgets('checking a task off removes it from Today', (tester) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('Errands');
    final id = await db.taskDao.add(list, 'Call dentist');
    await db.taskDao.setDueDate(id, today);

    await pumpTodayScreen(tester, db: db, today: today);
    expect(find.text('Call dentist'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(find.text('Call dentist'), findsNothing); // setDone -> leaves Today
  });
}
