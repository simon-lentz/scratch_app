import 'package:checkplan/core/model/due_status.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = EpochDay.fromDateTime(DateTime(2026, 6, 25, 9));

  test('null dueDay is NoDueDate', () {
    expect(dueStatusFor(null, today), isA<NoDueDate>());
  });

  test('a past day is Overdue by the day count', () {
    final status = dueStatusFor(today.value - 3, today);
    expect(status, isA<Overdue>());
    expect((status as Overdue).days, 3);
  });

  test('today is DueToday', () {
    expect(dueStatusFor(today.value, today), isA<DueToday>());
  });

  test('a future day is Upcoming on that day', () {
    final status = dueStatusFor(today.value + 2, today);
    expect(status, isA<Upcoming>());
    expect((status as Upcoming).on, EpochDay(today.value + 2));
  });

  test('describe labels each status', () {
    expect(describe(const NoDueDate()), 'No date');
    expect(describe(const Overdue(3)), 'Overdue 3d');
    expect(describe(const DueToday()), 'Today');
    expect(describe(Upcoming(EpochDay(today.value + 2))), 'Due 6/27');
  });
}
