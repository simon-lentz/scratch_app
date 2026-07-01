import 'package:checkplan/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'memory_db.dart';

/// Pumps [SettingsScreen] inside a `ProviderScope` + `MaterialApp`, then
/// settles.
///
/// Backs it with a fresh in-memory database via [memoryDbOverride] (the
/// container owns and closes it). Extra [overrides] layer on top — e.g. a fake
/// controller for the write-failure test.
Future<void> pumpSettingsScreen(
  WidgetTester tester, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [memoryDbOverride(), ...overrides],
      child: const MaterialApp(home: SettingsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}
