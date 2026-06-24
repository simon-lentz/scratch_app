import 'dart:async';

import 'package:checkplan/app/app.dart';
import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/connection.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/result.dart';
import 'package:checkplan/core/validation.dart';
import 'package:checkplan/features/checklists/application/checklist_providers.dart';
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
/// rename, recolour, archive, delete, and reorder all mutate the store, its
/// stream re-emits, and the screen rebuilds.
@Preview(name: 'CheckPlanApp')
Widget previewCheckPlanApp() {
  final store = _PreviewStore();
  return ProviderScope(
    overrides: [
      activeChecklistsProvider.overrideWith((ref) {
        ref.onDispose(store.dispose);
        return store.watch();
      }),
      checklistControllerProvider.overrideWith(() => _PreviewController(store)),
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

// coverage:ignore-end
