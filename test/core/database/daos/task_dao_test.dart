import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/daos/checklist_dao.dart';
import 'package:checkplan/core/database/daos/task_dao.dart';
import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ChecklistDao checklists;
  late TaskDao tasks;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    checklists = db.checklistDao;
    tasks = db.taskDao;
  });
  tearDown(() => db.close());

  EpochDay day(int y, int m, int d) => EpochDay.fromDateTime(DateTime(y, m, d));

  test(
    'add then watchForChecklist re-emits with the task and (0,0) progress',
    () async {
      final list = await checklists.create('List');
      final expectation = expectLater(
        tasks.watchForChecklist(list),
        // Initial empty snapshot races the awaited add(); assert the stream
        // emits through to the post-write state, not the first event.
        emitsThrough(
          predicate<List<TaskView>>(
            (views) =>
                views.length == 1 && views.single.subtaskProgress == (0, 0),
          ),
        ),
      );
      await tasks.add(list, 'Buy milk');
      await expectation;
    },
  );

  test('setDueDate places tasks into the correct Today buckets', () async {
    final list = await checklists.create('List');
    final today = day(2026, 6, 18);
    final yesterday = await tasks.add(list, 'overdue');
    final onToday = await tasks.add(list, 'today');
    final tomorrow = await tasks.add(list, 'upcoming');
    await tasks.setDueDate(yesterday, day(2026, 6, 17));
    await tasks.setDueDate(onToday, today);
    await tasks.setDueDate(tomorrow, day(2026, 6, 19));

    final buckets = await tasks.watchTodayBuckets(today).first;
    expect(buckets.overdue.map((t) => t.task.title), ['overdue']);
    expect(buckets.dueToday.map((t) => t.task.title), ['today']);
  });

  test('Today excludes done tasks and tasks with no due date', () async {
    final list = await checklists.create('List');
    final today = day(2026, 6, 18);
    final doneDue = await tasks.add(list, 'done');
    await tasks.setDueDate(doneDue, today);
    await tasks.setDone(doneDue, isDone: true);
    await tasks.add(list, 'no-date'); // dueDay stays null

    final buckets = await tasks.watchTodayBuckets(today).first;
    expect(buckets.overdue, isEmpty);
    expect(buckets.dueToday, isEmpty);
  });

  test('TodayTask carries the parent checklist title', () async {
    final list = await checklists.create('Errands');
    final today = day(2026, 6, 18);
    final t = await tasks.add(list, 'post office');
    await tasks.setDueDate(t, today);

    final buckets = await tasks.watchTodayBuckets(today).first;
    expect(buckets.dueToday.single.checklistTitle, 'Errands');
  });

  test('TodayTask carries its subtask (done, total) counts', () async {
    final list = await checklists.create('Errands');
    final today = day(2026, 6, 18);
    final t = await tasks.add(list, 'pack');
    await tasks.setDueDate(t, today);
    final first = await db.subtaskDao.add(t, 'shirts');
    await db.subtaskDao.add(t, 'shoes');
    await db.subtaskDao.setDone(first, isDone: true);

    final buckets = await tasks.watchTodayBuckets(today).first;
    expect(buckets.dueToday.single.subtaskProgress, (1, 2));
  });

  test('a Today task with no subtasks reports (0, 0) progress', () async {
    final list = await checklists.create('Errands');
    final today = day(2026, 6, 18);
    final t = await tasks.add(list, 'call');
    await tasks.setDueDate(t, today);

    final buckets = await tasks.watchTodayBuckets(today).first;
    expect(buckets.dueToday.single.subtaskProgress, (0, 0));
  });

  test('edit updates title and notes, then clears notes with null', () async {
    final list = await checklists.create('List');
    final id = await tasks.add(list, 'original');

    await tasks.edit(id, title: 'renamed', notes: 'some notes', dueDay: null);
    final edited = (await tasks.watchForChecklist(list).first).single;
    expect(edited.task.title, 'renamed');
    expect(edited.task.notes, 'some notes');

    // Omitting notes passes null: edit is a full write, so this clears them.
    await tasks.edit(id, title: 'renamed again', dueDay: null);
    final cleared = (await tasks.watchForChecklist(list).first).single;
    expect(cleared.task.title, 'renamed again');
    expect(cleared.task.notes, isNull);
  });

  test('reorder moves a task to the head, before its old first', () async {
    final list = await checklists.create('List');
    final a = await tasks.add(list, 'a');
    await tasks.add(list, 'b');
    final c = await tasks.add(list, 'c');
    // Move c to the front: nothing above it, a below it.
    await tasks.reorder(c, null, a);

    final titles = (await tasks.watchForChecklist(list).first)
        .map((view) => view.task.title)
        .toList();
    expect(titles, ['c', 'a', 'b']);
  });

  test(
    'reorder rebalances colliding ranks within the checklist scope only',
    () async {
      Future<List<String>> ranksOf(int checklistId) async =>
          (await tasks.watchForChecklist(checklistId).first)
              .map((view) => view.task.rank)
              .toList();

      final listA = await checklists.create('A');
      final listB = await checklists.create('B');
      final a1 = await tasks.add(listA, 'a1');
      final a2 = await tasks.add(listA, 'a2');
      final a3 = await tasks.add(listA, 'a3');
      await tasks.add(listB, 'b1');
      await tasks.add(listB, 'b2');
      final ranksBeforeB = await ranksOf(listB);

      // Collide a2 and a3 onto one rank, then drop a1 between them: the
      // rebalance must re-key listA only, leaving listB's ranks untouched.
      await (db.update(db.tasks)..where((t) => t.id.equals(a2))).write(
        const TasksCompanion(rank: Value('a1')),
      );
      await (db.update(db.tasks)..where((t) => t.id.equals(a3))).write(
        const TasksCompanion(rank: Value('a1')),
      );
      await tasks.reorder(a1, a2, a3);

      final viewsA = await tasks.watchForChecklist(listA).first;
      expect(viewsA.map((view) => view.task.title), ['a2', 'a1', 'a3']);
      expect(viewsA.map((view) => view.task.rank).toSet(), hasLength(3));
      expect(await ranksOf(listB), ranksBeforeB);
    },
  );

  test(
    'Today excludes tasks in archived checklists; restore brings them back',
    () async {
      final list = await checklists.create('List');
      final today = day(2026, 6, 18);
      final t = await tasks.add(list, 'due today');
      await tasks.setDueDate(t, today);

      var buckets = await tasks.watchTodayBuckets(today).first;
      expect(buckets.dueToday.map((e) => e.task.title), ['due today']);

      await checklists.archive(list);
      buckets = await tasks.watchTodayBuckets(today).first;
      expect(buckets.overdue, isEmpty);
      expect(buckets.dueToday, isEmpty);

      await checklists.restore(list);
      buckets = await tasks.watchTodayBuckets(today).first;
      expect(buckets.dueToday.map((e) => e.task.title), ['due today']);
    },
  );
}
