import 'package:checkplan/core/observability/logging_provider_observer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('logs a provider being added and its state changing', () {
    final logs = <String>[];
    final counter = StateProvider<int>((ref) => 0);
    final container = ProviderContainer(
      observers: [
        LoggingProviderObserver(
          sink: (message, {error, stackTrace}) => logs.add(message),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(counter); // first read -> didAddProvider(…, 0)
    container.read(counter.notifier).state = 1; // -> didUpdateProvider(…, 0, 1)

    expect(logs.any((l) => l.startsWith('+') && l.contains('0')), isTrue);
    expect(logs.any((l) => l.contains('0 → 1')), isTrue);
  });

  test('logs a provider being disposed', () {
    final logs = <String>[];
    final counter = StateProvider<int>((ref) => 0);
    // Mount the provider, then dispose the container -> didDisposeProvider.
    ProviderContainer(
        observers: [
          LoggingProviderObserver(
            sink: (message, {error, stackTrace}) => logs.add(message),
          ),
        ],
      )
      ..read(counter)
      ..dispose();

    expect(logs.any((l) => l.startsWith('-')), isTrue);
  });

  test('logs a provider failure with its originating stack trace', () {
    final logs = <String>[];
    StackTrace? capturedStack;
    final boom = Provider<int>((ref) => throw StateError('boom'));
    final container = ProviderContainer(
      observers: [
        LoggingProviderObserver(
          sink: (message, {error, stackTrace}) {
            logs.add(message);
            if (stackTrace != null) capturedStack = stackTrace;
          },
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(() => container.read(boom), throwsA(isA<ProviderException>()));
    expect(logs.any((l) => l.startsWith('!') && l.contains('boom')), isTrue);
    // The originating stack trace must be forwarded to the sink, not dropped.
    expect(capturedStack, isNotNull);
  });

  test('truncates on a code-point boundary, not mid-surrogate', () {
    final logs = <String>[];
    // toString is > 80 code units with an emoji straddling the 77-unit cut; a
    // code-unit substring would keep a lone (replacement-glyph) surrogate.
    final value = '${'a' * 76}😀${'b' * 10}';
    final provider = StateProvider<String>((ref) => value);
    final container = ProviderContainer(
      observers: [
        LoggingProviderObserver(
          sink: (message, {error, stackTrace}) => logs.add(message),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(provider);

    // The truncated line carries the ellipsis; it must hold no unpaired
    // surrogate (no rune in the UTF-16 surrogate range).
    final line = logs.firstWhere((l) => l.contains('…'));
    expect(line.runes.any((r) => r >= 0xD800 && r <= 0xDFFF), isFalse);
  });

  test('the default dart:developer sink runs without throwing', () {
    final counter = StateProvider<int>((ref) => 0);
    final container = ProviderContainer(
      observers: [const LoggingProviderObserver()],
    );
    addTearDown(container.dispose);

    expect(() {
      container.read(counter);
      container.read(counter.notifier).state = 1;
    }, returnsNormally);
  });
}
