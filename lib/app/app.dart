import 'package:checkplan/app/router.dart';
import 'package:checkplan/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The root widget: a Material 3 app that owns and disposes its [GoRouter].
class CheckPlanApp extends StatefulWidget {
  /// Creates the root application widget.
  const CheckPlanApp({super.key});

  @override
  State<CheckPlanApp> createState() => _CheckPlanAppState();
}

class _CheckPlanAppState extends State<CheckPlanApp> {
  late final GoRouter _router = createAppRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CheckPlan',
      theme: lightTheme,
      darkTheme: darkTheme,
      routerConfig: _router,
    );
  }
}
