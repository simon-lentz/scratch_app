import 'package:checkplan/core/widgets/name_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('returns the trimmed value on submit; disables submit on blank', (
    tester,
  ) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showNameDialog(
                  context,
                  title: 'New task',
                  submitLabel: 'Add',
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Blank → Add disabled.
    final addButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Add'),
    );
    expect(addButton.onPressed, isNull);

    await tester.enterText(find.byType(TextField), '  Sweep  ');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(result, 'Sweep');
  });
}
