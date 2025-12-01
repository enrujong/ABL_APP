import 'package:flutter/material.dart';
import 'gudang/gudang_dashboard.dart';
import 'distribusi/distribusi_dashboard.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background Gradient Biru Tua ke Biru Muda
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF3B82F6),
            ], // Blue 900 -> Blue 500
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo / Icon Besar
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Sistem Distribusi & Gudang',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const Text(
                  'PT. Abadi Jaya Lestarindo',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 50),

                // Kartu Login
                Card(
                  elevation: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  // Batasi lebar kartu agar bagus di Desktop
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
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Silahkan pilih role anda untuk masuk',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // Tombol Gudang
                        _buildLoginButton(
                          context,
                          title: 'Masuk sebagai GUDANG',
                          subtitle: 'Kelola Stok & Inbound',
                          icon: Icons.warehouse,
                          color: Colors.green,
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
                          context,
                          title: 'Masuk sebagai DISTRIBUSI',
                          subtitle: 'Penjualan & Outbound',
                          icon: Icons.local_shipping,
                          color: Colors.blue,
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
                  'v1.0.0 • Developed with Flutter',
                  style: TextStyle(color: Colors.white30, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget Tombol Custom biar rapi
  Widget _buildLoginButton(
    BuildContext context, {
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
          backgroundColor: Colors.white,
          foregroundColor: color, // Warna teks mengikuti role
          elevation: 0,
          side: BorderSide(
            color: color.withOpacity(0.2),
            width: 1,
          ), // Garis pinggir tipis
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
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
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }
}
