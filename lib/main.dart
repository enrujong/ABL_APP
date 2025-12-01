import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart'; // Import ini
import 'pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    // JANGAN LUPA ISI URL & KEY SUPABASE KAMU DI SINI
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
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(), // Kita pisahkan fungsi tema biar rapi
      home: const LoginPage(),
    );
  }

  // --- KONFIGURASI TEMA MODERN ---
  // --- KONFIGURASI TEMA MODERN (YANG SUDAH DIPERBAIKI) ---
  ThemeData _buildTheme() {
    var baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2563EB),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );

    return baseTheme.copyWith(
      // 1. Ganti Font jadi Poppins
      textTheme: GoogleFonts.poppinsTextTheme(baseTheme.textTheme),

      // 2. Desain Kotak Input (Form)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),

      // 3. Desain Tombol Global
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ), // <--- PASTIKAN ADA KOMA DAN KURUNG TUTUP INI
      // 4. Desain Card Global
      // Jika error 'CardTheme' berlanjut, coba ganti jadi 'CardThemeData'
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        color: Colors.white,
        surfaceTintColor: Colors.white,
      ),

      // 5. Desain AppBar Global
      appBarTheme: AppBarTheme(
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        elevation: 0,
      ),
    );
  }
}
