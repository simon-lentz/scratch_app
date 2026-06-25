import 'package:flutter/material.dart';

/// Shows a transient error [message] over the nearest [Scaffold].
void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
