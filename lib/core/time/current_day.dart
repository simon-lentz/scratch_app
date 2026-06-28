import 'dart:async';

import 'package:checkplan/core/time/clock.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'current_day.g.dart';

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
@Riverpod(keepAlive: true)
EpochDay currentDay(Ref ref) {
  final now = ref.watch(clockProvider)();
  // DateTime(...) is local; day + 1 normalises across month/year boundaries.
  final nextMidnight = DateTime(now.year, now.month, now.day + 1);
  final timer = Timer(nextMidnight.difference(now), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return EpochDay.fromDateTime(now);
}
