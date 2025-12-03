import 'package:flutter/material.dart';
import 'gudang/gudang_dashboard.dart';
import 'distribusi/distribusi_dashboard.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  // --- PALET WARNA BARU ---
  final Color _colDarkGunmetal = const Color(0xFF2B2D42); // Background Utama
  final Color _colRed = const Color(0xFFEF233C); // Aksen Merah
  final Color _colWhite = const Color(0xFFEDF2F4); // Teks/Card

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colDarkGunmetal, // Background Gelap Solid
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo / Icon Besar
              Icon(
                Icons.inventory_2_outlined,
                size: 80,
                color: _colRed,
              ), // Ikon Merah menyala
              const SizedBox(height: 20),
              Text(
                'Sistem Distribusi',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _colWhite,
                  letterSpacing: 1.2,
                ),
              ),
              const Text(
                'PT. Abadi Jaya Lestarindo',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 50),

              // Kartu Login
              Card(
                elevation: 8,
                color: _colWhite, // Kartu Putih
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: 400,
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      const Text(
                        'Selamat Datang',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Silahkan pilih role anda',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 40),

                      // Tombol Gudang
                      _buildLoginButton(
                        title: 'Masuk sebagai GUDANG',
                        subtitle: 'Kelola Stok & Inbound',
                        icon: Icons.warehouse,
                        color: _colDarkGunmetal, // Tombol Gelap
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) => const GudangDashboard(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Tombol Distribusi
                      _buildLoginButton(
                        title: 'Masuk sebagai DISTRIBUSI',
                        subtitle: 'Penjualan & Outbound',
                        icon: Icons.local_shipping,
                        color: _colRed, // Tombol Merah
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) => const DistribusiDashboard(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                'v1.0.0 • Professional ERP',
                style: TextStyle(color: Colors.white30, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color, // Warna tombol solid
          foregroundColor: Colors.white, // Teks Putih
          elevation: 4,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            Icon(icon, size: 28, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.white54,
            ),
          ],
        ),
      ),
    );
  }
}
