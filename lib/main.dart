import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/login_page.dart'; // Import halaman login

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zkmjbwpaqflchfxvtbgl.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InprbWpid3BhcWZsY2hmeHZ0YmdsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzODM1MjgsImV4cCI6MjA3OTk1OTUyOH0.qH3DF2aepVrIwcgjO4MTwaqYveY_oKkFwGxe1iQi-Fs',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Distribusi App',
      debugShowCheckedModeBanner: false, // Menghilangkan pita "Debug" di pojok
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginPage(), // Arahkan ke Login Page
    );
  }
}
