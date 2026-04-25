import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'screens/home_screen.dart';

void main() => runApp(const MonoApp());

class MonoApp extends StatelessWidget {
  const MonoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, 
      home: const HomeScreen(),
    );
  }
}
