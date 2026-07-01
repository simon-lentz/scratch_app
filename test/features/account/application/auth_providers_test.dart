import 'package:checkplan/core/result.dart';
import 'package:checkplan/features/account/application/auth_providers.dart';
import 'package:checkplan/features/account/application/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/fake_auth_service.dart';

void main() {
  ProviderContainer containerWith(FakeAuthService fake) =>
      ProviderContainer.test(
        overrides: [authServiceProvider.overrideWithValue(fake)],
      );

  test('authState defaults to SignedOut', () async {
    // An active listener keeps the StreamProvider subscribed; Riverpod pauses a
    // listener-less StreamProvider, stranding `.future` in loading.
    final container = containerWith(FakeAuthService())
      ..listen(authStateProvider, (_, _) {});
    expect(await container.read(authStateProvider.future), const SignedOut());
  });

  test('signIn returns Ok and authState reflects it', () async {
    final container = containerWith(FakeAuthService());
    final result = await container
        .read(authControllerProvider.notifier)
        .signIn('a@b.com', 'pw');
    expect(result, isA<Ok<void>>());
    container.listen(authStateProvider, (_, _) {});
    expect(
      await container.read(authStateProvider.future),
      const SignedIn('a@b.com'),
    );
  });

  test('a failing command maps to Err, not an uncaught throw', () async {
    final fake = FakeAuthService()..signInError = const AuthFailure('nope');
    final result = await containerWith(
      fake,
    ).read(authControllerProvider.notifier).signIn('a@b.com', 'pw');
    expect(result, isA<Err<void>>());
  });
}
