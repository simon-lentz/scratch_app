import 'package:flutter/foundation.dart';

/// The app-facing authentication state — the only auth shape the UI and
/// providers see.
///
/// Deliberately narrow: the vendor `Session`/`User` types never cross this seam
/// (they live behind [AuthService]'s Supabase implementation).
@immutable
sealed class AuthSnapshot {
  /// Const base constructor for the sealed hierarchy.
  const AuthSnapshot();
}

/// No account is signed in — the local-only, network-silent mode.
final class SignedOut extends AuthSnapshot {
  /// Const so callers can default to `const SignedOut()`.
  const SignedOut();

  @override
  bool operator ==(Object other) => other is SignedOut;

  @override
  int get hashCode => (SignedOut).hashCode;
}

/// An account is signed in, identified by its [email].
final class SignedIn extends AuthSnapshot {
  /// Wraps the signed-in account's [email].
  const SignedIn(this.email);

  /// The signed-in account's email address.
  final String email;

  @override
  bool operator ==(Object other) => other is SignedIn && other.email == email;

  @override
  int get hashCode => email.hashCode;
}

/// A recoverable authentication failure carrying a **user-safe** [message].
///
/// The Supabase implementation translates the SDK's error type into this, so no
/// vendor exception leaks past the seam. A domain `Exception` (not `Error`), so
/// `Result.guard` maps it to `Err`.
class AuthFailure implements Exception {
  /// Wraps a user-safe [message].
  const AuthFailure(this.message);

  /// A message safe to render inline to the user.
  final String message;

  @override
  String toString() => 'AuthFailure: $message';
}

/// The authentication boundary: a reactive state stream plus fallible commands.
///
/// Every command throws [AuthFailure] on a recoverable failure (wrong password,
/// taken email, offline, …); callers wrap them in `Result.guard`. The one
/// production implementation wraps `supabase_flutter`; tests use a fake.
abstract interface class AuthService {
  /// Emits the current [AuthSnapshot], then every later change.
  Stream<AuthSnapshot> get authStateChanges;

  /// Creates an account for [email]/[password].
  ///
  /// With email confirmation on this completes without minting a session (the
  /// caller shows a “check your email” state).
  Future<void> signUp(String email, String password);

  /// Signs in with [email]/[password]; on success the stream emits [SignedIn].
  Future<void> signIn(String email, String password);

  /// Signs out; the stream emits [SignedOut].
  Future<void> signOut();

  /// Sends a password-reset email to [email].
  Future<void> sendPasswordReset(String email);

  /// Re-sends the confirmation email to a not-yet-confirmed [email].
  Future<void> resendConfirmation(String email);
}

/// The default [AuthService]: no account, no network — the permanent local-only
/// mode.
///
/// `main` swaps in the Supabase implementation only when configured, so an
/// unconfigured build (or one where the user never signs in) makes zero calls.
class SignedOutAuthService implements AuthService {
  /// Const so it can be the provider default.
  const SignedOutAuthService();

  static const _unavailable = AuthFailure(
    'Cloud backup is not available in this build.',
  );

  @override
  Stream<AuthSnapshot> get authStateChanges =>
      Stream<AuthSnapshot>.value(const SignedOut());

  @override
  Future<void> signUp(String email, String password) async =>
      throw _unavailable;

  @override
  Future<void> signIn(String email, String password) async =>
      throw _unavailable;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordReset(String email) async => throw _unavailable;

  @override
  Future<void> resendConfirmation(String email) async => throw _unavailable;
}
