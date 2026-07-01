import 'package:checkplan/core/result.dart';
import 'package:checkplan/features/account/application/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthSnapshot', () {
    test('value equality by state and email', () {
      expect(const SignedOut(), const SignedOut());
      expect(const SignedIn('a@b.com'), const SignedIn('a@b.com'));
      expect(const SignedIn('a@b.com'), isNot(const SignedIn('c@d.com')));
      expect(const SignedIn('a@b.com'), isNot(const SignedOut()));
    });
  });

  group('SignedOutAuthService', () {
    test('emits SignedOut and nothing else', () async {
      const service = SignedOutAuthService();
      expect(await service.authStateChanges.first, const SignedOut());
    });

    test('network commands throw; signOut is a no-op', () async {
      const service = SignedOutAuthService();
      // The command surfaces the failure as a thrown AuthFailure…
      await expectLater(
        service.signUp('a@b.com', 'pw'),
        throwsA(isA<AuthFailure>()),
      );
      // …which Result.guard maps to Err, never an uncaught throw.
      expect(
        await Result.guard(() => service.signIn('a@b.com', 'pw')),
        isA<Err<void>>(),
      );
      // Signing out with no session is a harmless no-op.
      await expectLater(service.signOut(), completes);
    });
  });
}
