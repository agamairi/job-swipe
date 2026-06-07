import 'package:flutter/material.dart';
import 'package:job_swipe/screens/home_screen.dart';
import 'package:job_swipe/theme/app_theme.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
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
