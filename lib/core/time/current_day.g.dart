// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_day.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Today's local calendar day as an [EpochDay].
///
/// Derives from [clockProvider] and self-invalidates at the next local
/// midnight: it arms a [Timer] for the midnight boundary and
/// `ref.invalidateSelf`s when it fires, so anything watching it re-derives the
/// moment the day turns. The timer is cancelled in `ref.onDispose`.
///
/// Resume-from-background invalidation is wired separately in the navigation
/// shell, so this provider stays free of the widget binding and is buildable in
/// a plain `ProviderContainer.test`.

@ProviderFor(currentDay)
final currentDayProvider = CurrentDayProvider._();

/// Today's local calendar day as an [EpochDay].
///
/// Derives from [clockProvider] and self-invalidates at the next local
/// midnight: it arms a [Timer] for the midnight boundary and
/// `ref.invalidateSelf`s when it fires, so anything watching it re-derives the
/// moment the day turns. The timer is cancelled in `ref.onDispose`.
///
/// Resume-from-background invalidation is wired separately in the navigation
/// shell, so this provider stays free of the widget binding and is buildable in
/// a plain `ProviderContainer.test`.

final class CurrentDayProvider
    extends $FunctionalProvider<EpochDay, EpochDay, EpochDay>
    with $Provider<EpochDay> {
  /// Today's local calendar day as an [EpochDay].
  ///
  /// Derives from [clockProvider] and self-invalidates at the next local
  /// midnight: it arms a [Timer] for the midnight boundary and
  /// `ref.invalidateSelf`s when it fires, so anything watching it re-derives the
  /// moment the day turns. The timer is cancelled in `ref.onDispose`.
  ///
  /// Resume-from-background invalidation is wired separately in the navigation
  /// shell, so this provider stays free of the widget binding and is buildable in
  /// a plain `ProviderContainer.test`.
  CurrentDayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentDayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentDayHash();

  @$internal
  @override
  $ProviderElement<EpochDay> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EpochDay create(Ref ref) {
    return currentDay(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EpochDay value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EpochDay>(value),
    );
  }
}

String _$currentDayHash() => r'36c53c0727c3c9f1f47e49ceb97d09fda6355475';
