import 'dart:async';
import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/optimistic_order.dart';
import 'package:checkplan/core/result.dart';
import 'package:checkplan/core/widgets/async_switcher.dart';
import 'package:checkplan/core/widgets/confirm_delete_dialog.dart';
import 'package:checkplan/core/widgets/empty_view.dart';
import 'package:checkplan/core/widgets/error_snackbar.dart';
import 'package:checkplan/core/widgets/optimistic_reorder.dart';
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
      appBar: AppBar(
        title: const Text('Checklist Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            tooltip: 'Archived',
            onPressed: () => unawaited(context.push('/archived')),
          ),
        ],
      ),
      body: AsyncSwitcher(
        value: checklistsAsync,
        isEmpty: (summaries) => summaries.isEmpty,
        empty: const EmptyView(
          message: 'No checklists yet',
          icon: Icons.checklist,
        ),
        data: (summaries) => _ChecklistList(summaries: summaries),
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
class _ChecklistList extends ConsumerStatefulWidget {
  const _ChecklistList({required this.summaries});

  final List<ChecklistSummary> summaries;

  @override
  ConsumerState<_ChecklistList> createState() => _ChecklistListState();
}

class _ChecklistListState extends ConsumerState<_ChecklistList>
    with OptimisticReorder<_ChecklistList> {
  // Reflects a just-dropped reorder immediately, before the write round-trips
  // back through the stream — otherwise the list flickers the old order.
  final _order = OptimisticOrder();

  @override
  Widget build(BuildContext context) {
    final summaries = _order.reconcile(
      widget.summaries,
      (summary) => summary.checklist.id,
    );
    return ReorderableListView.builder(
      itemCount: summaries.length,
      onReorderItem: (oldIndex, newIndex) =>
          _reorder(summaries, oldIndex, newIndex),
      itemBuilder: (context, index) {
        final summary = summaries[index];
        return ChecklistTile(
          key: ValueKey(summary.checklist.id),
          summary: summary,
          onRename: () => _rename(summary),
          onRecolor: () => _recolor(summary.checklist.id),
          onArchive: () => _archive(summary),
          onDelete: () => _delete(summary),
          onOpen: () => _open(summary.checklist.id),
        );
      },
    );
  }

  void _open(int id) {
    // Once a detail route is already on top, a repeat tap (a fast double-tap)
    // would stack a second screen; canPop() is true by then, so drop it.
    if (Navigator.of(context).canPop()) return;
    unawaited(context.push('/checklist/$id'));
  }

  Future<void> _reorder(
    List<ChecklistSummary> summaries,
    int oldIndex,
    int newIndex,
  ) => applyReorder(
    currentIds: summaries.map((s) => s.checklist.id).toList(),
    oldIndex: oldIndex,
    newIndex: newIndex,
    order: _order,
    persist: (movedId, beforeId, afterId) => ref
        .read(checklistControllerProvider.notifier)
        .reorder(movedId, beforeId, afterId),
    errorMessage: 'Could not reorder the checklists',
  );

  Future<void> _rename(ChecklistSummary summary) async {
    final title = await showChecklistNameDialog(
      context,
      initialTitle: summary.checklist.title,
    );
    if (title == null) return;
    final result = await ref
        .read(checklistControllerProvider.notifier)
        .rename(summary.checklist.id, title);
    if (!mounted) return;
    if (result case Err()) {
      showErrorSnackBar(context, 'Could not rename the checklist');
    }
  }

  Future<void> _recolor(int id) async {
    final choice = await showRecolorDialog(context);
    if (choice == null || !mounted) return; // dismissed (no-op)
    final result = await ref
        .read(checklistControllerProvider.notifier)
        .setColor(id, choice.color?.toARGB32());
    if (!mounted) return;
    if (result case Err()) {
      showErrorSnackBar(context, 'Could not update the color');
    }
  }

  Future<void> _archive(ChecklistSummary summary) async {
    final controller = ref.read(checklistControllerProvider.notifier);
    final result = await controller.archive(summary.checklist.id);
    if (!mounted) return;
    if (result case Err()) {
      showErrorSnackBar(context, 'Could not archive the checklist');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Archived "${summary.checklist.title}"'),
        // A SnackBar with an action defaults to persisting (Flutter sets
        // persist = action != null), so without this the Undo bar would never
        // clear itself. Restore is also reachable from the Archived view, so a
        // finite window here is safe.
        persist: false,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            final restoreResult = await controller.restore(
              summary.checklist.id,
            );
            if (!mounted) return;
            if (restoreResult case Err()) {
              showErrorSnackBar(context, 'Could not restore the checklist');
            }
          },
        ),
      ),
    );
  }

  Future<void> _delete(ChecklistSummary summary) async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Delete "${summary.checklist.title}"?',
      message: 'This also deletes its tasks. This cannot be undone.',
    );
    if (!confirmed || !mounted) return;
    final result = await ref
        .read(checklistControllerProvider.notifier)
        .delete(summary.checklist.id);
    if (!mounted) return;
    if (result case Err()) {
      showErrorSnackBar(context, 'Could not delete the checklist');
    }
  }
}
