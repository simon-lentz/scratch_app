import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/daos/checklist_dao.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/result.dart';
import 'package:checkplan/core/validation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show Provider, StreamProvider;
import 'package:flutter_riverpod/misc.dart'
    show ProviderFamily, StreamProviderFamily;
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
  Future<Result<int>> create(String title) =>
      guardTitle(title, (title) => _dao.create(title));

  /// Renames the checklist [id] to the trimmed [title].
  ///
  /// Rejects an empty or over-length [title] like [create].
  Future<Result<void>> rename(int id, String title) =>
      guardTitle(title, (title) async {
        await _dao.rename(id, title);
      });

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

  /// Re-ranks the moved checklist between its new neighbours (null = list end).
  Future<Result<void>> reorder(int movedId, int? beforeId, int? afterId) =>
      Result.guard(() async {
        await _dao.reorder(movedId, beforeId, afterId);
      });

  /// Permanently deletes the checklist [id], cascading to its tasks.
  Future<Result<void>> delete(int id) => Result.guard(() async {
    await _dao.deleteById(id);
  });
}

/// The live checklist row for the given id, resolved by id so it is correct
/// for an archived checklist or a cold deep-link, not only one already in the
/// active list. Hand-written rather than `@riverpod` because its value type
/// names the drift row class [Checklist], which `riverpod_generator` cannot
/// resolve from another file's generated part (the same limit that makes
/// `subtasksForTaskProvider` hand-written). `autoDispose` like the other detail
/// reads.
final StreamProviderFamily<Checklist?, int> checklistRowByIdProvider =
    StreamProvider.autoDispose.family<Checklist?, int>(
      (ref, id) => ref.watch(checklistDaoProvider).watchRowById(id),
    );

/// The checklist row backing the detail app bar's title and color.
///
/// Returns the by-id row stream's value once it has emitted; until then it
/// seeds from the warm [activeChecklistsProvider] row, so navigating from the
/// list renders the real title and color on the first frame instead of
/// flashing the fallback while the stream's first emission is in flight. A
/// checklist absent from the active list (archived, or a cold deep-link) has no
/// seed and resolves when the stream emits. Hand-written for the same reason as
/// [checklistRowByIdProvider].
final ProviderFamily<Checklist?, int> checklistByIdProvider = Provider
    .autoDispose
    .family<Checklist?, int>((ref, id) {
      // The authoritative reactive source, once it has emitted.
      final row = ref.watch(checklistRowByIdProvider(id)).value;
      if (row != null) return row;
      // First-frame seed (and loading fallback): the warm active-list row.
      for (final summary
          in ref.watch(activeChecklistsProvider).value ??
              const <ChecklistSummary>[]) {
        if (summary.checklist.id == id) return summary.checklist;
      }
      return null;
    });
