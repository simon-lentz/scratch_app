import 'package:checkplan/core/database/daos/checklist_dao.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/result.dart';
import 'package:checkplan/core/validation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'checklist_providers.g.dart';

/// Accessor for the [ChecklistDao], backed by the shared database.
@Riverpod(keepAlive: true)
ChecklistDao checklistDao(Ref ref) =>
    ref.watch(appDatabaseProvider).checklistDao;

/// Reactive list of non-archived checklists, each with its task progress.
///
/// Re-emits whenever checklists or their tasks change.
@Riverpod(keepAlive: true)
Stream<List<ChecklistSummary>> activeChecklists(Ref ref) =>
    ref.watch(checklistDaoProvider).watchActiveSummaries();

/// Reactive list of archived checklists, most-recently-archived first.
///
/// Backs the archive view; re-emits whenever checklists or their tasks change.
@Riverpod(keepAlive: true)
Stream<List<ChecklistSummary>> archivedChecklists(Ref ref) =>
    ref.watch(checklistDaoProvider).watchArchivedSummaries();

/// Write commands for checklists.
///
/// Holds no state of its own — the database is the state. Each command returns
/// a [Result]: rejected input and caught exceptions become [Err]; programming
/// bugs (`Error`) propagate.
@Riverpod(keepAlive: true)
class ChecklistController extends _$ChecklistController {
  @override
  void build() {}

  ChecklistDao get _dao => ref.read(checklistDaoProvider);

  /// Creates a checklist from the (trimmed) [title]; the [Ok] value is its id.
  ///
  /// Rejects an empty or over-length [title] with an [Err] wrapping a
  /// [ValidationException] before the database is touched ([titleError] is the
  /// authoritative check; the DB length constraint is only a backstop).
  Future<Result<int>> create(String title) {
    final error = titleError(title);
    if (error != null) {
      return Future.value(Err(ValidationException(error)));
    }
    return Result.guard(() => _dao.create(title.trim()));
  }

  /// Renames the checklist [id] to the trimmed [title].
  ///
  /// Rejects an empty or over-length [title] like [create].
  Future<Result<void>> rename(int id, String title) {
    final error = titleError(title);
    if (error != null) {
      return Future.value(Err(ValidationException(error)));
    }
    return Result.guard(() async {
      await _dao.rename(id, title.trim());
    });
  }

  /// Sets or clears the checklist [id]'s ARGB theme color.
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

/// The summary for one checklist by [id] — title, color, and task progress —
/// resolved directly from the database via [ChecklistDao.watchById], so it is
/// correct for an archived checklist or a cold deep-link, not only for a
/// checklist already in the active list. `autoDispose` (the codegen default)
/// like the other detail reads.
@riverpod
Stream<ChecklistSummary?> checklistById(Ref ref, int id) =>
    ref.watch(checklistDaoProvider).watchById(id);
