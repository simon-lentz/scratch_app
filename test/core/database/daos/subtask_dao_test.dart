import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/dao_support.dart';
import 'package:checkplan/core/database/daos/checklist_dao.dart';
import 'package:checkplan/core/database/daos/subtask_dao.dart';
import 'package:checkplan/core/database/daos/task_dao.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ChecklistDao checklists;
  late TaskDao tasks;
  late SubtaskDao subtasks;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    checklists = db.checklistDao;
    tasks = db.taskDao;
    subtasks = db.subtaskDao;
  });
  tearDown(() => db.close());

  Future<int> seedTask() async {
    final list = await checklists.create('List');
    return tasks.add(list, 'Parent task');
  }

  test('add then watchForTask re-emits with the new subtask', () async {
    final task = await seedTask();
    final expectation = expectLater(
      subtasks.watchForTask(task),
      // Initial empty snapshot races the awaited add(); assert the stream
      // emits through to the post-write state, not the first event.
      emitsThrough(
        predicate<List<Subtask>>(
          (l) => l.length == 1 && l.single.title == 'Step 1',
        ),
      ),
    );
    await subtasks.add(task, 'Step 1');
    await expectation;
  });

  test(
    'toggling all subtasks done does not change the parent task isDone',
    () async {
      final task = await seedTask();
      final s1 = await subtasks.add(task, 'a');
      final s2 = await subtasks.add(task, 'b');
      await subtasks.setDone(s1, isDone: true);
      await subtasks.setDone(s2, isDone: true);

      final parent = await (db.select(
        db.tasks,
      )..where((t) => t.id.equals(task))).getSingle();
      expect(parent.isDone, isFalse);

      final views = await tasks.watchForChecklist(parent.checklistId).first;
      expect(views.single.subtaskProgress, (2, 2));
    },
  );

  test('deleting a task cascades to its subtasks (FK pragma)', () async {
    final task = await seedTask();
    await subtasks.add(task, 'doomed');
    await tasks.deleteById(task);
    expect(await db.select(db.subtasks).get(), isEmpty);
  });

  test('rename changes the subtask title', () async {
    final task = await seedTask();
    final id = await subtasks.add(task, 'old');
    await subtasks.rename(id, 'new');

    expect((await subtasks.watchForTask(task).first).single.title, 'new');
  });

  test('deleteById removes only the targeted subtask', () async {
    final task = await seedTask();
    await subtasks.add(task, 'keep');
    final doomed = await subtasks.add(task, 'remove');
    await subtasks.deleteById(doomed);

    final titles = (await subtasks.watchForTask(task).first)
        .map((subtask) => subtask.title)
        .toList();
    expect(titles, ['keep']);
  });

  test('reorder rewrites subtask positions within the task', () async {
    final task = await seedTask();
    final a = await subtasks.add(task, 'a');
    final b = await subtasks.add(task, 'b');
    final c = await subtasks.add(task, 'c');
    await subtasks.reorder(task, [c, a, b]);

    final titles = (await subtasks.watchForTask(task).first)
        .map((subtask) => subtask.title)
        .toList();
    expect(titles, ['c', 'a', 'b']);
  });

  test('reorder rejects a partial id set', () async {
    final task = await seedTask();
    final a = await subtasks.add(task, 'a');
    await subtasks.add(task, 'b');
    await subtasks.add(task, 'c');
    // Omitting b and c would leave them colliding on stale positions.
    await expectLater(
      subtasks.reorder(task, [a]),
      throwsA(isA<ReorderConflict>()),
    );
  });
}
