import 'dart:async';

import 'package:checkplan/features/account/application/auth_service.dart';

/// An in-memory [AuthService] for tests — no network, no SDK.
///
/// Seed the initial state via `initial`; drive later changes with [emit]. Each
/// command records its call and, if its matching `…Error` field is set, throws
/// it (to exercise the `Err` path); otherwise it succeeds and — for
/// [signIn]/[signOut] — emits the corresponding snapshot so a watching widget
/// updates.
class FakeAuthService implements AuthService {
  /// Starts in `initial` (default signed-out).
  FakeAuthService({AuthSnapshot initial = const SignedOut()})
    : _current = initial;

  final _controller = StreamController<AuthSnapshot>.broadcast();
  AuthSnapshot _current;

  /// When set, [signIn] throws it (exercises the failure path).
  AuthFailure? signInError;

  /// When set, [signUp] throws it.
  AuthFailure? signUpError;

  /// When set, [sendPasswordReset] throws it.
  AuthFailure? resetError;

  /// When set, [resendConfirmation] throws it.
  AuthFailure? resendError;

  /// The commands invoked, in order, for assertions (e.g. `signIn:a@b.com`).
  final calls = <String>[];

  /// Pushes a new state to listeners (e.g. confirmation completing).
  void emit(AuthSnapshot snapshot) {
    _current = snapshot;
    _controller.add(snapshot);
  }

  @override
  Stream<AuthSnapshot> get authStateChanges async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<void> signUp(String email, String password) async {
    calls.add('signUp:$email');
    if (signUpError case final error?) throw error;
  }

  @override
  Future<void> signIn(String email, String password) async {
    calls.add('signIn:$email');
    if (signInError case final error?) throw error;
    emit(SignedIn(email));
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    emit(const SignedOut());
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    calls.add('reset:$email');
    if (resetError case final error?) throw error;
  }

  @override
  Future<void> resendConfirmation(String email) async {
    calls.add('resend:$email');
    if (resendError case final error?) throw error;
  }
}
