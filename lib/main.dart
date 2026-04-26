import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'screens/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  runApp(const MonoApp());
}

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

