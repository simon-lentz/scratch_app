import 'package:flutter_test/flutter_test.dart';
import '../../../support/a11y.dart';
import '../../../support/pump_settings_screen.dart';

void main() {
  testWidgets('Settings meets tap-target and labelled-tappable guidelines', (
    tester,
  ) async {
    await pumpSettingsScreen(tester);
    await expectMeetsTapTargetGuidelines(tester);
  });
}
