import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

// coverage:ignore-start
void main() {
  runApp(const CheckPlanApp());
}

/// Widget preview of [CheckPlanApp] for Flutter's widget previewer
/// (`flutter widget-preview start`).
@Preview(name: 'CheckPlanApp')
Widget previewCheckPlanApp() => const CheckPlanApp();
// coverage:ignore-end

/// The root widget of the application.
class CheckPlanApp extends StatelessWidget {
  /// Creates the root application widget.
  const CheckPlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CheckPlan',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.indigo)),
      home: const HomePlaceholder(),
    );
  }
}

/// Temporary home shown until the real Lists screen lands.
class HomePlaceholder extends StatelessWidget {
  /// Creates the placeholder home.
  const HomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CheckPlan')),
      body: const Center(child: Text('CheckPlan')),
    );
  }
}
