import 'package:checkplan/core/time/clock.dart';
import 'package:checkplan/core/time/current_day.dart';
import 'package:checkplan/core/time/epoch_day.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("currentDay is the EpochDay of the clock's local day", () {
    final container = ProviderContainer.test(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 6, 25, 9)),
      ],
    );
    expect(
      container.read(currentDayProvider),
      EpochDay.fromDateTime(DateTime(2026, 6, 25, 9)),
    );
  });

  testWidgets('currentDay rolls over at the local midnight boundary', (
    tester,
  ) async {
    var now = DateTime(2026, 6, 25, 23, 59, 59);
    final seen = <EpochDay>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [clockProvider.overrideWithValue(() => now)],
        child: Consumer(
          builder: (context, ref, _) {
            seen.add(ref.watch(currentDayProvider));
            return const SizedBox();
          },
        ),
      ),
    );
    final first = seen.last;

    // Advance the wall clock past midnight, then fire the armed timer.
    now = DateTime(2026, 6, 26, 0, 0, 1);
    await tester.pump(const Duration(minutes: 2));

    expect(seen.last.value, first.value + 1);
  });
}
