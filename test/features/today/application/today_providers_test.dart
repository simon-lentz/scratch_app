import 'package:checkplan/core/time/current_day.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:checkplan/features/checklists/application/checklist_providers.dart';
import 'package:checkplan/features/tasks/application/task_providers.dart';
import 'package:checkplan/features/today/application/today_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';

void main() {
  test('todayProvider buckets seeded due tasks by the current day', () async {
    final today = EpochDay.fromDateTime(DateTime(2026, 6, 18));
    final container = ProviderContainer.test(
      overrides: [
        memoryDbOverride(),
        currentDayProvider.overrideWithValue(today),
      ],
    );

    final dao = container.read(taskDaoProvider);
    final list = await container.read(checklistDaoProvider).create('Errands');
    final overdue = await dao.add(list, 'overdue');
    final onToday = await dao.add(list, 'today');
    await dao.setDueDate(overdue, EpochDay.fromDateTime(DateTime(2026, 6, 17)));
    await dao.setDueDate(onToday, today);

    container.listen(todayProvider, (_, _) {}); // unpause the stream
    final buckets = await container.read(todayProvider.future);

    expect(buckets.overdue.map((t) => t.task.title), ['overdue']);
    expect(buckets.dueToday.map((t) => t.task.title), ['today']);
  });
}
