import 'package:checkplan/core/color.dart';
import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/optimistic_order.dart';
import 'package:checkplan/core/result.dart';
import 'package:checkplan/core/time/current_day.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:checkplan/core/validation.dart';
import 'package:checkplan/core/widgets/async_switcher.dart';
import 'package:checkplan/core/widgets/confirm_delete_dialog.dart';
import 'package:checkplan/core/widgets/empty_view.dart';
import 'package:checkplan/core/widgets/error_snackbar.dart';
import 'package:checkplan/core/widgets/name_dialog.dart';
import 'package:checkplan/core/widgets/optimistic_reorder.dart';
import 'package:checkplan/features/checklists/application/checklist_providers.dart';
import 'package:checkplan/features/tasks/application/subtask_providers.dart';
import 'package:checkplan/features/tasks/application/task_providers.dart';
import 'package:checkplan/features/tasks/presentation/task_actions.dart';
import 'package:checkplan/features/tasks/presentation/widgets/subtask_tile.dart';
import 'package:checkplan/features/tasks/presentation/widgets/task_editor_sheet.dart';
import 'package:checkplan/features/tasks/presentation/widgets/task_tile.dart';
import 'package:flutter/foundation.dart';
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
    final checklist = ref.watch(checklistByIdProvider(checklistId));
    final title = checklist?.title ?? 'Checklist';
    final colorValue = checklist?.colorValue;
    final barColor = colorValue == null ? null : Color(colorValue);
    final tasksAsync = ref.watch(tasksForChecklistProvider(checklistId));
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: barColor,
        foregroundColor: barColor == null ? null : readableOn(barColor),
      ),
      body: AsyncSwitcher(
        value: tasksAsync,
        isEmpty: (tasks) => tasks.isEmpty,
        empty: const EmptyView(
          message: 'No tasks yet',
          icon: Icons.task_alt,
        ),
        data: (tasks) => _TaskList(tasks: tasks),
      ),
      floatingActionButton: switch (tasksAsync) {
        AsyncData() => FloatingActionButton(
          onPressed: () => _addTask(context, ref, checklistId),
          tooltip: 'New task',
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
class _TaskList extends ConsumerStatefulWidget {
  const _TaskList({required this.tasks});

  final List<TaskView> tasks;

  @override
  ConsumerState<_TaskList> createState() => _TaskListState();
}

class _TaskListState extends ConsumerState<_TaskList>
    with OptimisticReorder<_TaskList> {
  // Reflects a just-dropped reorder immediately, before the write round-trips
  // back through the stream — otherwise the list flickers the old order.
  final _order = OptimisticOrder();

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(currentDayProvider);
    final tasks = _order.reconcile(widget.tasks, (view) => view.task.id);
    return ReorderableListView.builder(
      itemCount: tasks.length,
      // Each task carries its own drag region, scoped to the tile in
      // `_TaskItem`. With the default whole-item handle, a long-press anywhere
      // on an expanded task — including its nested subtask rows — would start a
      // parent reorder; scoping it to the tile stops that hijack.
      buildDefaultDragHandles: false,
      onReorderItem: (oldIndex, newIndex) =>
          _reorder(tasks, oldIndex, newIndex),
      // The row handlers below use this State's context (not a per-row builder
      // context), so a row that unmounts mid-write can't suppress its error
      // snackbar. Hence the wildcard parameter.
      itemBuilder: (_, index) {
        final view = tasks[index];
        return _TaskItem(
          key: ValueKey(view.task.id),
          index: index,
          view: view,
          today: today,
          onToggleDone: (isDone) =>
              toggleTaskDone(context, ref, view.task.id, isDone: isDone),
          onEdit: () => _edit(view),
          confirmAndDelete: () =>
              _confirmAndDelete(view.task.id, view.task.title),
        );
      },
    );
  }

  Future<void> _reorder(List<TaskView> tasks, int oldIndex, int newIndex) =>
      applyReorder(
        currentIds: tasks.map((t) => t.task.id).toList(),
        oldIndex: oldIndex,
        newIndex: newIndex,
        order: _order,
        persist: (movedId, beforeId, afterId) => ref
            .read(taskControllerProvider.notifier)
            .reorder(movedId, beforeId, afterId),
        errorMessage: 'Could not reorder the tasks',
      );

  // Confirms, then deletes, then always returns false: on success the reactive
  // stream removes the row (so the Dismissible never enters its dismissed state
  // mid-async-write); on failure the row stays and a snackbar shows.
  Future<bool> _confirmAndDelete(int id, String title) async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Delete "$title"?',
      message: 'This also deletes its subtasks. This cannot be undone.',
    );
    if (!confirmed || !mounted) return false;
    final result = await ref.read(taskControllerProvider.notifier).delete(id);
    if (!mounted) return false;
    if (result case Err()) {
      showErrorSnackBar(context, 'Could not delete the task');
    }
    return false;
  }

  Future<void> _edit(TaskView view) async {
    final draft = await showTaskEditorSheet(context, task: view.task);
    if (draft == null || !mounted) return;
    final result = await ref
        .read(taskControllerProvider.notifier)
        .edit(
          view.task.id,
          title: draft.title,
          notes: draft.notes,
          dueDay: draft.dueDay,
        );
    if (!mounted) return;
    if (result case Err()) {
      showErrorSnackBar(context, 'Could not save the task');
    }
  }
}

/// One row of the task list: the dismissible task tile plus, when expanded, its
/// subtasks and an inline add field. Expansion is local view state.
class _TaskItem extends ConsumerStatefulWidget {
  const _TaskItem({
    required this.index,
    required this.view,
    required this.today,
    required this.onToggleDone,
    required this.onEdit,
    required this.confirmAndDelete,
    super.key,
  });

  /// This task's position in the outer list, for its drag-start listener.
  final int index;
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

  @override
  Widget build(BuildContext context) {
    final task = widget.view.task;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Only the tile is a drag region — the subtask sublist below is
        // deliberately outside it, so a long-press on a subtask cannot start a
        // parent task reorder. The listener is invisible, so the tile renders
        // and long-press-reorders exactly as it did under the default handle.
        ReorderableDelayedDragStartListener(
          index: widget.index,
          child: Dismissible(
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
              dragHandle: _desktopDragHandle(),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _expanded
              ? _SubtaskSection(taskId: task.id)
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  // On desktop/web the outer task list has no default handle (it was disabled
  // to scope the long-press drag away from the nested subtasks), so a mouse
  // user has no visible reorder affordance. Mirror Flutter's own desktop
  // default: a grip that starts an immediate drag, with a grab cursor. Mobile
  // keeps the long-press-on-tile drag and shows no grip.
  Widget? _desktopDragHandle() {
    final isDesktop = switch (defaultTargetPlatform) {
      TargetPlatform.linux ||
      TargetPlatform.windows ||
      TargetPlatform.macOS => true,
      _ => false,
    };
    if (!isDesktop) return null;
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: ReorderableDragStartListener(
        index: widget.index,
        // Claim taps so a click on the grip doesn't fall through to the tile's
        // onTap (edit); excludeFromSemantics keeps it out of the a11y tree.
        child: GestureDetector(
          onTap: () {},
          excludeFromSemantics: true,
          child: const Icon(Icons.drag_handle),
        ),
      ),
    );
  }
}

/// The expanded task's subtask region: a reactive, reorderable list of subtasks
/// plus an inline add field. Its own [ConsumerStatefulWidget] so subtask-stream
/// emissions rebuild only this section, not the whole task tile above it.
class _SubtaskSection extends ConsumerStatefulWidget {
  const _SubtaskSection({required this.taskId});

  /// The parent task whose subtasks this section shows and edits.
  final int taskId;

  @override
  ConsumerState<_SubtaskSection> createState() => _SubtaskSectionState();
}

class _SubtaskSectionState extends ConsumerState<_SubtaskSection>
    with OptimisticReorder<_SubtaskSection> {
  final _addController = TextEditingController();
  // Reflects a just-dropped subtask reorder immediately, before the write
  // round-trips back through the stream — mirrors _TaskListState's _order.
  final _subOrder = OptimisticOrder();

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskId = widget.taskId;
    final subtasksAsync = ref.watch(subtasksForTaskProvider(taskId));
    // Loading and error both collapse to an empty list: a subtask-query error
    // is pre-empted by the screen-level AsyncSwitcher (which blocks expansion),
    // and the brief first-expand loading frame is hidden by the enclosing
    // AnimatedSize. A nested loading/error view is deliberately omitted — the
    // shared AsyncSwitcher's full-screen destructive error arm is unfit inside
    // a single task row.
    final value = switch (subtasksAsync) {
      AsyncData(:final value) => value,
      _ => const <Subtask>[],
    };
    final rows = _subOrder.reconcile(value, (subtask) => subtask.id);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // A nested reorderable: the subtask rows drag via an explicit grip
        // (buildDefaultDragHandles: false) so they do not fight the outer task
        // list's long-press drag; shrink-wrapped and non-scrolling because the
        // outer list scrolls.
        if (rows.isNotEmpty)
          ReorderableListView.builder(
            key: ValueKey('subtasks-$taskId'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: rows.length,
            onReorderItem: (oldIndex, newIndex) => _reorderSub(
              rows.map((subtask) => subtask.id).toList(),
              oldIndex,
              newIndex,
            ),
            itemBuilder: (_, index) {
              final subtask = rows[index];
              return SubtaskTile(
                key: ValueKey(subtask.id),
                subtask: subtask,
                onToggleDone: (isDone) =>
                    _toggleSub(subtask.id, isDone: isDone),
                onRename: () => _renameSub(subtask.id, subtask.title),
                onDelete: () => _deleteSub(subtask.id),
                dragHandle: ReorderableDragStartListener(
                  index: index,
                  // The grip recognizes drags, not taps; without this a bare
                  // tap falls through to the row's onTap (rename). Claim and
                  // discard taps here so only drags reach the reorderable.
                  // excludeFromSemantics keeps it out of the a11y tree (no
                  // unlabeled tappable node).
                  child: GestureDetector(
                    onTap: () {},
                    excludeFromSemantics: true,
                    child: const Icon(Icons.drag_indicator),
                  ),
                ),
              );
            },
          ),
        Padding(
          padding: const EdgeInsets.only(left: 32, right: 16),
          child: TextField(
            controller: _addController,
            decoration: const InputDecoration(hintText: 'Add subtask'),
            inputFormatters: [LengthLimitingTextInputFormatter(maxTitleLength)],
            onSubmitted: (_) => _addSub(),
          ),
        ),
      ],
    );
  }

  Future<void> _addSub() async {
    final title = _addController.text;
    if (titleError(title) != null) return; // ignore empty input
    // Clear before the await: a second rapid submit then reads an empty field
    // and cannot re-add, and text typed during the write is not clobbered by a
    // post-await clear.
    _addController.clear();
    final result = await ref
        .read(subtaskControllerProvider.notifier)
        .add(widget.taskId, title);
    if (!mounted) return;
    if (result case Err()) {
      _addController.text = title; // restore so a failed add can be retried
      showErrorSnackBar(context, 'Could not add the subtask');
    }
  }

  Future<void> _renameSub(int id, String currentTitle) async {
    final title = await showNameDialog(
      context,
      title: 'Rename subtask',
      submitLabel: 'Save',
      initialValue: currentTitle,
    );
    if (title == null || !mounted) return;
    final result = await ref
        .read(subtaskControllerProvider.notifier)
        .rename(id, title);
    if (!mounted) return;
    if (result case Err()) {
      showErrorSnackBar(context, 'Could not rename the subtask');
    }
  }

  Future<void> _reorderSub(List<int> currentIds, int oldIndex, int newIndex) =>
      applyReorder(
        currentIds: currentIds,
        oldIndex: oldIndex,
        newIndex: newIndex,
        order: _subOrder,
        persist: (movedId, beforeId, afterId) => ref
            .read(subtaskControllerProvider.notifier)
            .reorder(movedId, beforeId, afterId),
        errorMessage: 'Could not reorder the subtasks',
      );

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
