import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/reordering.dart';
import 'package:checkplan/core/result.dart';
import 'package:checkplan/core/time/current_day.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:checkplan/core/validation.dart';
import 'package:checkplan/core/widgets/confirm_delete_dialog.dart';
import 'package:checkplan/core/widgets/empty_view.dart';
import 'package:checkplan/core/widgets/error_snackbar.dart';
import 'package:checkplan/core/widgets/name_dialog.dart';
import 'package:checkplan/core/widgets/stream_error_view.dart';
import 'package:checkplan/features/checklists/application/checklist_providers.dart';
import 'package:checkplan/features/tasks/application/subtask_providers.dart';
import 'package:checkplan/features/tasks/application/task_providers.dart';
import 'package:checkplan/features/tasks/presentation/task_actions.dart';
import 'package:checkplan/features/tasks/presentation/widgets/subtask_tile.dart';
import 'package:checkplan/features/tasks/presentation/widgets/task_editor_sheet.dart';
import 'package:checkplan/features/tasks/presentation/widgets/task_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A checklist's detail screen: a live, reactive list of its tasks.
class ChecklistDetailScreen extends ConsumerWidget {
  /// Creates the detail screen for the checklist with [checklistId].
  const ChecklistDetailScreen({required this.checklistId, super.key});

  /// The id of the checklist whose tasks are shown.
  final int checklistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title =
        ref.watch(checklistByIdProvider(checklistId))?.checklist.title ??
        'Checklist';
    final tasksAsync = ref.watch(tasksForChecklistProvider(checklistId));
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: switch (tasksAsync) {
        AsyncData(:final value) when value.isEmpty => const EmptyView(
          message: 'No tasks yet',
        ),
        AsyncData(:final value) => _TaskList(
          tasks: value,
          checklistId: checklistId,
        ),
        AsyncError(:final error) => StreamErrorView(error: error),
        _ => const Center(child: CircularProgressIndicator()),
      },
      floatingActionButton: switch (tasksAsync) {
        AsyncData() => FloatingActionButton(
          onPressed: () => _addTask(context, ref, checklistId),
          child: const Icon(Icons.add),
        ),
        _ => null,
      },
    );
  }
}

Future<void> _addTask(
  BuildContext context,
  WidgetRef ref,
  int checklistId,
) async {
  final title = await showNameDialog(
    context,
    title: 'New task',
    submitLabel: 'Add',
  );
  if (title == null || !context.mounted) return;
  final result = await ref
      .read(taskControllerProvider.notifier)
      .add(checklistId, title);
  if (!context.mounted) return;
  if (result case Err()) showErrorSnackBar(context, 'Could not add the task');
}

/// The non-empty list of task views.
class _TaskList extends ConsumerWidget {
  const _TaskList({required this.tasks, required this.checklistId});

  final List<TaskView> tasks;
  final int checklistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(currentDayProvider);
    return ReorderableListView.builder(
      itemCount: tasks.length,
      onReorderItem: (oldIndex, newIndex) =>
          _reorder(context, ref, oldIndex, newIndex),
      // The row handlers below close over this build context (not a per-row
      // builder context), so a row that unmounts mid-write can't suppress its
      // error snackbar. Hence the wildcard parameter.
      itemBuilder: (_, index) {
        final view = tasks[index];
        return _TaskItem(
          key: ValueKey(view.task.id),
          view: view,
          today: today,
          onToggleDone: (isDone) =>
              toggleTaskDone(context, ref, view.task.id, isDone: isDone),
          onEdit: () => _edit(context, ref, view),
          confirmAndDelete: () =>
              _confirmAndDelete(context, ref, view.task.id, view.task.title),
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
    final ids = reorderedIds(
      tasks.map((t) => t.task.id).toList(),
      oldIndex,
      newIndex,
    );
    final result = await ref
        .read(taskControllerProvider.notifier)
        .reorder(checklistId, ids);
    if (!context.mounted) return;
    if (result case Err()) {
      showErrorSnackBar(context, 'Could not reorder the tasks');
    }
  }

  // Confirms, then deletes, then always returns false: on success the reactive
  // stream removes the row (so the Dismissible never enters its dismissed state
  // mid-async-write); on failure the row stays and a snackbar shows.
  Future<bool> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    int id,
    String title,
  ) async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Delete "$title"?',
      message: 'This also deletes its subtasks. This cannot be undone.',
    );
    if (!confirmed || !context.mounted) return false;
    final result = await ref.read(taskControllerProvider.notifier).delete(id);
    if (!context.mounted) return false;
    if (result case Err()) {
      showErrorSnackBar(context, 'Could not delete the task');
    }
    return false;
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    TaskView view,
  ) async {
    final draft = await showTaskEditorSheet(context, task: view.task);
    if (draft == null || !context.mounted) return;
    final result = await ref
        .read(taskControllerProvider.notifier)
        .edit(
          view.task.id,
          title: draft.title,
          notes: draft.notes,
          dueDay: draft.dueDay,
        );
    if (!context.mounted) return;
    if (result case Err()) {
      showErrorSnackBar(context, 'Could not save the task');
    }
  }
}

/// One row of the task list: the dismissible task tile plus, when expanded, its
/// subtasks and an inline add field. Expansion is local view state.
class _TaskItem extends ConsumerStatefulWidget {
  const _TaskItem({
    required this.view,
    required this.today,
    required this.onToggleDone,
    required this.onEdit,
    required this.confirmAndDelete,
    super.key,
  });

  final TaskView view;
  final EpochDay today;
  final ValueChanged<bool> onToggleDone;
  final VoidCallback onEdit;
  final Future<bool> Function() confirmAndDelete;

  @override
  ConsumerState<_TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends ConsumerState<_TaskItem> {
  bool _expanded = false;
  final _addController = TextEditingController();

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.view.task;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Dismissible(
          key: ValueKey('dismiss-${task.id}'),
          direction: DismissDirection.endToStart,
          background: ColoredBox(
            color: scheme.errorContainer,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Icon(Icons.delete, color: scheme.onErrorContainer),
              ),
            ),
          ),
          // See `_confirmAndDelete` on `_TaskList`: it deletes then returns
          // false, so the row leaves via the reactive stream, never via the
          // Dismissible's dismissed state.
          confirmDismiss: (_) => widget.confirmAndDelete(),
          child: TaskTile(
            key: ValueKey(task.id),
            view: widget.view,
            today: widget.today,
            onToggleDone: widget.onToggleDone,
            onEdit: widget.onEdit,
            expanded: _expanded,
            onToggleExpanded: () => setState(() => _expanded = !_expanded),
          ),
        ),
        if (_expanded) _subtasks(task.id),
      ],
    );
  }

  Widget _subtasks(int taskId) {
    final subtasksAsync = ref.watch(subtasksForTaskProvider(taskId));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...switch (subtasksAsync) {
          AsyncData(:final value) => value.map(
            (subtask) => SubtaskTile(
              key: ValueKey(subtask.id),
              subtask: subtask,
              onToggleDone: (isDone) => _toggleSub(subtask.id, isDone: isDone),
              onDelete: () => _deleteSub(subtask.id),
            ),
          ),
          _ => const [],
        },
        Padding(
          padding: const EdgeInsets.only(left: 32, right: 16),
          child: TextField(
            controller: _addController,
            decoration: const InputDecoration(hintText: 'Add subtask'),
            inputFormatters: [LengthLimitingTextInputFormatter(maxTitleLength)],
            onSubmitted: (_) => _addSub(taskId),
          ),
        ),
      ],
    );
  }

  Future<void> _addSub(int taskId) async {
    final title = _addController.text;
    if (titleError(title) != null) return; // ignore empty input
    // Clear before the await: a second rapid submit then reads an empty field
    // and cannot re-add, and text typed during the write is not clobbered by a
    // post-await clear.
    _addController.clear();
    final result = await ref
        .read(subtaskControllerProvider.notifier)
        .add(taskId, title);
    if (!mounted) return;
    if (result case Err()) {
      _addController.text = title; // restore so a failed add can be retried
      showErrorSnackBar(context, 'Could not add the subtask');
    }
  }

  Future<void> _toggleSub(int id, {required bool isDone}) async {
    final result = await ref
        .read(subtaskControllerProvider.notifier)
        .setDone(id, isDone: isDone);
    if (!mounted) return;
    if (result case Err()) {
      showErrorSnackBar(context, 'Could not update the subtask');
    }
  }

  Future<void> _deleteSub(int id) async {
    final result = await ref
        .read(subtaskControllerProvider.notifier)
        .delete(id);
    if (!mounted) return;
    if (result case Err()) {
      showErrorSnackBar(context, 'Could not delete the subtask');
    }
  }
}
