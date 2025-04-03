import 'package:flutter/material.dart';

ThemeData buildAppTheme(BuildContext context) {
  Brightness brightness = MediaQuery.of(context).platformBrightness;
  Color seedColor = (brightness == Brightness.dark) ? Colors.green : Colors.red;
  return ThemeData(
    useMaterial3: true, // Enable Material 3 (You)
    // Color scheme that adapts to system preferences (light/dark mode)
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    ),
    cardColor: ColorScheme.fromSeed(seedColor: seedColor).onPrimaryContainer,
    appBarTheme: const AppBarTheme(
      titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    ),
  );
}
