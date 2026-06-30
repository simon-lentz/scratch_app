import 'package:checkplan/core/database/dao_support.dart';
import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/core/result.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:checkplan/core/validation.dart';
import 'package:checkplan/features/checklists/application/checklist_providers.dart';
import 'package:checkplan/features/tasks/application/task_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer.test(overrides: [memoryDbOverride()]);
  });

  TaskController controller() =>
      container.read(taskControllerProvider.notifier);

  Future<int> seedChecklist() =>
      container.read(checklistDaoProvider).create('List');

  Future<TaskView> onlyTask(int checklistId) async =>
      (await container
              .read(taskDaoProvider)
              .watchForChecklist(checklistId)
              .first)
          .single;

  Future<List<String>> titles(int checklistId) async {
    final tasks = await container
        .read(taskDaoProvider)
        .watchForChecklist(checklistId)
        .first;
    return tasks.map((t) => t.task.title).toList();
  }

  test('add returns Ok with the id and trims the title', () async {
    final list = await seedChecklist();
    final result = await controller().add(list, '  Sweep  ');
    expect(result, isA<Ok<int>>());
    expect(await titles(list), ['Sweep']);
  });

  test('add rejects a blank title at the controller boundary', () async {
    final list = await seedChecklist();
    final result = await controller().add(list, '   ');
    expect(result, isA<Err<int>>());
    expect((result as Err<int>).error, isA<ValidationException>());
  });

  test('edit updates title and clears notes with null', () async {
    final list = await seedChecklist();
    final id = ((await controller().add(list, 'Old')) as Ok<int>).value;
    await controller().edit(id, title: 'New', notes: 'note', dueDay: null);
    var task = (await onlyTask(list)).task;
    expect(task.title, 'New');
    expect(task.notes, 'note');
    await controller().edit(id, title: 'New', dueDay: null);
    task = (await onlyTask(list)).task;
    expect(task.notes, isNull);
  });

  test('edit rejects a blank title at the controller boundary', () async {
    final list = await seedChecklist();
    final id = ((await controller().add(list, 'Old')) as Ok<int>).value;
    final result = await controller().edit(id, title: '   ', dueDay: null);
    expect(result, isA<Err<void>>());
    expect((result as Err<void>).error, isA<ValidationException>());
  });

  test('setDone toggles the task flag', () async {
    final list = await seedChecklist();
    final id = ((await controller().add(list, 'Task')) as Ok<int>).value;
    await controller().setDone(id, isDone: true);
    expect((await onlyTask(list)).task.isDone, true);
  });

  test('delete removes the task', () async {
    final list = await seedChecklist();
    final id = ((await controller().add(list, 'Doomed')) as Ok<int>).value;
    await controller().delete(id);
    expect(await titles(list), isEmpty);
  });

  test('reorder changes the order', () async {
    final list = await seedChecklist();
    final a = ((await controller().add(list, 'A')) as Ok<int>).value;
    final b = ((await controller().add(list, 'B')) as Ok<int>).value;
    await controller().reorder(list, [b, a]);
    expect(await titles(list), ['B', 'A']);
  });

  test('reorder with a stale id set returns Err(ReorderConflict)', () async {
    final list = await seedChecklist();
    final a = ((await controller().add(list, 'A')) as Ok<int>).value;
    await controller().add(list, 'B'); // omitted from the set below
    final result = await controller().reorder(list, [a]);
    expect(result, isA<Err<void>>());
    expect((result as Err<void>).error, isA<ReorderConflict>());
  });

  test('edit sets and then clears the due date', () async {
    final list = await seedChecklist();
    final id = ((await controller().add(list, 'Task')) as Ok<int>).value;
    final due = EpochDay.fromDateTime(DateTime(2026, 6, 18));
    await controller().edit(id, title: 'Task', dueDay: due);
    expect((await onlyTask(list)).task.dueDay, due);
    await controller().edit(id, title: 'Task', dueDay: null);
    expect((await onlyTask(list)).task.dueDay, isNull);
  });
}
