import 'package:checkplan/core/widgets/labeled_checkbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders a Checkbox carrying the value and the semantic label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LabeledCheckbox(
            label: 'Toggle "Milk" done',
            value: true,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    expect(
      tester.getSemantics(find.byType(Checkbox)).label,
      'Toggle "Milk" done',
    );
    handle.dispose();
  });

  testWidgets('toggling fires onChanged with the new (non-null) value', (
    tester,
  ) async {
    bool? toggled;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LabeledCheckbox(
            label: 'Toggle "Milk" done',
            value: false,
            onChanged: (value) => toggled = value,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(Checkbox));
    expect(toggled, isTrue);
  });
}
