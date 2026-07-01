// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's [AuthService].
///
/// Defaults to the no-op [SignedOutAuthService] so the app is local-only and
/// network-silent unless `main` injects the Supabase implementation (only when
/// configured) or a test overrides it with a fake.

@ProviderFor(authService)
final authServiceProvider = AuthServiceProvider._();

/// The app's [AuthService].
///
/// Defaults to the no-op [SignedOutAuthService] so the app is local-only and
/// network-silent unless `main` injects the Supabase implementation (only when
/// configured) or a test overrides it with a fake.

final class AuthServiceProvider
    extends $FunctionalProvider<AuthService, AuthService, AuthService>
    with $Provider<AuthService> {
  /// The app's [AuthService].
  ///
  /// Defaults to the no-op [SignedOutAuthService] so the app is local-only and
  /// network-silent unless `main` injects the Supabase implementation (only when
  /// configured) or a test overrides it with a fake.
  AuthServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authServiceHash();

  @$internal
  @override
  $ProviderElement<AuthService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthService create(Ref ref) {
    return authService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthService>(value),
    );
  }
}

String _$authServiceHash() => r'01bd3e9c993ad13ea4543ed7db80a7c1a62bc80e';

/// The reactive auth state — the current [AuthSnapshot] and every change.

@ProviderFor(authState)
final authStateProvider = AuthStateProvider._();

/// The reactive auth state — the current [AuthSnapshot] and every change.

final class AuthStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<AuthSnapshot>,
          AuthSnapshot,
          Stream<AuthSnapshot>
        >
    with $FutureModifier<AuthSnapshot>, $StreamProvider<AuthSnapshot> {
  /// The reactive auth state — the current [AuthSnapshot] and every change.
  AuthStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateHash();

  @$internal
  @override
  $StreamProviderElement<AuthSnapshot> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<AuthSnapshot> create(Ref ref) {
    return authState(ref);
  }
}

String _$authStateHash() => r'863e1dc0d30ee9ca72c5ca62ca29593638a5ff3c';

/// Write commands for authentication.
///
/// Holds no state of its own. Each command delegates to [authServiceProvider]
/// through `Result.guard`, so a caught [AuthFailure] becomes [Err] and a bug
/// (`Error`) propagates — the same contract as the other write controllers.

@ProviderFor(AuthController)
final authControllerProvider = AuthControllerProvider._();

/// Write commands for authentication.
///
/// Holds no state of its own. Each command delegates to [authServiceProvider]
/// through `Result.guard`, so a caught [AuthFailure] becomes [Err] and a bug
/// (`Error`) propagates — the same contract as the other write controllers.
final class AuthControllerProvider
    extends $NotifierProvider<AuthController, void> {
  /// Write commands for authentication.
  ///
  /// Holds no state of its own. Each command delegates to [authServiceProvider]
  /// through `Result.guard`, so a caught [AuthFailure] becomes [Err] and a bug
  /// (`Error`) propagates — the same contract as the other write controllers.
  AuthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authControllerHash();

  @$internal
  @override
  AuthController create() => AuthController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$authControllerHash() => r'673f54f8b31cd16b654508799fe7b58930e456f1';

/// Write commands for authentication.
///
/// Holds no state of its own. Each command delegates to [authServiceProvider]
/// through `Result.guard`, so a caught [AuthFailure] becomes [Err] and a bug
/// (`Error`) propagates — the same contract as the other write controllers.

abstract class _$AuthController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
