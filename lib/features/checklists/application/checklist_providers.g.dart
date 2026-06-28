// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checklist_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Accessor for the [ChecklistDao], backed by the shared database.

@ProviderFor(checklistDao)
final checklistDaoProvider = ChecklistDaoProvider._();

/// Accessor for the [ChecklistDao], backed by the shared database.

final class ChecklistDaoProvider
    extends $FunctionalProvider<ChecklistDao, ChecklistDao, ChecklistDao>
    with $Provider<ChecklistDao> {
  /// Accessor for the [ChecklistDao], backed by the shared database.
  ChecklistDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checklistDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checklistDaoHash();

  @$internal
  @override
  $ProviderElement<ChecklistDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChecklistDao create(Ref ref) {
    return checklistDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChecklistDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChecklistDao>(value),
    );
  }
}

String _$checklistDaoHash() => r'eb97d89e26e079875dbe24ffec7222dc6414e3c0';

/// Reactive list of non-archived checklists, each with its task progress.
///
/// Re-emits whenever checklists or their tasks change.

@ProviderFor(activeChecklists)
final activeChecklistsProvider = ActiveChecklistsProvider._();

/// Reactive list of non-archived checklists, each with its task progress.
///
/// Re-emits whenever checklists or their tasks change.

final class ActiveChecklistsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ChecklistSummary>>,
          List<ChecklistSummary>,
          Stream<List<ChecklistSummary>>
        >
    with
        $FutureModifier<List<ChecklistSummary>>,
        $StreamProvider<List<ChecklistSummary>> {
  /// Reactive list of non-archived checklists, each with its task progress.
  ///
  /// Re-emits whenever checklists or their tasks change.
  ActiveChecklistsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeChecklistsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeChecklistsHash();

  @$internal
  @override
  $StreamProviderElement<List<ChecklistSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ChecklistSummary>> create(Ref ref) {
    return activeChecklists(ref);
  }
}

String _$activeChecklistsHash() => r'd8046d7a9064f7b643ac59d590816b4a62dab633';

/// Reactive list of archived checklists, most-recently-archived first.
///
/// Backs the archive view; re-emits whenever checklists or their tasks change.

@ProviderFor(archivedChecklists)
final archivedChecklistsProvider = ArchivedChecklistsProvider._();

/// Reactive list of archived checklists, most-recently-archived first.
///
/// Backs the archive view; re-emits whenever checklists or their tasks change.

final class ArchivedChecklistsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ChecklistSummary>>,
          List<ChecklistSummary>,
          Stream<List<ChecklistSummary>>
        >
    with
        $FutureModifier<List<ChecklistSummary>>,
        $StreamProvider<List<ChecklistSummary>> {
  /// Reactive list of archived checklists, most-recently-archived first.
  ///
  /// Backs the archive view; re-emits whenever checklists or their tasks change.
  ArchivedChecklistsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'archivedChecklistsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$archivedChecklistsHash();

  @$internal
  @override
  $StreamProviderElement<List<ChecklistSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ChecklistSummary>> create(Ref ref) {
    return archivedChecklists(ref);
  }
}

String _$archivedChecklistsHash() =>
    r'4dcd285b273dca6cacbcb8a881365cb658abc6b9';

/// Write commands for checklists.
///
/// Holds no state of its own — the database is the state. Each command returns
/// a [Result]: rejected input and caught exceptions become [Err]; programming
/// bugs (`Error`) propagate.

@ProviderFor(ChecklistController)
final checklistControllerProvider = ChecklistControllerProvider._();

/// Write commands for checklists.
///
/// Holds no state of its own — the database is the state. Each command returns
/// a [Result]: rejected input and caught exceptions become [Err]; programming
/// bugs (`Error`) propagate.
final class ChecklistControllerProvider
    extends $NotifierProvider<ChecklistController, void> {
  /// Write commands for checklists.
  ///
  /// Holds no state of its own — the database is the state. Each command returns
  /// a [Result]: rejected input and caught exceptions become [Err]; programming
  /// bugs (`Error`) propagate.
  ChecklistControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checklistControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checklistControllerHash();

  @$internal
  @override
  ChecklistController create() => ChecklistController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$checklistControllerHash() =>
    r'4b09444d08cc0376c34e92ff100d264107183022';

/// Write commands for checklists.
///
/// Holds no state of its own — the database is the state. Each command returns
/// a [Result]: rejected input and caught exceptions become [Err]; programming
/// bugs (`Error`) propagate.

abstract class _$ChecklistController extends $Notifier<void> {
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

/// The active-list summary for one checklist id, or null if it is not in the
/// active list (still loading, or archived).
///
/// Derives from [activeChecklistsProvider] so the detail screen can title its
/// app bar without a separate query. `autoDispose` (the codegen default) for
/// the same reasons as the other detail reads.

@ProviderFor(checklistById)
final checklistByIdProvider = ChecklistByIdFamily._();

/// The active-list summary for one checklist id, or null if it is not in the
/// active list (still loading, or archived).
///
/// Derives from [activeChecklistsProvider] so the detail screen can title its
/// app bar without a separate query. `autoDispose` (the codegen default) for
/// the same reasons as the other detail reads.

final class ChecklistByIdProvider
    extends
        $FunctionalProvider<
          ChecklistSummary?,
          ChecklistSummary?,
          ChecklistSummary?
        >
    with $Provider<ChecklistSummary?> {
  /// The active-list summary for one checklist id, or null if it is not in the
  /// active list (still loading, or archived).
  ///
  /// Derives from [activeChecklistsProvider] so the detail screen can title its
  /// app bar without a separate query. `autoDispose` (the codegen default) for
  /// the same reasons as the other detail reads.
  ChecklistByIdProvider._({
    required ChecklistByIdFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'checklistByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$checklistByIdHash();

  @override
  String toString() {
    return r'checklistByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<ChecklistSummary?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ChecklistSummary? create(Ref ref) {
    final argument = this.argument as int;
    return checklistById(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChecklistSummary? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChecklistSummary?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChecklistByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$checklistByIdHash() => r'65e4817829270bcf4d13d455425a8f97206ce46f';

/// The active-list summary for one checklist id, or null if it is not in the
/// active list (still loading, or archived).
///
/// Derives from [activeChecklistsProvider] so the detail screen can title its
/// app bar without a separate query. `autoDispose` (the codegen default) for
/// the same reasons as the other detail reads.

final class ChecklistByIdFamily extends $Family
    with $FunctionalFamilyOverride<ChecklistSummary?, int> {
  ChecklistByIdFamily._()
    : super(
        retry: null,
        name: r'checklistByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The active-list summary for one checklist id, or null if it is not in the
  /// active list (still loading, or archived).
  ///
  /// Derives from [activeChecklistsProvider] so the detail screen can title its
  /// app bar without a separate query. `autoDispose` (the codegen default) for
  /// the same reasons as the other detail reads.

  ChecklistByIdProvider call(int id) =>
      ChecklistByIdProvider._(argument: id, from: this);

  @override
  String toString() => r'checklistByIdProvider';
}
