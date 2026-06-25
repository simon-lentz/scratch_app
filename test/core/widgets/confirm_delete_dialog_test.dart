import 'package:checkplan/core/widgets/confirm_delete_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('returns true on confirm and false on cancel', (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async => result = await showConfirmDeleteDialog(
                context,
                title: 'Delete "X"?',
                message: 'Gone for good.',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    // Confirm path.
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(result, isTrue);

    // Cancel path.
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('uses a custom confirm label when given', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async => showConfirmDeleteDialog(
                context,
                title: 'Remove?',
                message: 'Bye.',
                confirmLabel: 'Remove',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Remove'), findsOneWidget);
  });
}
