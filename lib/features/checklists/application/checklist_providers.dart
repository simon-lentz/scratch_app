import 'package:checkplan/core/database/daos/checklist_dao.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Accessor for the [ChecklistDao], backed by the shared database.
final checklistDaoProvider = Provider<ChecklistDao>(
  (ref) => ref.watch(appDatabaseProvider).checklistDao,
);

/// Reactive list of non-archived checklists, each with its task progress.
///
/// Re-emits whenever checklists or their tasks change.
final activeChecklistsProvider = StreamProvider<List<ChecklistSummary>>(
  (ref) => ref.watch(checklistDaoProvider).watchActiveSummaries(),
);

/// Write commands for checklists.
///
/// Holds no state of its own — the database is the state. Each
/// command returns a [Result]: drift exceptions become [Err]; programming bugs
/// (`Error`) propagate.
class ChecklistController extends Notifier<void> {
  @override
  void build() {}

  ChecklistDao get _dao => ref.read(checklistDaoProvider);

  /// Creates a checklist from the (trimmed) [title]; the [Ok] value is its id.
  Future<Result<int>> create(String title) =>
      Result.guard(() => _dao.create(title.trim()));

  /// Renames the checklist [id] to the trimmed [title].
  Future<Result<void>> rename(int id, String title) => Result.guard(() async {
    await _dao.rename(id, title.trim());
  });

  /// Sets or clears the checklist [id]'s ARGB theme colour.
  Future<Result<void>> setColor(int id, int? colorValue) =>
      Result.guard(() async {
        await _dao.setColor(id, colorValue);
      });

  /// Archives the checklist [id], hiding it from the active list.
  Future<Result<void>> archive(int id) => Result.guard(() async {
    await _dao.archive(id);
  });

  /// Restores the previously archived checklist [id].
  Future<Result<void>> restore(int id) => Result.guard(() async {
    await _dao.restore(id);
  });

  /// Rewrites checklist positions to match [orderedIds].
  Future<Result<void>> reorder(List<int> orderedIds) => Result.guard(() async {
    await _dao.reorder(orderedIds);
  });

  /// Permanently deletes the checklist [id], cascading to its tasks.
  Future<Result<void>> delete(int id) => Result.guard(() async {
    await _dao.deleteById(id);
  });
}

/// Exposes [ChecklistController] for write commands.
final checklistControllerProvider = NotifierProvider<ChecklistController, void>(
  ChecklistController.new,
);
