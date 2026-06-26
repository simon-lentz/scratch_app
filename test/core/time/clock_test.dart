import 'package:checkplan/core/time/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clockProvider returns a working clock (DateTime.now by default)', () {
    final container = ProviderContainer.test();
    final before = DateTime.now();
    final now = container.read(clockProvider)();
    expect(now.isBefore(before.subtract(const Duration(minutes: 1))), isFalse);
  });

  test('an overridden clock returns its fixed local time', () {
    final fixed = DateTime(2026, 6, 25, 9);
    final container = ProviderContainer.test(
      overrides: [clockProvider.overrideWithValue(() => fixed)],
    );
    expect(container.read(clockProvider)(), fixed);
  });
}
