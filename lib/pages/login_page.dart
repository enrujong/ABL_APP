import 'package:flutter/material.dart';
import 'gudang/gudang_dashboard.dart';
import 'distribusi/distribusi_dashboard.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  // --- PALET WARNA BARU ---
  final Color _colDarkGunmetal = const Color(0xFF2B2D42);
  final Color _colRed = const Color(0xFFEF233C);
  final Color _colWhite = const Color(0xFFEDF2F4);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colDarkGunmetal,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            vertical: 40,
          ), // Padding vertikal biar aman di layar kecil
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- LOGO PERUSAHAAN (DIPERBESAR) ---
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Image.asset(
                  'lib/assets/warehouse-logo-1024.png',
                  height: 180, // Diperbesar dari 120 ke 180
                  width: 180,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 20), // Jarak dikurangi (Tadinya 30)

              Text(
                'Sistem Administrasi Gudang & Distribusi',
                style: TextStyle(
                  fontSize:
                      32, // Font judul diperbesar sedikit biar seimbang sama logo
                  fontWeight: FontWeight.bold,
                  color: _colWhite,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(
                height: 5,
              ), // Jarak antar teks judul & PT dirapatkan
              const Text(
                'PT. Abadi Berkat Lestarindo',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),

              const SizedBox(height: 40), // Jarak ke kartu login disesuaikan
              // Kartu Login
              Card(
                elevation: 8,
                color: _colWhite,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    20,
                  ), // Lebih membulat modern
                ),
                child: Container(
                  width: 400,
                  padding: const EdgeInsets.all(32), // Padding dalam kartu
                  child: Column(
                    children: [
                      const Text(
                        'Selamat Datang',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2B2D42), // Dark Gunmetal text
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Silahkan pilih role anda',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 32), // Jarak ke tombol
                      // Tombol Gudang
                      _buildLoginButton(
                        title: 'Masuk sebagai GUDANG',
                        subtitle: 'Kelola Stok & Inbound',
                        icon: Icons.warehouse,
                        color: _colDarkGunmetal,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) => const GudangDashboard(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16), // Jarak antar tombol
                      // Tombol Distribusi
                      _buildLoginButton(
                        title: 'Masuk sebagai DISTRIBUSI',
                        subtitle: 'Penjualan & Outbound',
                        icon: Icons.local_shipping,
                        color: _colRed,
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

              const SizedBox(height: 30),
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
      height: 70, // Tinggi tombol fix agar gagah
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ), // Sudut tombol lebih bulat
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(
                  0.2,
                ), // Lingkaran background icon
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
