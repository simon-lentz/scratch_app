import 'package:checkplan/app/app.dart';
import 'package:checkplan/core/database/connection.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/core/database/summaries.dart';
import 'package:checkplan/features/checklists/application/checklist_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// coverage:ignore-start
void main() {
  runApp(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(openAppDatabase())],
      child: const CheckPlanApp(),
    ),
  );
}

/// Widget preview of [CheckPlanApp], backed by sample data rather than a
/// database: `NativeDatabase` pulls in `dart:ffi`, which is unavailable on
/// the `flutter build web` target, so it must stay out of `main.dart`.
@Preview(name: 'CheckPlanApp')
Widget previewCheckPlanApp() => ProviderScope(
  overrides: [
    activeChecklistsProvider.overrideWith(
      (ref) => Stream.value(const <ChecklistSummary>[]),
    ),
  ],
  child: const CheckPlanApp(),
);
// coverage:ignore-end
