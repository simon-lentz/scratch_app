import 'dart:io' show Platform;

import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/time/current_day.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:checkplan/features/today/application/today_providers.dart';
import 'package:checkplan/features/today/presentation/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _instant = DateTime.utc(2026);
final _today = EpochDay.fromDateTime(DateTime(2026, 6, 25));

Task _task(int id, String title, int dueDay) => Task(
  id: id,
  checklistId: 1,
  title: title,
  isDone: false,
  dueDay: dueDay,
  position: id,
  createdAt: _instant,
  updatedAt: _instant,
);

void main() {
  // Goldens are baselined on Linux (CI); this test skips off Linux, so a macOS
  // `flutter test` stays green and `--update-goldens` writes no baseline on the
  // wrong platform.
  testWidgets('Today — overdue and due-today sections', (tester) async {
    final buckets = TodayBuckets(
      overdue: [
        TodayTask(
          task: _task(1, 'Milk', _today.value - 1),
          checklistTitle: 'Groceries',
        ),
      ],
      dueToday: [
        TodayTask(
          task: _task(2, 'Bread', _today.value),
          checklistTitle: 'Groceries',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentDayProvider.overrideWithValue(_today),
          todayProvider.overrideWith((ref) => Stream.value(buckets)),
        ],
        child: const MaterialApp(home: TodayScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(TodayScreen),
      matchesGoldenFile('goldens/today_sections.png'),
    );
  }, skip: !Platform.isLinux);
}
