/// Fractional ordering keys ("ranks"): lexicographically-ordered base-62
/// strings with the property that a key can always be produced strictly
/// between any two others. Inserting between neighbours is a one-row change;
/// the key length grows only when you repeatedly split the same gap.
///
/// A direct port of Observable / rocicorp `generateKeyBetween` (see
/// `rank_test.dart` for the canonical golden vectors). Pure Dart — no deps.
library;

const String _digits =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
const String _integerZero = 'a0';
const String _smallestInteger = 'A00000000000000000000000000'; // 'A' + 26 zeros

int _integerLength(String head) {
  final c = head.codeUnitAt(0);
  if (c >= 0x61 && c <= 0x7A) return c - 0x61 + 2; // 'a'..'z'
  if (c >= 0x41 && c <= 0x5A) return 0x5A - c + 2; // 'A'..'Z'
  throw ArgumentError('Invalid order-key head: $head');
}

void _validateInteger(String integer) {
  if (integer.length != _integerLength(integer[0])) {
    throw ArgumentError('Invalid integer part of order key: $integer');
  }
}

String _integerPart(String key) {
  final len = _integerLength(key[0]);
  if (len > key.length) throw ArgumentError('Invalid order key: $key');
  return key.substring(0, len);
}

void _validateOrderKey(String key) {
  if (key == _smallestInteger) throw ArgumentError('Invalid order key: $key');
  final i = _integerPart(key);
  final f = key.substring(i.length);
  if (f.isNotEmpty && f[f.length - 1] == '0') {
    throw ArgumentError('Invalid order key (trailing zero): $key');
  }
}

String? _incrementInteger(String x) {
  _validateInteger(x);
  final head = x[0];
  final digs = x.substring(1).split('');
  var carry = true;
  for (var i = digs.length - 1; carry && i >= 0; i--) {
    final d = _digits.indexOf(digs[i]) + 1;
    if (d == _digits.length) {
      digs[i] = '0';
    } else {
      digs[i] = _digits[d];
      carry = false;
    }
  }
  if (carry) {
    if (head == 'Z') return 'a0';
    if (head == 'z') return null;
    final h = String.fromCharCode(head.codeUnitAt(0) + 1);
    if (h.compareTo('a') > 0) {
      digs.add('0');
    } else {
      digs.removeLast();
    }
    return h + digs.join();
  }
  return head + digs.join();
}

String? _decrementInteger(String x) {
  _validateInteger(x);
  final head = x[0];
  final digs = x.substring(1).split('');
  var borrow = true;
  for (var i = digs.length - 1; borrow && i >= 0; i--) {
    final d = _digits.indexOf(digs[i]) - 1;
    if (d == -1) {
      digs[i] = _digits[_digits.length - 1];
    } else {
      digs[i] = _digits[d];
      borrow = false;
    }
  }
  if (borrow) {
    if (head == 'a') return 'Z${_digits[_digits.length - 1]}';
    if (head == 'A') return null;
    final h = String.fromCharCode(head.codeUnitAt(0) - 1);
    if (h.compareTo('Z') < 0) {
      digs.add(_digits[_digits.length - 1]);
    } else {
      digs.removeLast();
    }
    return h + digs.join();
  }
  return head + digs.join();
}

String _midpoint(String a, String? b) {
  if (b != null && a.compareTo(b) >= 0) throw ArgumentError('$a >= $b');
  if ((a.isNotEmpty && a[a.length - 1] == '0') ||
      (b != null && b.isNotEmpty && b[b.length - 1] == '0')) {
    throw ArgumentError('trailing zero');
  }
  if (b != null) {
    var n = 0;
    while ((n < a.length ? a[n] : '0') == b[n]) {
      n++;
    }
    if (n > 0) {
      return b.substring(0, n) +
          _midpoint(a.substring(n < a.length ? n : a.length), b.substring(n));
    }
  }
  final digitA = a.isNotEmpty ? _digits.indexOf(a[0]) : 0;
  final digitB = (b != null && b.isNotEmpty)
      ? _digits.indexOf(b[0])
      : _digits.length;
  if (digitB - digitA > 1) {
    return _digits[(digitA + digitB + 1) ~/ 2];
  }
  if (b != null && b.length > 1) return b.substring(0, 1);
  return _digits[digitA] + _midpoint(a.isNotEmpty ? a.substring(1) : '', null);
}

/// A rank strictly between [a] and [b]. `rankBetween(null, null)` is the first
/// key; before-first is `rankBetween(null, first)`, after-last is
/// `rankBetween(last, null)`. Throws [ArgumentError] if `a >= b`.
String rankBetween(String? a, String? b) {
  if (a != null) _validateOrderKey(a);
  if (b != null) _validateOrderKey(b);
  if (a != null && b != null && a.compareTo(b) >= 0) {
    throw ArgumentError('$a >= $b');
  }
  if (a == null && b == null) return _integerZero;
  if (a == null) {
    final ib = _integerPart(b!);
    final fb = b.substring(ib.length);
    if (ib == _smallestInteger) return ib + _midpoint('', fb);
    return ib.compareTo(b) < 0 ? ib : _decrementInteger(ib)!;
  }
  if (b == null) {
    final ia = _integerPart(a);
    final fa = a.substring(ia.length);
    return _incrementInteger(ia) ?? ia + _midpoint(fa, null);
  }
  final ia = _integerPart(a);
  final fa = a.substring(ia.length);
  final ib = _integerPart(b);
  final fb = b.substring(ib.length);
  if (ia == ib) return ia + _midpoint(fa, fb);
  final i = _incrementInteger(ia);
  return (i != null && i.compareTo(b) < 0) ? i : ia + _midpoint(fa, null);
}

/// [n] ordered ranks strictly between [a] and [b]; shorter keys than [n]
/// sequential [rankBetween] calls. `ranksBetween(null, null, k)` is the compact
/// append sequence `['a0','a1',…]` — used to backfill existing rows.
List<String> ranksBetween(String? a, String? b, int n) {
  if (n <= 0) return [];
  if (n == 1) return [rankBetween(a, b)];
  if (b == null) {
    var c = rankBetween(a, b);
    final r = [c];
    for (var i = 0; i < n - 1; i++) {
      c = rankBetween(c, b);
      r.add(c);
    }
    return r;
  }
  if (a == null) {
    var c = rankBetween(a, b);
    final r = [c];
    for (var i = 0; i < n - 1; i++) {
      c = rankBetween(a, c);
      r.add(c);
    }
    return r.reversed.toList();
  }
  final mid = n ~/ 2;
  final c = rankBetween(a, b);
  return [...ranksBetween(a, c, mid), c, ...ranksBetween(c, b, n - mid - 1)];
}
