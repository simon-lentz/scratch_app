import 'package:checkplan/core/time/epoch_day.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  EpochDay day(int y, int m, int d) => EpochDay.fromDateTime(DateTime(y, m, d));

  test('fromDateTime drops time-of-day, yielding a clean day index', () {
    final morning = EpochDay.fromDateTime(DateTime(2026, 6, 18, 0, 1));
    final evening = EpochDay.fromDateTime(DateTime(2026, 6, 18, 23, 59));
    expect(morning.value, evening.value);
    expect(day(2026, 6, 19).value - day(2026, 6, 18).value, 1);
  });

  test('toLocalDateTime round-trips to local midnight of the same day', () {
    final back = day(2026, 6, 18).toLocalDateTime();
    expect((back.year, back.month, back.day), (2026, 6, 18));
    expect((back.hour, back.minute), (0, 0));
  });

  test('comparison and subtraction operators match calendar order', () {
    expect(day(2026, 6, 17) < day(2026, 6, 18), isTrue);
    expect(day(2026, 6, 18) < day(2026, 6, 18), isFalse);
    expect(day(2026, 6, 18) - day(2026, 6, 17), 1);
    expect(day(2026, 6, 1) - day(2026, 6, 18), -17);
  });
}
