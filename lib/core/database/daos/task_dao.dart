import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/dao_support.dart';
import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/database/tables/checklists.dart';
import 'package:checkplan/core/database/tables/subtasks.dart';
import 'package:checkplan/core/database/tables/tasks.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:drift/drift.dart';

part 'task_dao.g.dart';

/// Reads and writes tasks, exposing reactive checklist and Today views.
@DriftAccessor(tables: [Tasks, Subtasks, Checklists])
class TaskDao extends DatabaseAccessor<AppDatabase>
    with _$TaskDaoMixin, PositioningDao {
  /// Binds the DAO to its attached database.
  TaskDao(super.attachedDatabase);

  /// A checklist's tasks ordered by `rank` (id as a stable tiebreaker),
  /// each with subtask `(done, total)` counts.
  Stream<List<TaskView>> watchForChecklist(int checklistId) {
    final query = select(tasks).join([
      // useColumns: false — read the counts, not the joined rows.
      leftOuterJoin(
        subtasks,
        subtasks.taskId.equalsExp(tasks.id),
        useColumns: false,
      ),
    ]);
    final readProgress = addProgressCounts(query, subtasks.id, subtasks.isDone);
    query
      ..where(tasks.checklistId.equals(checklistId))
      ..groupBy([tasks.id])
      ..orderBy([
        OrderingTerm(expression: tasks.rank),
        OrderingTerm(expression: tasks.id),
      ]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => TaskView(
              task: row.readTable(tasks),
              subtaskProgress: readProgress(row),
            ),
          )
          .toList(),
    );
  }

  /// Incomplete tasks in non-archived checklists due on or before `today`,
  /// partitioned into overdue (`dueDay < today`) and due-today
  /// (`dueDay == today`).
  ///
  /// `today` must be the device's current **local** calendar day as an
  /// [EpochDay]; stored `dueDay`s are also local calendar days, so the
  /// comparison is exact integer arithmetic. Tasks in archived checklists are
  /// excluded — an archived list is hidden everywhere, Today included.
  Stream<TodayBuckets> watchTodayBuckets(EpochDay today) {
    final query = select(tasks).join([
      // useColumns: false — only the checklist title (added below) and the
      // subtask counts are read, not the joined rows themselves.
      innerJoin(
        checklists,
        checklists.id.equalsExp(tasks.checklistId),
        useColumns: false,
      ),
      leftOuterJoin(
        subtasks,
        subtasks.taskId.equalsExp(tasks.id),
        useColumns: false,
      ),
    ]);
    final readProgress = addProgressCounts(query, subtasks.id, subtasks.isDone);
    query
      ..addColumns([checklists.title])
      ..where(
        tasks.isDone.equals(false) &
            tasks.dueDay.isNotNull() &
            tasks.dueDay.isSmallerOrEqualValue(today.value) &
            checklists.archivedAt.isNull(),
      )
      ..groupBy([tasks.id])
      ..orderBy([
        OrderingTerm(expression: tasks.dueDay),
        OrderingTerm(expression: tasks.id),
      ]);

    return query.watch().map((rows) {
      final overdue = <TodayTask>[];
      final dueToday = <TodayTask>[];
      for (final row in rows) {
        final task = row.readTable(tasks);
        final entry = TodayTask(
          task: task,
          // Non-null: inner join on a NOT NULL column.
          checklistTitle: row.read(checklists.title)!,
          subtaskProgress: readProgress(row),
        );
        // dueDay is non-null here (guarded by the WHERE above).
        if (task.dueDay! < today) {
          overdue.add(entry);
        } else {
          dueToday.add(entry);
        }
      }
      return TodayBuckets(overdue: overdue, dueToday: dueToday);
    });
  }

  /// Adds a task to the checklist at the tail of its order.
  ///
  /// Allocating the rank and inserting run in one transaction, so they are
  /// atomic.
  Future<int> add(int checklistId, String title) {
    return transaction(() async {
      final now = DateTime.timestamp();
      return into(tasks).insert(
        TasksCompanion.insert(
          checklistId: checklistId,
          title: title,
          rank: await nextRank(
            tasks,
            tasks.rank,
            where: tasks.checklistId.equals(checklistId),
          ),
          createdAt: now,
          updatedAt: now,
        ),
      );
    });
  }

  /// Sets the task's title, notes, and due date from the editor draft — a full
  /// write of the editable fields, not a patch.
  ///
  /// Passing `notes: null` clears the notes;
  /// `dueDay: null` clears the due date.
  Future<int> edit(
    int id, {
    required String title,
    required EpochDay? dueDay,
    String? notes,
  }) => (update(tasks)..where((t) => t.id.equals(id))).write(
    TasksCompanion(
      title: Value(title),
      notes: Value(notes),
      dueDay: Value(dueDay),
      updatedAt: Value(DateTime.timestamp()),
    ),
  );

  /// Sets the task's own completion flag.
  Future<int> setDone(int id, {required bool isDone}) =>
      (update(tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(
          isDone: Value(isDone),
          updatedAt: Value(DateTime.timestamp()),
        ),
      );

  /// Sets or clears the task's due date (a timezone-free [EpochDay]).
  Future<int> setDueDate(int id, EpochDay? dueDay) =>
      (update(tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(
          dueDay: Value(dueDay),
          updatedAt: Value(DateTime.timestamp()),
        ),
      );

  /// Hard-deletes the task, cascading to its subtasks.
  Future<int> deleteById(int id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();

  /// Re-ranks the moved task between its new neighbours (null = list end).
  Future<void> reorder(int movedId, int? beforeId, int? afterId) =>
      reorderByRank(
        tasks,
        movedId: movedId,
        beforeId: beforeId,
        afterId: afterId,
        idColumn: tasks.id,
        rankColumn: tasks.rank,
        rowFor: (rank, now) =>
            TasksCompanion(rank: Value(rank), updatedAt: Value(now)),
      );
}
