import 'package:checkplan/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CheckPlanApp shows the placeholder home, not the counter', (
    tester,
  ) async {
    await tester.pumpWidget(const CheckPlanApp());

    expect(find.text('CheckPlan'), findsWidgets); // app-bar title + body
    expect(find.byIcon(Icons.add), findsNothing); // the counter FAB is gone
    expect(find.text('0'), findsNothing);
  });
}
