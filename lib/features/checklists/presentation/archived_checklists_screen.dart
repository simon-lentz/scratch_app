import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/result.dart';
import 'package:checkplan/core/widgets/async_switcher.dart';
import 'package:checkplan/core/widgets/confirm_delete_dialog.dart';
import 'package:checkplan/core/widgets/empty_view.dart';
import 'package:checkplan/core/widgets/error_snackbar.dart';
import 'package:checkplan/features/checklists/application/checklist_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The archive view: a live, reactive list of archived checklists, each of
/// which can be restored to the active list or permanently deleted.
///
/// Pushed under the Lists branch, so it keeps the bottom nav bar and its
/// app-bar back button returns to Lists.
class ArchivedChecklistsScreen extends ConsumerWidget {
  /// Creates the archive view.
  const ArchivedChecklistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivedAsync = ref.watch(archivedChecklistsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Archived')),
      body: AsyncSwitcher(
        value: archivedAsync,
        isEmpty: (summaries) => summaries.isEmpty,
        empty: const EmptyView(
          message: 'Nothing archived',
          icon: Icons.archive_outlined,
        ),
        data: (summaries) => _ArchivedList(summaries: summaries),
      ),
    );
  }
}

/// The non-empty list of archived checklist summaries.
class _ArchivedList extends ConsumerWidget {
  const _ArchivedList({required this.summaries});

  final List<ChecklistSummary> summaries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      itemCount: summaries.length,
      // The row handlers close over this build context (not the per-row builder
      // context), so a row that unmounts when its checklist leaves the archived
      // stream can't suppress its error snackbar. Hence the wildcard parameter.
      itemBuilder: (_, index) {
        final summary = summaries[index];
        final (done, total) = summary.progress;
        final colorValue = summary.checklist.colorValue;
        return ListTile(
          key: ValueKey(summary.checklist.id),
          leading: CircleAvatar(
            backgroundColor: colorValue == null ? null : Color(colorValue),
          ),
          title: Text(summary.checklist.title),
          subtitle: Text(total == 0 ? 'No tasks' : '$done/$total'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.unarchive_outlined),
                tooltip: 'Restore',
                onPressed: () => _restore(context, ref, summary.checklist.id),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete',
                onPressed: () => _delete(context, ref, summary),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _restore(BuildContext context, WidgetRef ref, int id) async {
    final result = await ref
        .read(checklistControllerProvider.notifier)
        .restore(id);
    if (!context.mounted) return;
    if (result case Err()) {
      showErrorSnackBar(context, 'Could not restore the checklist');
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ChecklistSummary summary,
  ) async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Delete "${summary.checklist.title}"?',
      message: 'This also deletes its tasks. This cannot be undone.',
    );
    if (!confirmed || !context.mounted) return;
    final result = await ref
        .read(checklistControllerProvider.notifier)
        .delete(summary.checklist.id);
    if (!context.mounted) return;
    if (result case Err()) {
      showErrorSnackBar(context, 'Could not delete the checklist');
    }
  }
}
