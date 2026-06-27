import 'dart:async';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/reordering.dart';
import 'package:checkplan/core/result.dart';
import 'package:checkplan/core/widgets/confirm_delete_dialog.dart';
import 'package:checkplan/core/widgets/empty_view.dart';
import 'package:checkplan/core/widgets/error_snackbar.dart';
import 'package:checkplan/core/widgets/stream_error_view.dart';
import 'package:checkplan/features/checklists/application/checklist_providers.dart';
import 'package:checkplan/features/checklists/presentation/widgets/checklist_name_dialog.dart';
import 'package:checkplan/features/checklists/presentation/widgets/checklist_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The "Lists" home screen: a live, reactive list of the user's checklists.
class ChecklistsScreen extends ConsumerWidget {
  /// Creates the Lists screen.
  const ChecklistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checklistsAsync = ref.watch(activeChecklistsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Lists')),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: switch (checklistsAsync) {
          AsyncData(:final value) when value.isEmpty => const EmptyView(
            key: ValueKey('empty'),
            message: 'No checklists yet',
            icon: Icons.checklist,
          ),
          AsyncData(:final value) => KeyedSubtree(
            key: const ValueKey('data'),
            child: _ChecklistList(summaries: value),
          ),
          AsyncError(:final error) => StreamErrorView(
            key: const ValueKey('error'),
            error: error,
            onRetry: () => ref.invalidate(appDatabaseProvider),
          ),
          _ => const Center(
            key: ValueKey('loading'),
            child: CircularProgressIndicator(),
          ),
        },
      ),
      floatingActionButton: switch (checklistsAsync) {
        AsyncData() => FloatingActionButton(
          onPressed: () => _createChecklist(context, ref),
          tooltip: 'New checklist',
          child: const Icon(Icons.add),
        ),
        _ => null,
      },
    );
  }
}

Future<void> _createChecklist(BuildContext context, WidgetRef ref) async {
  final title = await showChecklistNameDialog(context);
  if (title == null || !context.mounted) return;
  final result = await ref
      .read(checklistControllerProvider.notifier)
      .create(title);
  if (!context.mounted) return;
  if (result case Err()) {
    showErrorSnackBar(context, 'Could not create the checklist');
  }
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
          onRecolor: () => _recolor(context, ref, summary.checklist.id),
          onArchive: () => _archive(context, ref, summary),
          onDelete: () => _delete(context, ref, summary),
          onOpen: () => _open(context, summary.checklist.id),
        );
      },
    );
  }

  void _open(BuildContext context, int id) {
    // Once a detail route is already on top, a repeat tap (a fast double-tap)
    // would stack a second screen; canPop() is true by then, so drop it.
    if (Navigator.of(context).canPop()) return;
    unawaited(context.push('/checklist/$id'));
  }

  Future<void> _reorder(
    BuildContext context,
    WidgetRef ref,
    int oldIndex,
    int newIndex,
  ) async {
    final ids = reorderedIds(
      summaries.map((s) => s.checklist.id).toList(),
      oldIndex,
      newIndex,
    );
    final result = await ref
        .read(checklistControllerProvider.notifier)
        .reorder(ids);
    if (!context.mounted) return;
    if (result case Err()) {
      showErrorSnackBar(context, 'Could not reorder the checklists');
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
      showErrorSnackBar(context, 'Could not rename the checklist');
    }
  }

  Future<void> _recolor(BuildContext context, WidgetRef ref, int id) async {
    final choice = await showRecolorDialog(context);
    if (choice == null || !context.mounted) return; // dismissed (no-op)
    final result = await ref
        .read(checklistControllerProvider.notifier)
        .setColor(id, choice.color?.toARGB32());
    if (!context.mounted) return;
    if (result case Err()) {
      showErrorSnackBar(context, 'Could not update the color');
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
      showErrorSnackBar(context, 'Could not archive the checklist');
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
              showErrorSnackBar(context, 'Could not restore the checklist');
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
