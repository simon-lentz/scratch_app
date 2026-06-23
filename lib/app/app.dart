import 'package:checkplan/app/router.dart';
import 'package:checkplan/app/theme.dart';
import 'package:flutter/material.dart';

/// The root widget: a Material 3 app driven by [appRouter].
class CheckPlanApp extends StatelessWidget {
  /// Creates the root application widget.
  const CheckPlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CheckPlan',
      theme: lightTheme,
      darkTheme: darkTheme,
      routerConfig: appRouter,
    );
  }
}
