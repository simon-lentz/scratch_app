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

  test('fromDateTime rejects a UTC DateTime', () {
    // The civil date is read from the DateTime's components, so a UTC value
    // would yield the UTC day, not the user's local one.
    expect(
      () => EpochDay.fromDateTime(DateTime.utc(2026, 6, 18)),
      throwsA(isA<AssertionError>()),
    );
  });

  test('toLocalDateTime yields local noon of the same day (DST-safe)', () {
    final back = day(2026, 6, 18).toLocalDateTime();
    expect((back.year, back.month, back.day), (2026, 6, 18));
    // Noon, not midnight: a DST transition can skip local midnight (advancing
    // it to 01:00 and risking date/time drift), but never local noon.
    expect((back.hour, back.minute), (12, 0));
  });

  test('comparison and subtraction operators match calendar order', () {
    expect(day(2026, 6, 17) < day(2026, 6, 18), isTrue);
    expect(day(2026, 6, 18) < day(2026, 6, 18), isFalse);
    expect(day(2026, 6, 18) - day(2026, 6, 17), 1);
    expect(day(2026, 6, 1) - day(2026, 6, 18), -17);
  });

  test('<=, >, and >= match calendar order', () {
    final earlier = day(2026, 6, 17);
    final later = day(2026, 6, 18);
    expect(earlier <= later, isTrue);
    expect(later <= later, isTrue);
    expect(later <= earlier, isFalse);
    expect(later > earlier, isTrue);
    expect(earlier > later, isFalse);
    expect(later >= later, isTrue);
    expect(later >= earlier, isTrue);
    expect(earlier >= later, isFalse);
  });
}
