import 'package:checkplan/core/result.dart';
import 'package:checkplan/core/widgets/error_snackbar.dart';
import 'package:checkplan/features/account/presentation/account_section.dart';
import 'package:checkplan/features/settings/application/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App settings — an account section and the theme-mode selector; later UI
/// toggles extend it.
class SettingsScreen extends ConsumerStatefulWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // The optimistically-selected mode: set the instant a segment is tapped so
  // the highlight moves without waiting for the write to persist and the stream
  // to re-emit. Cleared once the persisted value catches up (in build), so the
  // store resumes as the source of truth for any later external change.
  ThemeMode? _pending;

  @override
  Widget build(BuildContext context) {
    final persisted = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    // Drop the optimistic override once the store reflects it, so a subsequent
    // change to the setting from elsewhere is honored again.
    if (_pending == persisted) _pending = null;
    final selected = _pending ?? persisted;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const AccountSection(),
          const Divider(),
          ListTile(
            title: const Text('Theme'),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('System')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ],
                selected: {selected},
                onSelectionChanged: (choice) => _setThemeMode(choice.first),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    // Reflect the choice immediately, then persist. On failure, roll the
    // optimistic highlight back to the stored value and surface the error.
    setState(() => _pending = mode);
    final result = await ref
        .read(settingsControllerProvider.notifier)
        .setThemeMode(mode);
    if (!mounted) return;
    if (result case Err()) {
      setState(() => _pending = null);
      showErrorSnackBar(context, 'Could not update the theme');
    }
  }
}
