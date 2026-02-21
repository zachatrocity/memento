import 'package:flutter/material.dart';

/// Visual theme choices for the template.
enum AppTheme {
  light,
  dark,
  hacker,
  kids,
}

extension AppThemeX on AppTheme {
  String get label => switch (this) {
        AppTheme.light => 'Light',
        AppTheme.dark => 'Dark',
        AppTheme.hacker => 'Hacker',
        AppTheme.kids => 'Kids',
      };

  static AppTheme fromString(String value) {
    return AppTheme.values.firstWhere(
      (t) => t.name == value,
      orElse: () => AppTheme.light,
    );
  }
}

ThemeData buildTheme(AppTheme theme) {
  switch (theme) {
    case AppTheme.light:
      return _buildLightTheme();
    case AppTheme.dark:
      return _buildDarkTheme();
    case AppTheme.hacker:
      return _buildHackerTheme();
    case AppTheme.kids:
      return _buildKidsTheme();
  }
}

ThemeData _baseTheme(ColorScheme colorScheme, {String? fontFamily}) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: fontFamily,
    appBarTheme: const AppBarTheme(centerTitle: false),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}

ThemeData _buildLightTheme() {
  final colorScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF0057FF));
  return _baseTheme(colorScheme);
}

ThemeData _buildDarkTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF0057FF),
    brightness: Brightness.dark,
  );
  return _baseTheme(colorScheme);
}

ThemeData _buildHackerTheme() {
  // Terminal-ish black + green with mono-ish typography.
  const bg = Color(0xFF050607);
  const green = Color(0xFF19FF7A);

  final colorScheme = ColorScheme.fromSeed(
    seedColor: green,
    brightness: Brightness.dark,
  ).copyWith(
    surface: bg,
    primary: green,
    secondary: const Color(0xFF00D16A),
  );

  return _baseTheme(colorScheme, fontFamily: 'monospace').copyWith(
    scaffoldBackgroundColor: bg,
  );
}

ThemeData _buildKidsTheme() {
  // Inspired by Splashpad site tokens (mist + cyan accents).
  // https://github.com/splashpad/site/blob/main/src/styles/tokens.css
  const mistBg = Color(0xFFFAFEFF);
  const cyan = Color(0xFF1DCBE3);

  final colorScheme = ColorScheme.fromSeed(
    seedColor: cyan,
    brightness: Brightness.light,
  );

  return _baseTheme(colorScheme).copyWith(
    scaffoldBackgroundColor: mistBg,
  );
}
