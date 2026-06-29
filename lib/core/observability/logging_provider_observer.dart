import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A [ProviderObserver] that logs provider lifecycle and state changes — a thin
/// development aid for debugging reactivity. It is registered in debug builds
/// via `ProviderScope(observers: …)`; each event is written to [sink], which
/// defaults to the `dart:developer` log under the `riverpod` name.
final class LoggingProviderObserver extends ProviderObserver {
  /// Creates the observer. The app uses the default `dart:developer` logger;
  /// tests inject a capturing [sink].
  const LoggingProviderObserver({this.sink = _developerLog});

  /// Where each formatted event line is written.
  final void Function(String message) sink;

  static void _developerLog(String message) =>
      developer.log(message, name: 'riverpod');

  String _name(ProviderObserverContext context) =>
      context.provider.name ?? context.provider.runtimeType.toString();

  // Cap a logged value so a large object can't flood the log.
  String _brief(Object? value) {
    final text = value.toString();
    return text.length <= 80 ? text : '${text.substring(0, 77)}…';
  }

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) =>
      sink('+ ${_name(context)} = ${_brief(value)}');

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) => sink(
    '~ ${_name(context)}: ${_brief(previousValue)} → ${_brief(newValue)}',
  );

  @override
  void didDisposeProvider(ProviderObserverContext context) =>
      sink('- ${_name(context)}');

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) => sink('! ${_name(context)} threw: $error');
}
