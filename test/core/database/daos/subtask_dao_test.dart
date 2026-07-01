import 'package:checkplan/core/database/app_database.dart';
import 'package:checkplan/core/database/daos/checklist_dao.dart';
import 'package:checkplan/core/database/daos/subtask_dao.dart';
import 'package:checkplan/core/database/daos/task_dao.dart';
import 'package:drift/drift.dart' show Value;
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

  Future<Task> readTask(int id) =>
      (db.select(db.tasks)..where((t) => t.id.equals(id))).getSingle();

  test('completing the last subtask auto-completes the parent', () async {
    final task = await seedTask();
    final s1 = await subtasks.add(task, 'a');
    final s2 = await subtasks.add(task, 'b');

    await subtasks.setDone(s1, isDone: true);
    expect((await readTask(task)).isDone, isFalse); // not all done yet

    await subtasks.setDone(s2, isDone: true);
    expect((await readTask(task)).isDone, isTrue); // last completed -> done

    final views = await tasks
        .watchForChecklist(
          (await readTask(task)).checklistId,
        )
        .first;
    expect(views.single.subtaskProgress, (2, 2));
  });

  test('unchecking a subtask reopens an auto-completed parent', () async {
    final task = await seedTask();
    final s1 = await subtasks.add(task, 'a');
    await subtasks.setDone(s1, isDone: true);
    expect((await readTask(task)).isDone, isTrue); // only subtask done -> done

    await subtasks.setDone(s1, isDone: false);
    expect(
      (await readTask(task)).isDone,
      isFalse,
    ); // an open subtask reopens it
  });

  test('adding an open subtask reopens an auto-completed parent', () async {
    final task = await seedTask();
    final s1 = await subtasks.add(task, 'a');
    await subtasks.setDone(s1, isDone: true);
    expect((await readTask(task)).isDone, isTrue); // auto-completed

    await subtasks.add(task, 'b'); // a new open subtask
    expect((await readTask(task)).isDone, isFalse); // reopened
  });

  test('deleting the last open subtask completes the parent', () async {
    final task = await seedTask();
    final done = await subtasks.add(task, 'done');
    final open = await subtasks.add(task, 'open');
    await subtasks.setDone(done, isDone: true);
    expect((await readTask(task)).isDone, isFalse); // 'open' still open

    await subtasks.deleteById(open); // last open removed; 'done' remains
    expect((await readTask(task)).isDone, isTrue); // all remaining done -> done
  });

  test('deleting the only subtask does not complete the parent', () async {
    final task = await seedTask();
    final only = await subtasks.add(task, 'only');

    await subtasks.deleteById(only); // zero subtasks left -> manual territory
    expect((await readTask(task)).isDone, isFalse); // unchanged
  });

  test('re-completing an already-done parent issues no write', () async {
    final task = await seedTask();
    final s1 = await subtasks.add(task, 'a');
    await subtasks.setDone(s1, isDone: true); // parent auto-completes
    final before = await readTask(task);

    // Re-complete the already-done subtask: the parent is already done, so the
    // reconcile must not re-write it (no spurious updatedAt bump / re-emit).
    await subtasks.setDone(s1, isDone: true);
    expect((await readTask(task)).updatedAt, before.updatedAt);
  });

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

  test('reorder moves a subtask to the head, before its old first', () async {
    final task = await seedTask();
    final a = await subtasks.add(task, 'a');
    await subtasks.add(task, 'b');
    final c = await subtasks.add(task, 'c');
    // Move c to the front: nothing above it, a below it.
    await subtasks.reorder(c, null, a);

    final titles = (await subtasks.watchForTask(task).first)
        .map((subtask) => subtask.title)
        .toList();
    expect(titles, ['c', 'a', 'b']);
  });

  test(
    'reorder rebalances colliding ranks within the task scope only',
    () async {
      Future<List<String>> ranksOf(int taskId) async =>
          (await subtasks.watchForTask(taskId).first)
              .map((subtask) => subtask.rank)
              .toList();

      final taskA = await seedTask();
      final list = (await readTask(taskA)).checklistId;
      final taskB = await tasks.add(list, 'Other task');
      final a1 = await subtasks.add(taskA, 'a1');
      final a2 = await subtasks.add(taskA, 'a2');
      final a3 = await subtasks.add(taskA, 'a3');
      await subtasks.add(taskB, 'b1');
      await subtasks.add(taskB, 'b2');
      final ranksBeforeB = await ranksOf(taskB);

      // Collide a2 and a3 onto one rank, then drop a1 between them: the
      // rebalance must re-key taskA's subtasks only, leaving taskB's untouched.
      await (db.update(db.subtasks)..where((s) => s.id.equals(a2))).write(
        const SubtasksCompanion(rank: Value('a1')),
      );
      await (db.update(db.subtasks)..where((s) => s.id.equals(a3))).write(
        const SubtasksCompanion(rank: Value('a1')),
      );
      await subtasks.reorder(a1, a2, a3);

      final rowsA = await subtasks.watchForTask(taskA).first;
      expect(rowsA.map((subtask) => subtask.title), ['a2', 'a1', 'a3']);
      expect(rowsA.map((subtask) => subtask.rank).toSet(), hasLength(3));
      expect(await ranksOf(taskB), ranksBeforeB);
    },
  );
}
