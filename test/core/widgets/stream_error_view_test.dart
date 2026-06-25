import 'package:checkplan/core/widgets/stream_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the error description', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StreamErrorView(error: Exception('boom'))),
      ),
    );
    expect(find.textContaining('Something went wrong'), findsOneWidget);
    expect(find.textContaining('boom'), findsOneWidget);
  });
}
