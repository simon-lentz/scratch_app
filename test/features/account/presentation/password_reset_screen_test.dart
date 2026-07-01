import 'package:checkplan/features/account/application/auth_providers.dart';
import 'package:checkplan/features/account/application/auth_service.dart';
import 'package:checkplan/features/account/presentation/password_reset_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/fake_auth_service.dart';

Future<void> _pump(WidgetTester tester, FakeAuthService fake) =>
    tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(fake)],
        child: const MaterialApp(home: PasswordResetScreen()),
      ),
    );

void main() {
  testWidgets('submitting reveals the confirmation copy', (tester) async {
    final fake = FakeAuthService();
    await _pump(tester, fake);
    await tester.enterText(find.byKey(const Key('email')), 'a@b.com');
    await tester.tap(find.widgetWithText(FilledButton, 'Send reset link'));
    await tester.pumpAndSettle();
    expect(fake.calls, contains('reset:a@b.com'));
    expect(find.textContaining('reset link is on the way'), findsOneWidget);
  });

  testWidgets('a failed request shows the message inline', (tester) async {
    final fake = FakeAuthService()..resetError = const AuthFailure('Bad email');
    await _pump(tester, fake);
    await tester.enterText(find.byKey(const Key('email')), 'bad');
    await tester.tap(find.widgetWithText(FilledButton, 'Send reset link'));
    await tester.pumpAndSettle();
    expect(find.text('Bad email'), findsOneWidget);
  });
}
