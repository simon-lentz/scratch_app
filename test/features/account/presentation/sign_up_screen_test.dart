import 'package:checkplan/features/account/application/auth_providers.dart';
import 'package:checkplan/features/account/application/auth_service.dart';
import 'package:checkplan/features/account/presentation/sign_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/fake_auth_service.dart';

Future<void> _pump(WidgetTester tester, FakeAuthService fake) =>
    tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(fake)],
        child: const MaterialApp(home: SignUpScreen()),
      ),
    );

void main() {
  testWidgets('submitting reveals the check-your-email state', (tester) async {
    final fake = FakeAuthService();
    await _pump(tester, fake);
    await tester.enterText(find.byKey(const Key('email')), 'a@b.com');
    await tester.enterText(find.byKey(const Key('password')), 'pw12345');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(fake.calls, contains('signUp:a@b.com'));
    expect(find.textContaining('Check your email'), findsOneWidget);
  });

  testWidgets('a failed sign-up shows the message inline', (tester) async {
    final fake = FakeAuthService()
      ..signUpError = const AuthFailure('Email already registered');
    await _pump(tester, fake);
    await tester.enterText(find.byKey(const Key('email')), 'a@b.com');
    await tester.enterText(find.byKey(const Key('password')), 'pw12345');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Email already registered'), findsOneWidget);
  });

  testWidgets('resend re-sends the confirmation email', (tester) async {
    final fake = FakeAuthService();
    await _pump(tester, fake);
    await tester.enterText(find.byKey(const Key('email')), 'a@b.com');
    await tester.enterText(find.byKey(const Key('password')), 'pw12345');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(TextButton, 'Resend confirmation email'),
    );
    await tester.pumpAndSettle();
    expect(fake.calls, contains('resend:a@b.com'));
  });
}
