import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/features/checklists/application/checklist_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The "Lists" home screen: a live, reactive list of the user's checklists.
class ChecklistsScreen extends ConsumerWidget {
  /// Creates the Lists screen.
  const ChecklistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checklistsAsync = ref.watch(activeChecklistsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Lists')),
      body: switch (checklistsAsync) {
        AsyncData(:final value) when value.isEmpty => const _EmptyChecklists(),
        AsyncData(:final value) => _ChecklistList(summaries: value),
        AsyncError(:final error) => _ErrorView(error: error),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

/// The non-empty list of checklist summaries.
class _ChecklistList extends StatelessWidget {
  const _ChecklistList({required this.summaries});

  final List<ChecklistSummary> summaries;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: summaries.length,
      itemBuilder: (context, index) {
        final summary = summaries[index];
        final (done, total) = summary.progress;
        return ListTile(
          title: Text(summary.checklist.title),
          subtitle: Text(total == 0 ? 'No tasks' : '$done/$total'),
        );
      },
    );
  }
}

/// Shown when there are no active checklists.
class _EmptyChecklists extends StatelessWidget {
  const _EmptyChecklists();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('No checklists yet'));
  }
}

/// Shown when the checklists stream emits an error.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Something went wrong:\n$error'));
  }
}
