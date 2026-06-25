import 'dart:async';

import 'package:checkplan/app/app.dart';
import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/connection.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/result.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:checkplan/core/validation.dart';
import 'package:checkplan/features/checklists/application/checklist_providers.dart';
import 'package:checkplan/features/tasks/application/subtask_providers.dart';
import 'package:checkplan/features/tasks/application/task_providers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// coverage:ignore-start
void main() {
  runApp(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(openAppDatabase())],
      child: const CheckPlanApp(),
    ),
  );
}

/// Interactive widget preview of [CheckPlanApp], backed by an in-memory store
/// instead of a database.
///
/// The real database is kept out of `main.dart`'s import graph on purpose:
/// `NativeDatabase` pulls in `dart:ffi`, which is unavailable on the
/// `flutter build web` target. [_PreviewStore] is pure Dart, so the preview
/// stays off that path while still exercising the real one-way loop — the FAB,
/// rename, recolor, archive, delete, and reorder all mutate the store, its
/// stream re-emits, and the screen rebuilds.
@Preview(name: 'CheckPlanApp')
Widget previewCheckPlanApp() {
  final store = _PreviewStore();
  final detailStore = _PreviewDetailStore();
  return ProviderScope(
    overrides: [
      activeChecklistsProvider.overrideWith((ref) {
        ref
          ..onDispose(store.dispose)
          ..onDispose(detailStore.dispose);
        return store.watch();
      }),
      checklistControllerProvider.overrideWith(() => _PreviewController(store)),
      tasksForChecklistProvider.overrideWith(
        (ref, checklistId) => detailStore.watchTasks(checklistId),
      ),
      taskControllerProvider.overrideWith(
        () => _PreviewTaskController(detailStore),
      ),
      subtasksForTaskProvider.overrideWith(
        (ref, taskId) => detailStore.watchSubtasks(taskId),
      ),
      subtaskControllerProvider.overrideWith(
        () => _PreviewSubtaskController(detailStore),
      ),
    ],
    child: const CheckPlanApp(),
  );
}

/// In-memory checklist store backing [previewCheckPlanApp].
///
/// Plays the database's role in the one-way loop: every mutation updates the
/// list and emits a new active snapshot, so the read stream re-emits and the UI
/// rebuilds. Archive is reversible (it sets `archivedAt`, hidden from the
/// snapshot) so Undo works; delete drops the row entirely.
class _PreviewStore {
  _PreviewStore() {
    _summaries.addAll([
      ChecklistSummary(checklist: _newRow('Groceries'), progress: (2, 5)),
      ChecklistSummary(
        checklist: _newRow('Weekend trip', colorValue: 0xFF00897B),
        progress: (0, 0),
      ),
    ]);
  }

  final _controller = StreamController<List<ChecklistSummary>>.broadcast();
  final List<ChecklistSummary> _summaries = [];
  var _nextId = 1;

  /// Emits the active snapshot now, then again after every mutation.
  Stream<List<ChecklistSummary>> watch() async* {
    yield _active();
    yield* _controller.stream;
  }

  List<ChecklistSummary> _active() => [
    for (final summary in _summaries)
      if (summary.checklist.archivedAt == null) summary,
  ];

  void _emit() => _controller.add(_active());

  Checklist _newRow(String title, {int? colorValue}) {
    final now = DateTime.timestamp();
    final id = _nextId++;
    return Checklist(
      id: id,
      title: title,
      colorValue: colorValue,
      position: id,
      createdAt: now,
      updatedAt: now,
    );
  }

  void _replace(int id, Checklist Function(Checklist row) update) {
    final index = _summaries.indexWhere((s) => s.checklist.id == id);
    if (index < 0) return;
    final current = _summaries[index];
    _summaries[index] = ChecklistSummary(
      checklist: update(current.checklist),
      progress: current.progress,
    );
    _emit();
  }

  int create(String title) {
    final row = _newRow(title);
    _summaries.add(ChecklistSummary(checklist: row, progress: (0, 0)));
    _emit();
    return row.id;
  }

  void rename(int id, String title) => _replace(
    id,
    (row) => row.copyWith(title: title, updatedAt: DateTime.timestamp()),
  );

  void setColor(int id, int? colorValue) => _replace(
    id,
    (row) => row.copyWith(
      colorValue: Value(colorValue),
      updatedAt: DateTime.timestamp(),
    ),
  );

  void archive(int id) => _replace(
    id,
    (row) => row.copyWith(archivedAt: Value(DateTime.timestamp())),
  );

  void restore(int id) =>
      _replace(id, (row) => row.copyWith(archivedAt: const Value(null)));

  void delete(int id) {
    _summaries.removeWhere((s) => s.checklist.id == id);
    _emit();
  }

  void reorder(List<int> orderedIds) {
    _summaries.sort(
      (a, b) => orderedIds
          .indexOf(a.checklist.id)
          .compareTo(orderedIds.indexOf(b.checklist.id)),
    );
    _emit();
  }

  /// Closes the broadcast stream when the preview's [ProviderScope] disposes.
  void dispose() => _controller.close();
}

/// A [ChecklistController] whose commands drive a [_PreviewStore] rather than a
/// database, so the preview's writes are interactive and never reach the
/// throw-only `appDatabaseProvider`.
class _PreviewController extends ChecklistController {
  _PreviewController(this._store);

  final _PreviewStore _store;

  @override
  Future<Result<int>> create(String title) async {
    final error = titleError(title);
    if (error != null) return Err(ValidationException(error));
    return Ok(_store.create(title.trim()));
  }

  @override
  Future<Result<void>> rename(int id, String title) async {
    final error = titleError(title);
    if (error != null) return Err(ValidationException(error));
    _store.rename(id, title.trim());
    return const Ok(null);
  }

  @override
  Future<Result<void>> setColor(int id, int? colorValue) async {
    _store.setColor(id, colorValue);
    return const Ok(null);
  }

  @override
  Future<Result<void>> archive(int id) async {
    _store.archive(id);
    return const Ok(null);
  }

  @override
  Future<Result<void>> restore(int id) async {
    _store.restore(id);
    return const Ok(null);
  }

  @override
  Future<Result<void>> reorder(List<int> orderedIds) async {
    _store.reorder(orderedIds);
    return const Ok(null);
  }

  @override
  Future<Result<void>> delete(int id) async {
    _store.delete(id);
    return const Ok(null);
  }
}

/// In-memory task + subtask store backing the detail route in
/// [previewCheckPlanApp], mirroring [_PreviewStore].
///
/// Plays the database's role for the detail screen: every mutation re-emits the
/// affected streams (a checklist's tasks; a task's subtasks), so the one-way
/// loop rebuilds the UI. Seeds checklist id 1 so the opened detail is
/// populated.
class _PreviewDetailStore {
  _PreviewDetailStore() {
    final apples = _newTask(1, 'Apples', isDone: true);
    _tasks.addAll([
      apples,
      _newTask(1, 'Oranges', isDone: true),
      _newTask(1, 'Bread'),
      _newTask(1, 'Milk'),
      _newTask(1, 'Butter'),
    ]);
    _subtasks.add(_newSubtask(apples.id, 'Granny Smith'));
  }

  final _tick = StreamController<void>.broadcast();
  final List<Task> _tasks = [];
  final List<Subtask> _subtasks = [];
  var _nextTaskId = 1;
  var _nextSubtaskId = 1;

  /// A checklist's tasks (with subtask progress), re-emitted on every change.
  Stream<List<TaskView>> watchTasks(int checklistId) async* {
    yield _taskViews(checklistId);
    yield* _tick.stream.map((_) => _taskViews(checklistId));
  }

  /// A task's subtasks, re-emitted on every change.
  Stream<List<Subtask>> watchSubtasks(int taskId) async* {
    yield _subtasksFor(taskId);
    yield* _tick.stream.map((_) => _subtasksFor(taskId));
  }

  List<TaskView> _taskViews(int checklistId) => [
    for (final task in _tasks)
      if (task.checklistId == checklistId)
        TaskView(task: task, subtaskProgress: _progressFor(task.id)),
  ]..sort((a, b) => a.task.position.compareTo(b.task.position));

  List<Subtask> _subtasksFor(int taskId) => [
    for (final s in _subtasks)
      if (s.taskId == taskId) s,
  ]..sort((a, b) => a.position.compareTo(b.position));

  Progress _progressFor(int taskId) {
    final subs = _subtasks.where((s) => s.taskId == taskId);
    return (subs.where((s) => s.isDone).length, subs.length);
  }

  void _emit() => _tick.add(null);

  Task _newTask(int checklistId, String title, {bool isDone = false}) {
    final now = DateTime.timestamp();
    final id = _nextTaskId++;
    return Task(
      id: id,
      checklistId: checklistId,
      title: title,
      isDone: isDone,
      position: id,
      createdAt: now,
      updatedAt: now,
    );
  }

  Subtask _newSubtask(int taskId, String title, {bool isDone = false}) {
    final now = DateTime.timestamp();
    final id = _nextSubtaskId++;
    return Subtask(
      id: id,
      taskId: taskId,
      title: title,
      isDone: isDone,
      position: id,
      createdAt: now,
      updatedAt: now,
    );
  }

  void _replaceTask(int id, Task Function(Task row) update) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index < 0) return;
    _tasks[index] = update(_tasks[index]);
  }

  int addTask(int checklistId, String title) {
    final row = _newTask(checklistId, title);
    _tasks.add(row);
    _emit();
    return row.id;
  }

  void editTask(
    int id, {
    required String title,
    required EpochDay? dueDay,
    String? notes,
  }) {
    _replaceTask(
      id,
      (row) => row.copyWith(
        title: title,
        notes: Value(notes),
        dueDay: Value(dueDay?.value),
        updatedAt: DateTime.timestamp(),
      ),
    );
    _emit();
  }

  void setTaskDone(int id, {required bool isDone}) {
    _replaceTask(
      id,
      (row) => row.copyWith(isDone: isDone, updatedAt: DateTime.timestamp()),
    );
    _emit();
  }

  void deleteTask(int id) {
    _tasks.removeWhere((t) => t.id == id);
    _subtasks.removeWhere((s) => s.taskId == id); // FK cascade
    _emit();
  }

  void reorderTasks(List<int> orderedIds) {
    for (final (index, id) in orderedIds.indexed) {
      _replaceTask(id, (row) => row.copyWith(position: index));
    }
    _emit();
  }

  int addSubtask(int taskId, String title) {
    final row = _newSubtask(taskId, title);
    _subtasks.add(row);
    _emit();
    return row.id;
  }

  void setSubtaskDone(int id, {required bool isDone}) {
    final index = _subtasks.indexWhere((s) => s.id == id);
    if (index < 0) return;
    _subtasks[index] = _subtasks[index].copyWith(
      isDone: isDone,
      updatedAt: DateTime.timestamp(),
    );
    _emit();
  }

  void deleteSubtask(int id) {
    _subtasks.removeWhere((s) => s.id == id);
    _emit();
  }

  /// Closes the broadcast stream when the preview's `ProviderScope` disposes.
  void dispose() => _tick.close();
}

/// A [TaskController] whose commands drive a [_PreviewDetailStore] rather than
/// a database, so the preview's task writes never reach the throw-only
/// `appDatabaseProvider`.
class _PreviewTaskController extends TaskController {
  _PreviewTaskController(this._store);

  final _PreviewDetailStore _store;

  @override
  Future<Result<int>> add(int checklistId, String title) async {
    final error = titleError(title);
    if (error != null) return Err(ValidationException(error));
    return Ok(_store.addTask(checklistId, title.trim()));
  }

  @override
  Future<Result<void>> edit(
    int id, {
    required String title,
    required EpochDay? dueDay,
    String? notes,
  }) async {
    final error = titleError(title);
    if (error != null) return Err(ValidationException(error));
    _store.editTask(id, title: title.trim(), notes: notes, dueDay: dueDay);
    return const Ok(null);
  }

  @override
  Future<Result<void>> setDone(int id, {required bool isDone}) async {
    _store.setTaskDone(id, isDone: isDone);
    return const Ok(null);
  }

  @override
  Future<Result<void>> delete(int id) async {
    _store.deleteTask(id);
    return const Ok(null);
  }

  @override
  Future<Result<void>> reorder(int checklistId, List<int> orderedIds) async {
    _store.reorderTasks(orderedIds);
    return const Ok(null);
  }
}

/// A [SubtaskController] whose commands drive a [_PreviewDetailStore].
class _PreviewSubtaskController extends SubtaskController {
  _PreviewSubtaskController(this._store);

  final _PreviewDetailStore _store;

  @override
  Future<Result<int>> add(int taskId, String title) async {
    final error = titleError(title);
    if (error != null) return Err(ValidationException(error));
    return Ok(_store.addSubtask(taskId, title.trim()));
  }

  @override
  Future<Result<void>> setDone(int id, {required bool isDone}) async {
    _store.setSubtaskDone(id, isDone: isDone);
    return const Ok(null);
  }

  @override
  Future<Result<void>> delete(int id) async {
    _store.deleteSubtask(id);
    return const Ok(null);
  }
}

// coverage:ignore-end
