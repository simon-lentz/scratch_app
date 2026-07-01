// coverage:ignore-file
import 'package:checkplan/features/account/application/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// [AuthService] backed by `supabase_flutter` — the one SDK-coupled file.
///
/// Maps the gotrue auth client to the app-owned [AuthSnapshot]/[AuthFailure]
/// types, so no vendor type crosses the seam. The session and PKCE tokens
/// persist in the platform Keychain/Keystore via [FlutterSecureStorage], not in
/// plaintext SharedPreferences. Not unit-tested (it needs a live client);
/// verified by the integration test and on device.
class SupabaseAuthService implements AuthService {
  /// Wraps an already-initialized Supabase client.
  SupabaseAuthService(this._client);

  /// Initializes Supabase (secure-storage session + PKCE) and returns the
  /// service. Call once at startup, only when the config is present.
  static Future<SupabaseAuthService> initialize({
    required String url,
    required String publishableKey,
  }) async {
    const storage = FlutterSecureStorage();
    await Supabase.initialize(
      url: url,
      publishableKey: publishableKey,
      authOptions: FlutterAuthClientOptions(
        localStorage: _SecureLocalStorage(storage),
        pkceAsyncStorage: _SecurePkceStorage(storage),
      ),
    );
    return SupabaseAuthService(Supabase.instance.client);
  }

  final SupabaseClient _client;
  static const _redirect = 'io.checkplan.app://login-callback';

  AuthSnapshot _snapshot(Session? session) {
    final email = session?.user.email;
    return email == null ? const SignedOut() : SignedIn(email);
  }

  @override
  Stream<AuthSnapshot> get authStateChanges async* {
    yield _snapshot(_client.auth.currentSession);
    yield* _client.auth.onAuthStateChange.map((s) => _snapshot(s.session));
  }

  @override
  Future<void> signIn(String email, String password) => _guard(
    () => _client.auth.signInWithPassword(email: email, password: password),
  );

  @override
  Future<void> signUp(String email, String password) => _guard(
    () => _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: _redirect,
    ),
  );

  @override
  Future<void> signOut() => _guard(_client.auth.signOut);

  @override
  Future<void> sendPasswordReset(String email) => _guard(
    () => _client.auth.resetPasswordForEmail(email, redirectTo: _redirect),
  );

  @override
  Future<void> resendConfirmation(String email) =>
      _guard(() => _client.auth.resend(type: OtpType.signup, email: email));

  Future<void> _guard(Future<void> Function() call) async {
    try {
      await call();
    } on AuthException catch (error) {
      throw AuthFailure(error.message);
    }
  }
}

/// A secure-storage-backed [LocalStorage] (the gotrue session store).
class _SecureLocalStorage extends LocalStorage {
  _SecureLocalStorage(this._storage);

  final FlutterSecureStorage _storage;
  static const _key = 'supabase.session';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: _key);

  @override
  Future<String?> accessToken() => _storage.read(key: _key);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _key, value: persistSessionString);
}

/// A secure-storage-backed [GotrueAsyncStorage] (the PKCE verifier store).
class _SecurePkceStorage extends GotrueAsyncStorage {
  _SecurePkceStorage(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> getItem({required String key}) => _storage.read(key: key);

  @override
  Future<void> setItem({required String key, required String value}) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> removeItem({required String key}) => _storage.delete(key: key);
}
