import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/time/current_day.dart';
import 'package:checkplan/features/tasks/application/task_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'today_providers.g.dart';

/// Today's due-task buckets (overdue + due today), recomputed whenever the day
/// rolls over.
///
/// A `StreamProvider` over the task DAO's `watchTodayBuckets`, keyed by
/// [currentDayProvider] so a midnight rollover (or the shell's app-resume
/// invalidation) re-subscribes the stream against the new day.
@Riverpod(keepAlive: true)
Stream<TodayBuckets> today(Ref ref) {
  final day = ref.watch(currentDayProvider);
  return ref.watch(taskDaoProvider).watchTodayBuckets(day);
}
