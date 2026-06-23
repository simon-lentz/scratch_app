import 'package:checkplan/core/database/daos/checklist_dao.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/core/database/summaries.dart';
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
