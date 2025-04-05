import 'package:flutter/material.dart';
import 'dart:math';

ThemeData buildAppTheme(BuildContext context) {
  Color getRandomColor() {
    Random random = Random();
    return Color.fromRGBO(
      random.nextInt(256), // Random red value (0-255)
      random.nextInt(256), // Random green value (0-255)
      random.nextInt(256), // Random blue value (0-255)
      1.0, // Opacity (fully opaque)
    );
  }

  Brightness brightness = MediaQuery.of(context).platformBrightness;
  Color seedColor =
      (brightness == Brightness.dark) ? getRandomColor() : getRandomColor();
  return ThemeData(
    useMaterial3: true, // Enable Material 3 (You)
    // Color scheme that adapts to system preferences (light/dark mode)
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    ),
    cardColor: ColorScheme.fromSeed(seedColor: seedColor).onPrimaryContainer,
    appBarTheme: AppBarTheme(
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: brightness == Brightness.dark ? Colors.white : Colors.black,
      ),
    ),
  );
}
