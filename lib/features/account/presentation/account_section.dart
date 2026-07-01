import 'dart:async';

import 'package:checkplan/core/result.dart';
import 'package:checkplan/core/widgets/error_snackbar.dart';
import 'package:checkplan/features/account/application/auth_providers.dart';
import 'package:checkplan/features/account/application/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The account tiles at the top of Settings.
///
/// Signed out, it invites sign-in; signed in, it shows the account email and a
/// Sign out action. Backup, restore, and sync-status controls come later.
class AccountSection extends ConsumerWidget {
  /// Creates the account section.
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(authStateProvider).value ?? const SignedOut();
    return switch (snapshot) {
      SignedOut() => const _SignedOut(),
      SignedIn(:final email) => _SignedIn(email: email),
    };
  }
}

class _SignedOut extends StatelessWidget {
  const _SignedOut();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const ListTile(
        leading: Icon(Icons.cloud_off_outlined),
        title: Text('Not backed up'),
        subtitle: Text(
          'Your checklists live on this device only. Sign in to enable '
          'cloud backup.',
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: FilledButton(
          onPressed: () => unawaited(context.push('/sign-in')),
          child: const Text('Sign in'),
        ),
      ),
      TextButton(
        onPressed: () => unawaited(context.push('/sign-up')),
        child: const Text('Create account'),
      ),
    ],
  );
}

class _SignedIn extends ConsumerWidget {
  const _SignedIn({required this.email});

  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(
    leading: const Icon(Icons.cloud_done_outlined),
    title: Text(email),
    subtitle: const Text('Signed in'),
    trailing: TextButton(
      onPressed: () => unawaited(_signOut(context, ref)),
      child: const Text('Sign out'),
    ),
  );

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(authControllerProvider.notifier).signOut();
    if (!context.mounted) return;
    if (result case Err()) {
      showErrorSnackBar(context, 'Could not sign out');
    }
  }
}
