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
      observers: [LoggingProviderObserver(sink: logs.add)],
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
    ProviderContainer(observers: [LoggingProviderObserver(sink: logs.add)])
      ..read(counter)
      ..dispose();

    expect(logs.any((l) => l.startsWith('-')), isTrue);
  });

  test('logs a provider failure via providerDidFail', () {
    final logs = <String>[];
    final boom = Provider<int>((ref) => throw StateError('boom'));
    final container = ProviderContainer(
      observers: [LoggingProviderObserver(sink: logs.add)],
    );
    addTearDown(container.dispose);

    expect(() => container.read(boom), throwsA(isA<ProviderException>()));
    expect(logs.any((l) => l.startsWith('!') && l.contains('boom')), isTrue);
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
