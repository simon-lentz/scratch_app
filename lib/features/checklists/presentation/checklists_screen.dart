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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createChecklist(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}

Future<void> _createChecklist(BuildContext context, WidgetRef ref) async {
  final title = await showChecklistNameDialog(context);
  if (title == null) return;
  final result = await ref
      .read(checklistControllerProvider.notifier)
      .create(title);
  if (context.mounted && result is Err<int>) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not create the checklist')),
    );
  }
}

/// The non-empty list of checklist summaries.
class _ChecklistList extends ConsumerWidget {
  const _ChecklistList({required this.summaries});

  final List<ChecklistSummary> summaries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      itemCount: summaries.length,
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
    await ref
        .read(checklistControllerProvider.notifier)
        .rename(summary.checklist.id, title);
  }

  Future<void> _recolour(BuildContext context, WidgetRef ref, int id) async {
    final choice = await showRecolourDialog(context);
    if (choice == null || !context.mounted) return; // dismissed (no-op)
    await ref
        .read(checklistControllerProvider.notifier)
        .setColor(id, choice.color?.toARGB32());
  }

  Future<void> _archive(
    BuildContext context,
    WidgetRef ref,
    ChecklistSummary summary,
  ) async {
    final controller = ref.read(checklistControllerProvider.notifier);
    await controller.archive(summary.checklist.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Archived "${summary.checklist.title}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => controller.restore(summary.checklist.id),
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
    await ref
        .read(checklistControllerProvider.notifier)
        .delete(summary.checklist.id);
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
