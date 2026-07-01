import 'dart:async';

import 'package:checkplan/features/account/application/auth_providers.dart';
import 'package:checkplan/features/account/application/auth_service.dart';
import 'package:checkplan/features/account/presentation/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import '../../../support/fake_auth_service.dart';

/// Pumps [SignInScreen] as a route pushed over a dummy home, so its
/// success-path `context.pop()` has somewhere to return to.
Future<void> _pump(WidgetTester tester, FakeAuthService fake) async {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (c, s) => const Scaffold()),
      GoRoute(path: '/sign-in', builder: (c, s) => const SignInScreen()),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authServiceProvider.overrideWithValue(fake)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  unawaited(router.push('/sign-in'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a successful sign-in calls signIn and pops back', (
    tester,
  ) async {
    final fake = FakeAuthService();
    await _pump(tester, fake);
    await tester.enterText(find.byKey(const Key('email')), 'a@b.com');
    await tester.enterText(find.byKey(const Key('password')), 'pw');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(fake.calls, contains('signIn:a@b.com'));
    expect(find.byType(SignInScreen), findsNothing); // popped on success
  });

  testWidgets('a failed sign-in stays and shows the message inline', (
    tester,
  ) async {
    final fake = FakeAuthService()
      ..signInError = const AuthFailure('Wrong email or password');
    await _pump(tester, fake);
    await tester.enterText(find.byKey(const Key('email')), 'a@b.com');
    await tester.enterText(find.byKey(const Key('password')), 'bad');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Wrong email or password'), findsOneWidget);
  });
}
