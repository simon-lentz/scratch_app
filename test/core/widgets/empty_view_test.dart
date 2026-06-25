import 'package:checkplan/core/widgets/empty_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: EmptyView(message: 'Nothing')),
      ),
    );
    expect(find.text('Nothing'), findsOneWidget);
  });
}
