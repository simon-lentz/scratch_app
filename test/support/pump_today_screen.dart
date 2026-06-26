import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:checkplan/features/today/presentation/today_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_overrides.dart';

/// Pumps [TodayScreen] inside a `ProviderScope` + `MaterialApp`, then settles.
///
/// Backs it with a fresh in-memory database unless [db] is supplied (pass a
/// pre-seeded database to render due tasks) and pins `currentDayProvider` to
/// [today] (a default when omitted) via [baseTestOverrides], so the screen
/// never arms the real midnight `Timer`. Extra [overrides] layer on top.
Future<void> pumpTodayScreen(
  WidgetTester tester, {
  AppDatabase? db,
  EpochDay? today,
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...baseTestOverrides(db: db, today: today),
        ...overrides,
      ],
      child: const MaterialApp(home: TodayScreen()),
    ),
  );
  await tester.pumpAndSettle();
}
