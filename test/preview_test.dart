import 'package:checkplan/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('preview renders its seeded sample checklists', (tester) async {
    await tester.pumpWidget(previewCheckPlanApp());
    await tester.pumpAndSettle();
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('2/5'), findsOneWidget); // seeded progress renders the bar
  });

  testWidgets('preview FAB creates a checklist instead of crashing', (
    tester,
  ) async {
    await tester.pumpWidget(previewCheckPlanApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'New list');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    // Used to hit the throw-only appDatabaseProvider and raise an
    // UnimplementedError; now it drives the in-memory preview store.
    expect(find.text('New list'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('preview opens a checklist detail with interactive tasks', (
    tester,
  ) async {
    await tester.pumpWidget(previewCheckPlanApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Groceries'));
    await tester.pumpAndSettle();

    // The detail route renders its seeded tasks (not the throw-only DB error).
    expect(find.text('Apples'), findsOneWidget);
    expect(find.text('Bread'), findsOneWidget);
    expect(find.textContaining('Something went wrong'), findsNothing);

    // A write drives the in-memory store, never the throw-only
    // appDatabaseProvider, so toggling a task raises nothing.
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
