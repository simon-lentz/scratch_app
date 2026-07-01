import 'package:checkplan/core/result.dart';
import 'package:checkplan/features/settings/application/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../support/memory_db.dart';

void main() {
  group('theme-mode name mapping', () {
    test('round-trips every mode', () {
      for (final mode in ThemeMode.values) {
        expect(themeModeFromName(themeModeName(mode)), mode);
      }
    });

    test('an unknown or null name defaults to system', () {
      expect(themeModeFromName(null), ThemeMode.system);
      expect(themeModeFromName('bogus'), ThemeMode.system);
    });
  });

  group('providers', () {
    late ProviderContainer container;
    setUp(() {
      container = ProviderContainer.test(overrides: [memoryDbOverride()]);
    });

    test('themeMode defaults to system on an empty store', () async {
      // An active listener keeps the StreamProvider subscribed; Riverpod pauses
      // a provider once its last listener goes, stranding `.future` in loading.
      // ProviderContainer.test disposes the listener at test end.
      container.listen(themeModeProvider, (_, _) {});
      expect(await container.read(themeModeProvider.future), ThemeMode.system);
    });

    test('setThemeMode persists and themeMode reflects it', () async {
      final result = await container
          .read(settingsControllerProvider.notifier)
          .setThemeMode(ThemeMode.dark);
      expect(result, isA<Ok<void>>());
      // Subscribe after the write so this fresh subscription's first emission
      // already reflects it, and the retained listener keeps the provider
      // active so `.future` resolves rather than pausing in loading.
      container.listen(themeModeProvider, (_, _) {});
      expect(await container.read(themeModeProvider.future), ThemeMode.dark);
    });
  });
}
