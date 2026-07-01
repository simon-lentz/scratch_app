import 'package:checkplan/core/database/rank.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('rankBetween — published golden vectors', () {
    // From rocicorp/fractional-indexing (CC0) — the canonical test set.
    const cases = <(String?, String?, String)>[
      (null, null, 'a0'),
      (null, 'a0', 'Zz'),
      ('a0', null, 'a1'),
      ('a0', 'a1', 'a0V'),
      ('a0V', 'a1', 'a0l'),
      ('Zz', 'a0', 'ZzV'),
      ('Zz', 'a1', 'a0'),
      (null, 'Y00', 'Xzzz'),
      ('bzz', null, 'c000'),
      ('a0', 'a0V', 'a0G'),
      ('a0', 'a0G', 'a08'),
      ('b125', 'b129', 'b127'),
      ('a0', 'a1V', 'a1'),
      ('Zz', 'a01', 'a0'),
      (null, 'a0V', 'a0'),
      (null, 'b999', 'b99'),
    ];
    for (final (a, b, expected) in cases) {
      test('rankBetween($a, $b) == $expected', () {
        expect(rankBetween(a, b), expected);
      });
    }
  });

  test('a generated key sorts strictly between its bounds', () {
    final k = rankBetween('a0', 'a1');
    expect(k.compareTo('a0') > 0, isTrue);
    expect(k.compareTo('a1') < 0, isTrue);
  });

  test('repeated insertion just above a fixed lower bound stays ordered', () {
    // Insert repeatedly into (lo, prev), each key just below the last: the
    // sequence must strictly descend toward lo and never escape the range
    // (the key string grows as the gap shrinks).
    const lo = 'a0';
    var prev = 'a1';
    for (var i = 0; i < 20; i++) {
      final k = rankBetween(lo, prev);
      expect(k.compareTo(lo) > 0, isTrue, reason: '$k > $lo');
      expect(k.compareTo(prev) < 0, isTrue, reason: '$k < $prev');
      prev = k;
    }
  });

  test('rankBetween throws when a is not strictly less than b', () {
    expect(() => rankBetween('a1', 'a0'), throwsArgumentError);
    expect(() => rankBetween('a0', 'a0'), throwsArgumentError);
  });

  group('ranksBetween', () {
    test('n keys are ascending, distinct, and within the bounds', () {
      final keys = ranksBetween(null, null, 5);
      expect(keys, hasLength(5));
      final sorted = [...keys]..sort();
      expect(keys, sorted); // already ascending
      expect(keys.toSet(), hasLength(5)); // distinct
    });

    test('ranksBetween(null, null, k) is the compact append sequence', () {
      expect(ranksBetween(null, null, 3), ['a0', 'a1', 'a2']);
    });

    test('keys land strictly between two close bounds', () {
      final keys = ranksBetween('a0', 'a1', 4);
      expect(keys, hasLength(4));
      for (final k in keys) {
        expect(k.compareTo('a0') > 0 && k.compareTo('a1') < 0, isTrue);
      }
      final sorted = [...keys]..sort();
      expect(keys, sorted);
    });

    test('n <= 0 is empty; n == 1 is a single midpoint', () {
      expect(ranksBetween(null, null, 0), isEmpty);
      expect(ranksBetween('a0', 'a2', 1), [rankBetween('a0', 'a2')]);
    });

    test('before a bound (a == null) is ascending and in range', () {
      final keys = ranksBetween(null, 'a5', 3);
      expect(keys, hasLength(3));
      final sorted = [...keys]..sort();
      expect(keys, sorted);
      for (final k in keys) {
        expect(k.compareTo('a5') < 0, isTrue);
      }
    });
  });

  group('rankBetween — edge branches', () {
    test('rejects a malformed key: invalid head char', () {
      expect(() => rankBetween('@', null), throwsArgumentError);
    });

    test('rejects a malformed key: trailing zero in the fraction', () {
      expect(() => rankBetween('a00', null), throwsArgumentError);
      expect(() => rankBetween(null, 'a00'), throwsArgumentError);
    });

    test('before-first decrements a bare integer key', () {
      expect(rankBetween(null, 'a5'), 'a4');
    });

    test('before-first spans an integer-length decrease', () {
      final k = rankBetween(null, 'b00');
      expect(k.compareTo('b00') < 0, isTrue);
      expect(rankBetween(null, k).compareTo(k) < 0, isTrue);
    });

    test('after-last spans an integer-length increase', () {
      final k = rankBetween('Yzz', null);
      expect(k.compareTo('Yzz') > 0, isTrue);
      expect(rankBetween(k, null).compareTo(k) > 0, isTrue);
    });
  });
}
