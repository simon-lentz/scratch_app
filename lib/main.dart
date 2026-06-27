import 'package:checkplan/app/app.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// coverage:ignore-start
void main() {
  runApp(
    ProviderScope(
      overrides: [appDatabaseOverride()],
      child: const CheckPlanApp(),
    ),
  );
}

// coverage:ignore-end
