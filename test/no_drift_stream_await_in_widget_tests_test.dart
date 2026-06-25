import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Forbidden shapes inside a `testWidgets` body: a drift `watch…()` query
/// reduced to a single value, or any stream matcher. Both imply awaiting a
/// stream's emission, which the widget-test fake-async clock never delivers
/// without a `pump` — so the test hangs to the timeout.
final List<RegExp> _forbidden = <RegExp>[
  RegExp(r'watch\w*\s*\([^;{}]*?\)\s*\.\s*(first|firstWhere|single|last)\b'),
  RegExp(
    r'\b(emits|emitsThrough|emitsInOrder|emitsInAnyOrder|emitsAnyOf'
    r'|neverEmits|emitsDone|emitsError|mayEmit|mayEmitMultiple)\s*\(',
  ),
];

/// This guard's own filename, excluded from the scan (it contains the patterns
/// it searches for, as regex literals).
const String _selfName = 'no_drift_stream_await_in_widget_tests_test.dart';

void main() {
  test('no drift .watch() stream is awaited inside a testWidgets body', () {
    final violations = <String>[];

    final files = Directory('test')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.endsWith(_selfName));

    for (final file in files) {
      final source = _blankCommentsAndStrings(file.readAsStringSync());
      for (final span in _testWidgetsSpans(source)) {
        final body = source.substring(span.start, span.end);
        for (final pattern in _forbidden) {
          for (final match in pattern.allMatches(body)) {
            final offset = span.start + match.start;
            final before = source.substring(0, offset);
            final line = '\n'.allMatches(before).length + 1;
            violations.add('${file.path}:$line  ${match[0]!.trim()}');
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Awaiting a drift `.watch()` stream inside a testWidgets body hangs '
          'to the test timeout: widget tests run under a '
          'fake-async clock that only delivers stream events after a pump. Use '
          'a one-shot `.get()` read (the SeedReads extension in test/support) '
          'and assert reactive UI via pumpAndSettle + find.\n  '
          '${violations.join('\n  ')}',
    );
  });
}

/// The `(...)` argument span (exclusive of the outer parens) of every
/// `testWidgets(` call in [source], located by paren-depth matching.
Iterable<({int start, int end})> _testWidgetsSpans(String source) sync* {
  for (final match in RegExp(r'\btestWidgets\s*\(').allMatches(source)) {
    var depth = 1;
    var i = match.end;
    for (; i < source.length && depth > 0; i++) {
      switch (source[i]) {
        case '(':
          depth++;
        case ')':
          depth--;
      }
    }
    yield (start: match.end, end: i);
  }
}

/// Replaces comment and string-literal contents with spaces, preserving every
/// character offset and newline so match offsets map back to original line
/// numbers. Prevents matching the forbidden shapes inside comments or strings
/// (e.g. the explanatory `.watch()` comments in the sibling tests).
String _blankCommentsAndStrings(String source) {
  final out = StringBuffer();
  final n = source.length;
  var i = 0;
  while (i < n) {
    final c = source[i];
    final next = i + 1 < n ? source[i + 1] : '';
    if (c == '/' && next == '/') {
      while (i < n && source[i] != '\n') {
        out.write(' ');
        i++;
      }
    } else if (c == '/' && next == '*') {
      out.write('  ');
      i += 2;
      while (i < n &&
          !(source[i] == '*' && i + 1 < n && source[i + 1] == '/')) {
        out.write(source[i] == '\n' ? '\n' : ' ');
        i++;
      }
      if (i < n) {
        out.write('  ');
        i += 2;
      }
    } else if (c == "'" || c == '"') {
      i = _blankString(source, i, out);
    } else {
      out.write(c);
      i++;
    }
  }
  return out.toString();
}

/// Blanks the string literal that starts at [start] (a quote char), handling
/// triple-quoted strings and backslash escapes. Returns the index just past the
/// closing quote.
int _blankString(String source, int start, StringBuffer out) {
  final quote = source[start];
  final n = source.length;
  final isTriple =
      start + 2 < n && source[start + 1] == quote && source[start + 2] == quote;

  if (isTriple) {
    out.write('   ');
    var i = start + 3;
    while (i < n &&
        !(source[i] == quote &&
            i + 2 < n &&
            source[i + 1] == quote &&
            source[i + 2] == quote)) {
      out.write(source[i] == '\n' ? '\n' : ' ');
      i++;
    }
    if (i < n) {
      out.write('   ');
      i += 3;
    }
    return i;
  }

  out.write(' ');
  var i = start + 1;
  while (i < n && source[i] != quote) {
    final isEscape = source[i] == r'\';
    out.write(source[i] == '\n' ? '\n' : ' ');
    i++;
    if (isEscape && i < n) {
      out.write(source[i] == '\n' ? '\n' : ' ');
      i++;
    }
  }
  if (i < n) {
    out.write(' ');
    i++;
  }
  return i;
}
