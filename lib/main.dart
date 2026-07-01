import 'package:checkplan/app/app.dart';
import 'package:checkplan/core/database/database_providers.dart';
import 'package:checkplan/core/observability/logging_provider_observer.dart';
import 'package:checkplan/features/account/application/auth_providers.dart';
import 'package:checkplan/features/account/application/auth_service.dart';
import 'package:checkplan/features/account/application/supabase_auth_service.dart';
import 'package:checkplan/features/settings/application/settings_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// coverage:ignore-start
Future<void> main() async {
  // Touching the database (and Supabase) resolves paths/keys via platform
  // channels, so the engine must be bound before the reads below — runApp would
  // otherwise be the first to do this.
  WidgetsFlutterBinding.ensureInitialized();

  // The real Supabase client when the build is configured (--dart-define), else
  // the local-only no-op so the app still runs and makes no network calls.
  final authService = await _resolveAuthService();

  // Resolve the persisted theme before the first frame so an explicit
  // (non-system) mode is honored immediately, with no cold-start flash. The
  // container built here backs the app below (via UncontrolledProviderScope),
  // so the same database serves this one-shot read and every later query — no
  // second open.
  final container = ProviderContainer(
    observers: const [if (kDebugMode) LoggingProviderObserver()],
    overrides: [
      appDatabaseOverride(),
      authServiceProvider.overrideWithValue(authService),
    ],
  );
  var initialThemeMode = ThemeMode.system;
  try {
    initialThemeMode = themeModeFromName(
      await container.read(settingsDaoProvider).getValue(themeModeKey),
    );
  } on Exception catch (_) {
    // A failed open (e.g. a corrupt file) must not block launch: fall back to
    // the system default and let the normal database-error view render once the
    // app's screens query the still-failing database.
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: CheckPlanApp(initialThemeMode: initialThemeMode),
    ),
  );
}

/// The real [SupabaseAuthService] when `SUPABASE_URL` +
/// `SUPABASE_PUBLISHABLE_KEY` are supplied via `--dart-define`; otherwise the
/// local-only [SignedOutAuthService] (no Supabase init, no network).
Future<AuthService> _resolveAuthService() async {
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  if (url.isEmpty || key.isEmpty) return const SignedOutAuthService();
  return SupabaseAuthService.initialize(url: url, publishableKey: key);
}

// coverage:ignore-end
