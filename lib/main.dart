import 'package:checkplan/app/app.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/core/observability/logging_provider_observer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// coverage:ignore-start
void main() {
  runApp(
    ProviderScope(
      observers: const [if (kDebugMode) LoggingProviderObserver()],
      overrides: [appDatabaseOverride()],
      child: const CheckPlanApp(),
    ),
  );
}

// coverage:ignore-end
