import 'package:flutter_test/flutter_test.dart';

/// Asserts the currently-pumped UI meets the tap-target and labelled-tappable
/// accessibility guidelines.
///
/// Enables semantics for the check and disposes the handle in a `finally`, so a
/// failing guideline still releases it — the guideline failure, not a leaked
/// [SemanticsHandle] error, is what surfaces. (Flutter verifies handle disposal
/// before `addTearDown` callbacks run, so the handle must be released within
/// the test body.)
Future<void> expectMeetsTapTargetGuidelines(WidgetTester tester) async {
  final handle = tester.ensureSemantics();
  try {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  } finally {
    handle.dispose();
  }
}
