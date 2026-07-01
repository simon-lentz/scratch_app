import 'package:checkplan/core/result.dart';
import 'package:checkplan/features/account/application/auth_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

/// The app's [AuthService].
///
/// Defaults to the no-op [SignedOutAuthService] so the app is local-only and
/// network-silent unless `main` injects the Supabase implementation (only when
/// configured) or a test overrides it with a fake.
@Riverpod(keepAlive: true)
AuthService authService(Ref ref) => const SignedOutAuthService();

/// The reactive auth state — the current [AuthSnapshot] and every change.
@Riverpod(keepAlive: true)
Stream<AuthSnapshot> authState(Ref ref) =>
    ref.watch(authServiceProvider).authStateChanges;

/// Write commands for authentication.
///
/// Holds no state of its own. Each command delegates to [authServiceProvider]
/// through `Result.guard`, so a caught [AuthFailure] becomes [Err] and a bug
/// (`Error`) propagates — the same contract as the other write controllers.
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  void build() {}

  AuthService get _service => ref.read(authServiceProvider);

  /// Creates an account for [email]/[password].
  ///
  /// Returns `Ok` even when confirmation is still pending (no session yet — the
  /// caller shows a "check your email" state).
  Future<Result<void>> signUp(String email, String password) =>
      Result.guard(() => _service.signUp(email, password));

  /// Signs in with [email]/[password].
  Future<Result<void>> signIn(String email, String password) =>
      Result.guard(() => _service.signIn(email, password));

  /// Signs the current account out.
  Future<Result<void>> signOut() => Result.guard(_service.signOut);

  /// Sends a password-reset email to [email].
  Future<Result<void>> sendPasswordReset(String email) =>
      Result.guard(() => _service.sendPasswordReset(email));

  /// Re-sends the confirmation email to [email].
  Future<Result<void>> resendConfirmation(String email) =>
      Result.guard(() => _service.resendConfirmation(email));
}
