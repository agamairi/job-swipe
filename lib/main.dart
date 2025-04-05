import 'package:flutter/material.dart';
import 'package:job_swipe/screens/home_screen.dart';
import 'package:job_swipe/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomeScreen(),
      theme: buildAppTheme(context),
      debugShowCheckedModeBanner: false,
    );
  }
}
