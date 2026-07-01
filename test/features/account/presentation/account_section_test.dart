import 'package:checkplan/features/account/application/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/fake_auth_service.dart';
import '../../../support/pump_account_section.dart';

void main() {
  testWidgets('signed out: shows the not-backed-up message + Sign in', (
    tester,
  ) async {
    await pumpAccountSection(tester);
    expect(find.textContaining('Not backed up'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
  });

  testWidgets('signed in: shows the email + Sign out', (tester) async {
    await pumpAccountSection(
      tester,
      fake: FakeAuthService(initial: const SignedIn('a@b.com')),
    );
    expect(find.text('a@b.com'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Sign out'), findsOneWidget);
  });

  testWidgets('Sign out calls the controller and returns to signed-out', (
    tester,
  ) async {
    final fake = FakeAuthService(initial: const SignedIn('a@b.com'));
    await pumpAccountSection(tester, fake: fake);
    await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
    await tester.pumpAndSettle();
    expect(fake.calls, contains('signOut'));
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
  });
}
