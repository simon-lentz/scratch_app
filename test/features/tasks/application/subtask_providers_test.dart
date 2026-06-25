import 'package:checkplan/core/result.dart';
import 'package:checkplan/features/checklists/application/checklist_providers.dart';
import 'package:checkplan/features/tasks/application/subtask_providers.dart';
import 'package:checkplan/features/tasks/application/task_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer.test(overrides: [memoryDbOverride()]);
  });

  SubtaskController controller() =>
      container.read(subtaskControllerProvider.notifier);

  Future<int> seedTask() async {
    final list = await container.read(checklistDaoProvider).create('L');
    return container.read(taskDaoProvider).add(list, 'Task');
  }

  test('add then the read provider lists the subtask', () async {
    final task = await seedTask();
    final result = await controller().add(task, '  Step  ');
    expect(result, isA<Ok<int>>());
    container.listen(subtasksForTaskProvider(task), (_, _) {});
    final subtasks = await container.read(subtasksForTaskProvider(task).future);
    expect(subtasks.single.title, 'Step');
  });

  test('add rejects a blank title', () async {
    final task = await seedTask();
    final result = await controller().add(task, '  ');
    expect(result, isA<Err<int>>());
  });

  test('setDone toggles; delete removes', () async {
    final task = await seedTask();
    final id = ((await controller().add(task, 'Step')) as Ok<int>).value;
    final dao = container.read(subtaskDaoProvider);
    await controller().setDone(id, isDone: true);
    expect((await dao.watchForTask(task).first).single.isDone, true);
    await controller().delete(id);
    expect(await dao.watchForTask(task).first, isEmpty);
  });
}
