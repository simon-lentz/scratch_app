import 'package:flutter/material.dart';

/// The brand seed colour both [lightTheme] and [darkTheme] derive from, so the
/// two schemes stay in lockstep.
const Color _seedColor = Colors.indigo;

/// Builds a Material 3 theme for [brightness], seeded from [_seedColor].
ThemeData _themeFor(Brightness brightness) => ThemeData(
  colorScheme: .fromSeed(seedColor: _seedColor, brightness: brightness),
);

/// Light Material 3 theme, seeded from the brand colour.
final ThemeData lightTheme = _themeFor(Brightness.light);

/// Dark Material 3 theme, seeded from the brand colour.
final ThemeData darkTheme = _themeFor(Brightness.dark);
