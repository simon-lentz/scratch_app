import 'package:checkplan/core/database/app_database.dart';
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
}
