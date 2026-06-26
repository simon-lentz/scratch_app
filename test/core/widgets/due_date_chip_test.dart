import 'package:checkplan/core/model/due_status.dart';
import 'package:checkplan/core/widgets/due_date_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the status label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: DueDateChip(status: Overdue(2))),
      ),
    );
    expect(find.text('Overdue 2d'), findsOneWidget);
  });
}
