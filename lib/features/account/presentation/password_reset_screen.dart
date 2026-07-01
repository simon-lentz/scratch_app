import 'package:checkplan/core/result.dart';
import 'package:checkplan/features/account/application/auth_providers.dart';
import 'package:checkplan/features/account/application/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Requests a password-reset email; deep-link completion is device-tested.
class PasswordResetScreen extends ConsumerStatefulWidget {
  /// Creates the password-reset screen.
  const PasswordResetScreen({super.key});

  @override
  ConsumerState<PasswordResetScreen> createState() =>
      _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _email = TextEditingController();
  String? _error;
  var _busy = false;
  var _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reset password')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_sent)
          const Text(
            'If that email has an account, a reset link is on the way.',
          )
        else ...[
          TextField(
            key: const Key('email'),
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          if (_error case final message?)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: const Text('Send reset link'),
          ),
        ],
      ],
    ),
  );

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(_email.text.trim());
    if (!mounted) return;
    switch (result) {
      case Ok():
        setState(() => _sent = true);
      case Err(:final error):
        setState(() {
          _busy = false;
          _error = error is AuthFailure ? error.message : 'Could not send it';
        });
    }
  }
}
