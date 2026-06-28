// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'today_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Today's due-task buckets (overdue + due today), recomputed whenever the day
/// rolls over.
///
/// A `StreamProvider` over the task DAO's `watchTodayBuckets`, keyed by
/// [currentDayProvider] so a midnight rollover (or the shell's app-resume
/// invalidation) re-subscribes the stream against the new day.

@ProviderFor(today)
final todayProvider = TodayProvider._();

/// Today's due-task buckets (overdue + due today), recomputed whenever the day
/// rolls over.
///
/// A `StreamProvider` over the task DAO's `watchTodayBuckets`, keyed by
/// [currentDayProvider] so a midnight rollover (or the shell's app-resume
/// invalidation) re-subscribes the stream against the new day.

final class TodayProvider
    extends
        $FunctionalProvider<
          AsyncValue<TodayBuckets>,
          TodayBuckets,
          Stream<TodayBuckets>
        >
    with $FutureModifier<TodayBuckets>, $StreamProvider<TodayBuckets> {
  /// Today's due-task buckets (overdue + due today), recomputed whenever the day
  /// rolls over.
  ///
  /// A `StreamProvider` over the task DAO's `watchTodayBuckets`, keyed by
  /// [currentDayProvider] so a midnight rollover (or the shell's app-resume
  /// invalidation) re-subscribes the stream against the new day.
  TodayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayHash();

  @$internal
  @override
  $StreamProviderElement<TodayBuckets> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<TodayBuckets> create(Ref ref) {
    return today(ref);
  }
}

String _$todayHash() => r'092bab838618ab772f7e3c6261021e3b99acf585';
