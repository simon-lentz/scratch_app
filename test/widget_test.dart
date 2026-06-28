import 'package:checkplan/app/app.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/memory_db.dart';

void main() {
  testWidgets('CheckPlanApp launches on the empty Lists screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) => memoryDb()),
        ],
        child: const CheckPlanApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(AppBar, 'Lists'),
      findsOneWidget,
    ); // app-bar title
    expect(find.text('No checklists yet'), findsOneWidget); // empty state
  });

  testWidgets('each CheckPlanApp instance owns a distinct router', (
    tester,
  ) async {
    final db = memoryDb();
    Widget app() => ProviderScope(
      overrides: [appDatabaseProvider.overrideWith((ref) => db)],
      child: const CheckPlanApp(),
    );
    RouterConfig<Object>? routerOf() =>
        tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig;

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    final first = routerOf();

    // Replacing the tree disposes the first app (and its router); a fresh mount
    // must build its own router rather than reuse a shared global instance.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    final second = routerOf();

    expect(first, isNotNull);
    expect(identical(first, second), isFalse);
  });
}
