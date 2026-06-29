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

  /// Where each formatted event line is written. The `error` and `stackTrace`
  /// args are supplied only for a failure, so the default sink can forward them
  /// to the structured fields of `dart:developer`'s log.
  final void Function(String message, {Object? error, StackTrace? stackTrace})
  sink;

  static void _developerLog(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) => developer.log(
    message,
    name: 'riverpod',
    error: error,
    stackTrace: stackTrace,
  );

  String _name(ProviderObserverContext context) =>
      context.provider.name ?? context.provider.runtimeType.toString();

  // Cap a logged value so a large object can't flood the log. Truncate on a
  // code-point boundary (via runes) so a surrogate pair at the cut is not split
  // into a lone surrogate that renders as a replacement glyph. toString() runs
  // in full before truncating — unavoidable to preview a value, and cheap
  // enough for an observer registered only in debug builds.
  String _brief(Object? value) {
    final text = value.toString();
    if (text.length <= 80) return text;
    return '${String.fromCharCodes(text.runes.take(77))}…';
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
  ) => sink(
    '! ${_name(context)} threw: $error',
    error: error,
    stackTrace: stackTrace,
  );
}
