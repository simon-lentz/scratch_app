import 'package:flutter/material.dart';

/// Light Material 3 theme, seeded from the brand colour.
final ThemeData lightTheme = ThemeData(
  colorScheme: .fromSeed(seedColor: Colors.indigo),
);

/// Dark Material 3 theme, seeded from the brand colour.
final ThemeData darkTheme = ThemeData(
  colorScheme: .fromSeed(
    seedColor: Colors.indigo,
    brightness: Brightness.dark,
  ),
);
