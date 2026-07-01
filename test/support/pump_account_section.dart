import 'package:checkplan/features/account/application/auth_providers.dart';
import 'package:checkplan/features/account/presentation/account_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'fake_auth_service.dart';

/// Pumps [AccountSection] with `authServiceProvider` overridden by [fake] (or a
/// fresh signed-out fake), then settles.
///
/// These tests assert render + sign-out only; navigation to the auth screens is
/// covered by the full-app auth navigation test, so a plain `MaterialApp`
/// suffices (the signed-out arm's push buttons are never tapped here).
Future<void> pumpAccountSection(
  WidgetTester tester, {
  FakeAuthService? fake,
  List<Override> extra = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(fake ?? FakeAuthService()),
        ...extra,
      ],
      child: const MaterialApp(home: Scaffold(body: AccountSection())),
    ),
  );
  await tester.pumpAndSettle();
}
