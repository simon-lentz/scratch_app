import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/result.dart';
import 'package:checkplan/features/checklists/application/checklist_providers.dart';
import 'package:checkplan/features/checklists/presentation/widgets/checklist_name_dialog.dart';
import 'package:checkplan/features/checklists/presentation/widgets/checklist_tile.dart';
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
      floatingActionButton: switch (checklistsAsync) {
        AsyncData() => FloatingActionButton(
          onPressed: () => _createChecklist(context, ref),
          child: const Icon(Icons.add),
        ),
        _ => null,
      },
    );
  }
}

Future<void> _createChecklist(BuildContext context, WidgetRef ref) async {
  final title = await showChecklistNameDialog(context);
  if (title == null) return;
  final result = await ref
      .read(checklistControllerProvider.notifier)
      .create(title);
  if (!context.mounted) return;
  if (result case Err()) {
    _showError(context, 'Could not create the checklist');
  }
}

/// Shows a transient error [message] over the current scaffold.
void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// The non-empty list of checklist summaries.
class _ChecklistList extends ConsumerWidget {
  const _ChecklistList({required this.summaries});

  final List<ChecklistSummary> summaries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReorderableListView.builder(
      itemCount: summaries.length,
      onReorderItem: (oldIndex, newIndex) =>
          _reorder(context, ref, oldIndex, newIndex),
      itemBuilder: (context, index) {
        final summary = summaries[index];
        return ChecklistTile(
          key: ValueKey(summary.checklist.id),
          summary: summary,
          onRename: () => _rename(context, ref, summary),
          onRecolour: () => _recolour(context, ref, summary.checklist.id),
          onArchive: () => _archive(context, ref, summary),
          onDelete: () => _delete(context, ref, summary),
        );
      },
    );
  }

  Future<void> _reorder(
    BuildContext context,
    WidgetRef ref,
    int oldIndex,
    int newIndex,
  ) async {
    // onReorderItem already adjusts newIndex for the item removed at oldIndex,
    // so insert at newIndex directly (the deprecated onReorder required a
    // manual `newIndex > oldIndex ? newIndex - 1` shift).
    final ids = summaries.map((s) => s.checklist.id).toList();
    final moved = ids.removeAt(oldIndex);
    ids.insert(newIndex, moved);
    final result = await ref
        .read(checklistControllerProvider.notifier)
        .reorder(ids);
    if (!context.mounted) return;
    if (result case Err()) {
      _showError(context, 'Could not reorder the checklists');
    }
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    ChecklistSummary summary,
  ) async {
    final title = await showChecklistNameDialog(
      context,
      initialTitle: summary.checklist.title,
    );
    if (title == null) return;
    final result = await ref
        .read(checklistControllerProvider.notifier)
        .rename(summary.checklist.id, title);
    if (!context.mounted) return;
    if (result case Err()) {
      _showError(context, 'Could not rename the checklist');
    }
  }

  Future<void> _recolour(BuildContext context, WidgetRef ref, int id) async {
    final choice = await showRecolourDialog(context);
    if (choice == null || !context.mounted) return; // dismissed (no-op)
    final result = await ref
        .read(checklistControllerProvider.notifier)
        .setColor(id, choice.color?.toARGB32());
    if (!context.mounted) return;
    if (result case Err()) {
      _showError(context, 'Could not update the colour');
    }
  }

  Future<void> _archive(
    BuildContext context,
    WidgetRef ref,
    ChecklistSummary summary,
  ) async {
    final controller = ref.read(checklistControllerProvider.notifier);
    final result = await controller.archive(summary.checklist.id);
    if (!context.mounted) return;
    if (result case Err()) {
      _showError(context, 'Could not archive the checklist');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Archived "${summary.checklist.title}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            final restoreResult = await controller.restore(
              summary.checklist.id,
            );
            if (!context.mounted) return;
            if (restoreResult case Err()) {
              _showError(context, 'Could not restore the checklist');
            }
          },
        ),
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ChecklistSummary summary,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${summary.checklist.title}"?'),
        content: const Text(
          'This also deletes its tasks. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final result = await ref
        .read(checklistControllerProvider.notifier)
        .delete(summary.checklist.id);
    if (!context.mounted) return;
    if (result case Err()) {
      _showError(context, 'Could not delete the checklist');
    }
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
