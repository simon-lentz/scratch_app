// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subtask_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Accessor for the [SubtaskDao], backed by the shared database.

@ProviderFor(subtaskDao)
final subtaskDaoProvider = SubtaskDaoProvider._();

/// Accessor for the [SubtaskDao], backed by the shared database.

final class SubtaskDaoProvider
    extends $FunctionalProvider<SubtaskDao, SubtaskDao, SubtaskDao>
    with $Provider<SubtaskDao> {
  /// Accessor for the [SubtaskDao], backed by the shared database.
  SubtaskDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subtaskDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subtaskDaoHash();

  @$internal
  @override
  $ProviderElement<SubtaskDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SubtaskDao create(Ref ref) {
    return subtaskDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubtaskDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubtaskDao>(value),
    );
  }
}

String _$subtaskDaoHash() => r'c5207dc3ab0e1a581a4afdb9449d1a1dd94026a0';

/// Write commands for subtasks (add / toggle / delete).
///
/// Holds no state of its own, the database is the state. Each command returns
/// a [Result].

@ProviderFor(SubtaskController)
final subtaskControllerProvider = SubtaskControllerProvider._();

/// Write commands for subtasks (add / toggle / delete).
///
/// Holds no state of its own, the database is the state. Each command returns
/// a [Result].
final class SubtaskControllerProvider
    extends $NotifierProvider<SubtaskController, void> {
  /// Write commands for subtasks (add / toggle / delete).
  ///
  /// Holds no state of its own, the database is the state. Each command returns
  /// a [Result].
  SubtaskControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subtaskControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subtaskControllerHash();

  @$internal
  @override
  SubtaskController create() => SubtaskController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$subtaskControllerHash() => r'e472c6bab1965838199e6dee869c8c61b1e7760d';

/// Write commands for subtasks (add / toggle / delete).
///
/// Holds no state of its own, the database is the state. Each command returns
/// a [Result].

abstract class _$SubtaskController extends $Notifier<void> {
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
