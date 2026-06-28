// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The single [AppDatabase] instance for the whole app.
///
/// Declared to throw so it must be provided explicitly: `main` overrides it
/// with `openAppDatabase`'s result, and tests override it with an in-memory
/// database. One shared instance is what makes drift's `.watch()` streams
/// re-emit for every write.

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// The single [AppDatabase] instance for the whole app.
///
/// Declared to throw so it must be provided explicitly: `main` overrides it
/// with `openAppDatabase`'s result, and tests override it with an in-memory
/// database. One shared instance is what makes drift's `.watch()` streams
/// re-emit for every write.

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// The single [AppDatabase] instance for the whole app.
  ///
  /// Declared to throw so it must be provided explicitly: `main` overrides it
  /// with `openAppDatabase`'s result, and tests override it with an in-memory
  /// database. One shared instance is what makes drift's `.watch()` streams
  /// re-emit for every write.
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'7b884142d58689710a9f19182b927e669587e97d';

/// The database-file deletion used by [resetDatabase], injected so tests can
/// override it and touch no real files. Defaults to the platform
/// [reset.deleteAppDatabase] (an unsupported-throwing stub on web, where reset
/// is never offered).

@ProviderFor(deleteAppDatabase)
final deleteAppDatabaseProvider = DeleteAppDatabaseProvider._();

/// The database-file deletion used by [resetDatabase], injected so tests can
/// override it and touch no real files. Defaults to the platform
/// [reset.deleteAppDatabase] (an unsupported-throwing stub on web, where reset
/// is never offered).

final class DeleteAppDatabaseProvider
    extends
        $FunctionalProvider<
          Future<void> Function(),
          Future<void> Function(),
          Future<void> Function()
        >
    with $Provider<Future<void> Function()> {
  /// The database-file deletion used by [resetDatabase], injected so tests can
  /// override it and touch no real files. Defaults to the platform
  /// [reset.deleteAppDatabase] (an unsupported-throwing stub on web, where reset
  /// is never offered).
  DeleteAppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deleteAppDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deleteAppDatabaseHash();

  @$internal
  @override
  $ProviderElement<Future<void> Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<void> Function() create(Ref ref) {
    return deleteAppDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<void> Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Future<void> Function()>(value),
    );
  }
}

String _$deleteAppDatabaseHash() => r'a7bcf8d9ed7dc9d393f6d09fa9e4b3ed201216a3';
