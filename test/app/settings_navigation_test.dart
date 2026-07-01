import 'package:checkplan/app/app.dart';
import 'package:checkplan/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/test_overrides.dart';

void main() {
  testWidgets('the Lists app bar opens Settings', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        // Timer-safe by construction: baseTestOverrides pins both
        // appDatabaseProvider (a fresh in-memory DB) and currentDayProvider.
        overrides: baseTestOverrides(),
        child: const CheckPlanApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
  });
}
