import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/dao_support.dart';
import 'package:checkplan/core/database/daos/checklist_dao.dart';
import 'package:checkplan/core/database/daos/task_dao.dart';
import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/time/epoch_day.dart';
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

  test('reorder rewrites task positions within the checklist', () async {
    final list = await checklists.create('List');
    final a = await tasks.add(list, 'a');
    final b = await tasks.add(list, 'b');
    final c = await tasks.add(list, 'c');
    await tasks.reorder(list, [c, a, b]);

    final titles = (await tasks.watchForChecklist(list).first)
        .map((view) => view.task.title)
        .toList();
    expect(titles, ['c', 'a', 'b']);
  });

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

  test('reorder rejects a partial id set', () async {
    final list = await checklists.create('List');
    final a = await tasks.add(list, 'a');
    await tasks.add(list, 'b');
    await tasks.add(list, 'c');
    // Omitting b and c would leave them colliding on stale positions.
    await expectLater(
      tasks.reorder(list, [a]),
      throwsA(isA<ReorderConflict>()),
    );
  });
}
