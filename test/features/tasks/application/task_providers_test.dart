import 'package:checkplan/features/checklists/application/checklist_providers.dart';
import 'package:checkplan/features/tasks/application/task_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';

void main() {
  ProviderContainer makeContainer() =>
      ProviderContainer.test(overrides: [memoryDbOverride()]);

  test('tasksForChecklist starts empty for a fresh checklist', () async {
    final container = makeContainer();
    final id = await container.read(checklistDaoProvider).create('List');
    // An active listener keeps the autoDispose family read subscribed.
    container.listen(tasksForChecklistProvider(id), (_, _) {});
    final tasks = await container.read(tasksForChecklistProvider(id).future);
    expect(tasks, isEmpty);
  });

  test('a task added via the DAO appears in the read provider', () async {
    final container = makeContainer();
    final id = await container.read(checklistDaoProvider).create('Chores');
    await container.read(taskDaoProvider).add(id, 'Sweep');

    // Subscribe after the write so the first emission already reflects it.
    container.listen(tasksForChecklistProvider(id), (_, _) {});
    final tasks = await container.read(tasksForChecklistProvider(id).future);
    expect(tasks.single.task.title, 'Sweep');
    expect(tasks.single.subtaskProgress, (0, 0));
  });
}
