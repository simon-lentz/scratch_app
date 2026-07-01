import 'dart:async';

import 'package:checkplan/core/result.dart';
import 'package:checkplan/features/account/application/auth_providers.dart';
import 'package:checkplan/features/account/application/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Email + password sign-in, with links to create-account and reset.
class SignInScreen extends ConsumerStatefulWidget {
  /// Creates the sign-in screen.
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  var _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sign in')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          key: const Key('email'),
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        TextField(
          key: const Key('password'),
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
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
          child: const Text('Sign in'),
        ),
        TextButton(
          onPressed: () => unawaited(context.push('/sign-up')),
          child: const Text('Create account'),
        ),
        TextButton(
          onPressed: () => unawaited(context.push('/reset-password')),
          child: const Text('Forgot password?'),
        ),
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
        .signIn(_email.text.trim(), _password.text);
    if (!mounted) return;
    switch (result) {
      case Ok():
        if (context.canPop()) context.pop();
      case Err(:final error):
        setState(() {
          _busy = false;
          _error = error is AuthFailure ? error.message : 'Could not sign in';
        });
    }
  }
}
