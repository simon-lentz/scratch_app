import 'package:checkplan/app/app.dart';
import 'package:checkplan/features/account/presentation/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/test_overrides.dart';

void main() {
  testWidgets('the Settings account section opens the sign-in screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        // baseTestOverrides pins appDatabaseProvider + currentDayProvider;
        // authServiceProvider defaults to SignedOutAuthService (no override
        // needed), so the account section renders its signed-out arm.
        overrides: baseTestOverrides(),
        child: const CheckPlanApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
  });
}
