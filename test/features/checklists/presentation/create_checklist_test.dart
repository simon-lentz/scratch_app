import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/pump_checklists_screen.dart';

void main() {
  testWidgets('FAB opens the dialog and creates a checklist', (tester) async {
    await pumpChecklistsScreen(tester);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Groceries');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Groceries'), findsOneWidget);
  });

  testWidgets('Add is disabled until the title is non-empty', (tester) async {
    await pumpChecklistsScreen(tester);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    final addButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Add'),
    );
    expect(addButton.onPressed, isNull); // disabled while empty
  });
}
