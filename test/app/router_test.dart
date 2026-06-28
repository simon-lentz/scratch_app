import 'package:checkplan/app/app.dart';
import 'package:checkplan/app/router.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/core/time/clock.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/memory_db.dart';
import '../support/test_overrides.dart';

void main() {
  final today = EpochDay.fromDateTime(DateTime(2026, 6, 18));

  Future<void> pumpRouterApp(
    WidgetTester tester,
    String initialLocation,
  ) async {
    final router = createAppRouter(initialLocation: initialLocation);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: baseTestOverrides(today: today),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the bottom nav switches between Lists and Today', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: baseTestOverrides(today: today),
        child: const CheckPlanApp(),
      ),
    );
    await tester.pumpAndSettle();

    NavigationBar navBar() =>
        tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar().selectedIndex, 0);
    expect(find.widgetWithText(AppBar, 'Checklist Planner'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.today));
    await tester.pumpAndSettle();

    expect(navBar().selectedIndex, 1);
    expect(find.widgetWithText(AppBar, 'Today'), findsOneWidget);
  });

  testWidgets('initialLocation deep-links the Today branch', (tester) async {
    await pumpRouterApp(tester, '/today');

    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    expect(find.widgetWithText(AppBar, 'Today'), findsOneWidget);
  });

  testWidgets('a malformed checklist id shows the not-found screen', (
    tester,
  ) async {
    await pumpRouterApp(tester, '/checklist/abc');

    expect(find.text('That checklist does not exist'), findsOneWidget);
  });

  testWidgets('resuming re-derives the current day so Today rolls over', (
    tester,
  ) async {
    final db = memoryDb();
    final list = await db.checklistDao.create('L');
    final id = await db.taskDao.add(list, 'Tomorrow task');
    await db.taskDao.setDueDate(
      id,
      EpochDay.fromDateTime(DateTime(2026, 6, 19)),
    );

    // Morning times keep the midnight timer ~15h away, so it never fires during
    // pumpAndSettle; only the explicit resume re-derives the day.
    var now = DateTime(2026, 6, 18, 9);
    final router = createAppRouter(initialLocation: '/today');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => db),
          clockProvider.overrideWith(
            (ref) =>
                () => now,
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tomorrow task'), findsNothing); // upcoming on the 18th

    now = DateTime(2026, 6, 19, 9);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Tomorrow task'), findsOneWidget); // due today on the 19th

    // Dispose the tree so currentDayProvider cancels its midnight timer.
    await tester.pumpWidget(const SizedBox());
  });
}
