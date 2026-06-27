import 'package:checkplan/core/widgets/async_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, AsyncValue<List<int>> value) {
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: AsyncSwitcher<List<int>>(
            value: value,
            isEmpty: (items) => items.isEmpty,
            empty: const Text('Nothing here'),
            data: (items) => Text('count ${items.length}'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('a loading value shows a spinner', (tester) async {
    await _pump(tester, const AsyncLoading<List<int>>());
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('an empty value shows the empty widget', (tester) async {
    await _pump(tester, const AsyncData<List<int>>([]));
    await tester.pumpAndSettle();
    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('count 0'), findsNothing);
  });

  testWidgets('a non-empty value shows the data widget', (tester) async {
    await _pump(tester, const AsyncData<List<int>>([1, 2, 3]));
    await tester.pumpAndSettle();
    expect(find.text('count 3'), findsOneWidget);
  });

  testWidgets('an error shows the error view with a Retry button', (
    tester,
  ) async {
    await _pump(
      tester,
      AsyncError<List<int>>(Exception('boom'), StackTrace.empty),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Something went wrong'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
  });

  // The value-retaining loading case (an AsyncLoading carrying the previous
  // value must keep showing the data, not blank to a spinner) can't be built
  // synthetically — AsyncValue.copyWithPrevious is internal — so it is covered
  // end-to-end against a real provider invalidation in today_reload_test.dart.
}
