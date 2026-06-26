import 'dart:async';

import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:checkplan/features/today/application/today_providers.dart';
import 'package:checkplan/features/today/presentation/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';
import '../../../support/seed_reads.dart';
import '../../../support/test_overrides.dart';

void main() {
  testWidgets('keeps the loaded list visible while Today reloads', (
    tester,
  ) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('Errands');
    final id = await db.taskDao.add(list, 'Pay rent');
    await db.taskDao.setDueDate(
      id,
      EpochDay.fromDateTime(DateTime(2026, 6, 17)),
    );
    final task = await db.readSingleTask();

    // A broadcast controller stands in for the buckets stream so the reload can
    // re-subscribe — a single-subscription stream can't be listened to twice.
    final controller = StreamController<TodayBuckets>.broadcast();
    addTearDown(controller.close);
    final buckets = TodayBuckets(
      overdue: [TodayTask(task: task, checklistTitle: 'Errands')],
      dueToday: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...baseTestOverrides(
            db: db,
            today: EpochDay.fromDateTime(DateTime(2026, 6, 18)),
          ),
          todayProvider.overrideWith((ref) => controller.stream),
        ],
        child: const MaterialApp(home: TodayScreen()),
      ),
    );
    controller.add(buckets);
    await tester.pumpAndSettle();
    expect(find.text('Pay rent'), findsOneWidget);

    // Invalidating todayProvider is what a midnight rollover (and the shell's
    // app-resume) does: the stream re-subscribes and the provider sits in
    // AsyncLoading, but carries the previous value. The list must stay put
    // rather than blank back to a spinner.
    ProviderScope.containerOf(
      tester.element(find.byType(TodayScreen)),
      listen: false,
    ).invalidate(todayProvider);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Pay rent'), findsOneWidget);
  });
}
