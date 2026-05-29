import 'package:flutter/material.dart';
import 'package:mono/services/notification_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme.dart';
import 'core/constants.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart'; // Pastikan import ini ada

Future<void> main() async {
  // 1. Pastikan binding sudah siap
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inisialisasi Supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  await NotificationService().initNotification();

  runApp(const MonoApp());
}

class MonoApp extends StatelessWidget {
  const MonoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 3. Ambil sesi user saat ini
    final session = Supabase.instance.client.auth.currentSession;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mono Focus',
      theme: AppTheme.lightTheme,
      
      // 4. Logika penentuan halaman pertama
      // Jika session tidak null, artinya user sudah login
      home: session != null ? const HomeScreen() : const LoginScreen(),
      
      // Tips: Kamu juga bisa menambahkan routes di sini jika ingin
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}