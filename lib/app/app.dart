import 'package:checkplan/app/router.dart';
import 'package:checkplan/app/theme.dart';
import 'package:checkplan/features/settings/application/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The root widget: a Material 3 app that owns and disposes its [GoRouter] and
/// follows the persisted theme mode.
class CheckPlanApp extends ConsumerStatefulWidget {
  /// Creates the root application widget.
  const CheckPlanApp({super.key});

  @override
  ConsumerState<CheckPlanApp> createState() => _CheckPlanAppState();
}

class _CheckPlanAppState extends ConsumerState<CheckPlanApp> {
  late final GoRouter _router = createAppRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Until the persisted mode's stream first emits, use the system default —
    // the app's prior behaviour — so there's no flash for the common case.
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    return MaterialApp.router(
      title: 'CheckPlan',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}
