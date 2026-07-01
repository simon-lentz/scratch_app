import 'package:checkplan/features/account/application/auth_providers.dart';
import 'package:checkplan/features/account/presentation/password_reset_screen.dart';
import 'package:checkplan/features/account/presentation/sign_in_screen.dart';
import 'package:checkplan/features/account/presentation/sign_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/a11y.dart';
import '../../../support/fake_auth_service.dart';

Future<void> _pump(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authServiceProvider.overrideWithValue(FakeAuthService())],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Sign in meets tap-target and labelled-tappable guidelines', (
    tester,
  ) async {
    await _pump(tester, const SignInScreen());
    await expectMeetsTapTargetGuidelines(tester);
  });

  testWidgets('Sign up meets tap-target and labelled-tappable guidelines', (
    tester,
  ) async {
    await _pump(tester, const SignUpScreen());
    await expectMeetsTapTargetGuidelines(tester);
  });

  testWidgets('Reset password meets tap-target guidelines', (tester) async {
    await _pump(tester, const PasswordResetScreen());
    await expectMeetsTapTargetGuidelines(tester);
  });
}
