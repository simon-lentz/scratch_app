import 'package:checkplan/core/widgets/empty_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the message and the default icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: EmptyView(message: 'Nothing')),
      ),
    );
    expect(find.text('Nothing'), findsOneWidget);
    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
  });

  testWidgets('renders a given icon and action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyView(
            message: 'Empty',
            icon: Icons.event_available,
            action: FilledButton(onPressed: () {}, child: const Text('Add')),
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.event_available), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Add'), findsOneWidget);
  });
}
