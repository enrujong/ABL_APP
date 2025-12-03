import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/stat_card.dart';
import '../history_page.dart';
import '../partner_list_page.dart';
import 'add_product_page.dart';
import 'barang_masuk_page.dart';
import 'product_list_page.dart';
import 'stock_opname_page.dart';

class GudangDashboard extends StatefulWidget {
  const GudangDashboard({super.key});

  @override
  State<GudangDashboard> createState() => _GudangDashboardState();
}

class _GudangDashboardState extends State<GudangDashboard> {
  int _totalProducts = 0;
  int _lowStockItems = 0;

  // --- PALET WARNA BARU (PROFESSIONAL) ---
  final Color _colDarkGunmetal = const Color(0xFF2B2D42); // Utama
  final Color _colCoolGrey = const Color(0xFF8D99AE); // Sekunder
  final Color _colWhite = const Color(0xFFEDF2F4); // Background
  final Color _colRed = const Color(0xFFEF233C); // Aksen
  final Color _colDarkRed = const Color(0xFFD90429); // Danger

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final supabase = Supabase.instance.client;
    try {
      final productRes = await supabase
          .from('products')
          .select('id')
          .count(CountOption.exact);
      final lowStockRes = await supabase
          .from('products')
          .select('id')
          .lt('stock_quantity', 10)
          .count(CountOption.exact);

      if (mounted) {
        setState(() {
          _totalProducts = productRes.count;
          _lowStockItems = lowStockRes.count;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colWhite,
      appBar: AppBar(
        title: const Text('Dashboard Gudang'),
        backgroundColor: _colDarkGunmetal,
        foregroundColor: _colWhite,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.warehouse_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const PartnerListPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const HistoryPage()),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- STATISTIK ---
            SizedBox(
              height: 160,
              child: Row(
                children: [
                  StatCard(
                    title: 'Total Jenis Barang',
                    value: _totalProducts.toString(),
                    icon: Icons.category,
                    color: _colCoolGrey, // Abu-abu elegan
                  ),
                  const SizedBox(width: 24),
                  StatCard(
                    title: 'Stok Menipis (<10)',
                    value: _lowStockItems.toString(),
                    icon: Icons.warning_amber_rounded,
                    color: _colRed, // Merah menyala
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Text(
              'Menu Operasional',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _colDarkGunmetal,
              ),
            ),

            const SizedBox(height: 16),

            // --- MENU (EXPANDED) ---
            Expanded(
              child: Row(
                children: [
                  // 1. LIHAT STOK (Abu-abu)
                  _buildFullCard(
                    label: 'Lihat Stok\n& Barang',
                    icon: Icons.list_alt,
                    color: _colCoolGrey,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => const ProductListPage(),
                        ),
                      );
                      _fetchStats();
                    },
                  ),

                  const SizedBox(width: 24),

                  // 2. INPUT BARANG (Biru Gelap)
                  _buildFullCard(
                    label: 'Input Barang\nMasuk',
                    icon: Icons.input,
                    color: _colDarkGunmetal,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => const BarangMasukPage(),
                        ),
                      );
                      _fetchStats();
                    },
                  ),

                  const SizedBox(width: 24),

                  // 3. STOCK OPNAME (Merah Gelap)
                  _buildFullCard(
                    label: 'Stock Opname\n/ Koreksi',
                    icon: Icons.content_paste_search,
                    color: _colDarkRed,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => const StockOpnamePage(),
                        ),
                      );
                      _fetchStats();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const AddProductPage()),
          );
          _fetchStats();
        },
        backgroundColor: _colDarkGunmetal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Barang Baru'),
      ),
    );
  }

  Widget _buildFullCard({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(24),
        elevation: 8,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          splashColor: Colors.white24,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
