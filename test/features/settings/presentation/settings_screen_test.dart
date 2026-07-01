import 'package:checkplan/core/result.dart';
import 'package:checkplan/features/settings/application/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/pump_settings_screen.dart';

/// A controller whose `setThemeMode` fails, to drive the error feedback.
class _FailingSettingsController extends SettingsController {
  @override
  Future<Result<void>> setThemeMode(ThemeMode mode) async =>
      Err(Exception('boom'));
}

void main() {
  testWidgets('shows the three theme options', (tester) async {
    await pumpSettingsScreen(tester);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('selecting Dark persists it', (tester) async {
    await pumpSettingsScreen(tester);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    final selected = tester
        .widget<SegmentedButton<ThemeMode>>(
          find.byType(SegmentedButton<ThemeMode>),
        )
        .selected;
    expect(selected, {ThemeMode.dark});
  });

  testWidgets('a write failure shows an error', (tester) async {
    await pumpSettingsScreen(
      tester,
      overrides: [
        settingsControllerProvider.overrideWith(_FailingSettingsController.new),
      ],
    );
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(find.text('Could not update the theme'), findsOneWidget);
  });
}
