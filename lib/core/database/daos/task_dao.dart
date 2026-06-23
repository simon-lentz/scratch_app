import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/database/tables/checklists.dart';
import 'package:checkplan/core/database/tables/subtasks.dart';
import 'package:checkplan/core/database/tables/tasks.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:drift/drift.dart';

part 'task_dao.g.dart';

/// Reads and writes tasks, exposing reactive checklist and Today views.
@DriftAccessor(tables: [Tasks, Subtasks, Checklists])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  /// Binds the DAO to its attached database.
  TaskDao(super.attachedDatabase);

  /// A checklist's tasks ordered by position, each with subtask
  /// `(done, total)` counts.
  Stream<List<TaskView>> watchForChecklist(int checklistId) {
    final total = subtasks.id.count();
    final done = subtasks.id.count(filter: subtasks.isDone.equals(true));
    final query =
        select(tasks).join([
            // useColumns: false — read the counts, not the joined rows.
            leftOuterJoin(
              subtasks,
              subtasks.taskId.equalsExp(tasks.id),
              useColumns: false,
            ),
          ])
          ..addColumns([total, done])
          ..where(tasks.checklistId.equals(checklistId))
          ..groupBy([tasks.id])
          ..orderBy([OrderingTerm(expression: tasks.position)]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => TaskView(
              task: row.readTable(tasks),
              subtaskProgress: (row.read(done) ?? 0, row.read(total) ?? 0),
            ),
          )
          .toList(),
    );
  }

  /// Incomplete tasks due on or before `today`, partitioned into overdue
  /// (`dueDay < today`) and due-today (`dueDay == today`).
  ///
  /// `today` is a timezone-free [EpochDay], so the comparison is exact
  /// integer arithmetic.
  Stream<TodayBuckets> watchTodayBuckets(EpochDay today) {
    final query =
        select(tasks).join([
            innerJoin(checklists, checklists.id.equalsExp(tasks.checklistId)),
          ])
          ..where(
            tasks.isDone.equals(false) &
                tasks.dueDay.isNotNull() &
                tasks.dueDay.isSmallerOrEqualValue(today.value),
          )
          ..orderBy([OrderingTerm(expression: tasks.dueDay)]);

    return query.watch().map((rows) {
      final overdue = <TodayTask>[];
      final dueToday = <TodayTask>[];
      for (final row in rows) {
        final task = row.readTable(tasks);
        final entry = TodayTask(
          task: task,
          checklistTitle: row.readTable(checklists).title,
        );
        // dueDay is non-null here (guarded by the WHERE above).
        if (task.dueDay! < today.value) {
          overdue.add(entry);
        } else {
          dueToday.add(entry);
        }
      }
      return TodayBuckets(overdue: overdue, dueToday: dueToday);
    });
  }

  /// Adds a task to the checklist at the next free position.
  ///
  /// Allocating the position and inserting run in one transaction, so they are
  /// atomic.
  Future<int> add(int checklistId, String title) {
    return transaction(() async {
      final now = DateTime.timestamp();
      return into(tasks).insert(
        TasksCompanion.insert(
          checklistId: checklistId,
          title: title,
          position: await _nextPosition(checklistId),
          createdAt: now,
          updatedAt: now,
        ),
      );
    });
  }

  /// Sets the task's title and notes from the editor draft — a full write of
  /// the editable fields, not a patch.
  ///
  /// Passing `notes: null` clears the notes.
  Future<int> edit(int id, {required String title, String? notes}) =>
      (update(tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(
          title: Value(title),
          notes: Value(notes),
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
          dueDay: Value(dueDay?.value),
          updatedAt: Value(DateTime.timestamp()),
        ),
      );

  /// Hard-deletes the task, cascading to its subtasks.
  Future<int> deleteById(int id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();

  /// Rewrites positions within a checklist to match the given id order.
  Future<void> reorder(int checklistId, List<int> orderedIds) {
    final now = DateTime.timestamp();
    return batch((b) {
      for (final (index, id) in orderedIds.indexed) {
        b.update(
          tasks,
          TasksCompanion(position: Value(index), updatedAt: Value(now)),
          // Scope to the owning checklist: a stray foreign id can't be moved.
          where: (t) => t.id.equals(id) & t.checklistId.equals(checklistId),
        );
      }
    });
  }

  Future<int> _nextPosition(int checklistId) async {
    final maxPosition = tasks.position.max();
    final query = selectOnly(tasks)
      ..addColumns([maxPosition])
      ..where(tasks.checklistId.equals(checklistId));
    final row = await query.getSingleOrNull();
    return (row?.read(maxPosition) ?? -1) + 1;
  }
}
