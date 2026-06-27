import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/model/due_status.dart';
import 'package:checkplan/core/time/current_day.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:checkplan/core/widgets/empty_view.dart';
import 'package:checkplan/core/widgets/stream_error_view.dart';
import 'package:checkplan/features/tasks/presentation/task_actions.dart';
import 'package:checkplan/features/today/application/today_providers.dart';
import 'package:checkplan/features/today/presentation/widgets/today_task_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The "Today" screen: a live list of incomplete tasks due today or overdue,
/// grouped into Overdue and Today sections.
class TodayScreen extends ConsumerWidget {
  /// Creates the Today screen.
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayProvider);
    final today = ref.watch(currentDayProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
      body: switch (todayAsync) {
        AsyncError(:final error) => StreamErrorView(
          error: error,
          onRetry: () => ref.invalidate(appDatabaseProvider),
        ),
        AsyncValue(:final value?)
            when value.overdue.isEmpty && value.dueToday.isEmpty =>
          const EmptyView(
            message: 'Nothing due — nice.',
            icon: Icons.event_available,
          ),
        AsyncValue(:final value?) => _TodayList(buckets: value, today: today),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// The non-empty Today list: an Overdue section, then a Today section.
class _TodayList extends ConsumerWidget {
  const _TodayList({required this.buckets, required this.today});

  final TodayBuckets buckets;
  final EpochDay today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      children: [
        if (buckets.overdue.isNotEmpty) const _SectionHeader('Overdue'),
        for (final entry in buckets.overdue)
          _tile(context, ref, entry, dueStatusFor(entry.task.dueDay, today)),
        if (buckets.dueToday.isNotEmpty) const _SectionHeader('Today'),
        // No per-row chip under "Today": the section header already says these
        // are due today, so the chip would only repeat it.
        for (final entry in buckets.dueToday) _tile(context, ref, entry, null),
      ],
    );
  }

  Widget _tile(
    BuildContext context,
    WidgetRef ref,
    TodayTask entry,
    DueStatus? status,
  ) => TodayTaskTile(
    key: ValueKey(entry.task.id),
    entry: entry,
    status: status,
    onToggleDone: (isDone) =>
        toggleTaskDone(context, ref, entry.task.id, isDone: isDone),
  );
}

/// A section label above a group of Today rows.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(label, style: Theme.of(context).textTheme.titleSmall),
  );
}
