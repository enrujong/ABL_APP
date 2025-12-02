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

  // --- PALET WARNA BARU ---
  final Color _colPrussianBlue = const Color(0xFF1D3557);
  final Color _colCeladonBlue = const Color(0xFF457B9D);
  final Color _colHoneydew = const Color(0xFFF1FAEE);
  final Color _colImperialRed = const Color(0xFFE63946);

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
      backgroundColor: _colHoneydew,
      appBar: AppBar(
        title: const Text('Dashboard Gudang'),
        backgroundColor: _colPrussianBlue,
        foregroundColor: _colHoneydew,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.warehouse_outlined),
            tooltip: 'Data Supplier',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const PartnerListPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Riwayat',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const HistoryPage()),
            ),
          ),
        ],
      ),
      // Gunakan Column tanpa ScrollView agar bisa Expanded memenuhi layar
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- BAGIAN ATAS: STATISTIK ---
            SizedBox(
              height: 160, // Tinggi fix untuk statistik
              child: Row(
                children: [
                  StatCard(
                    title: 'Total Jenis Barang',
                    value: _totalProducts.toString(),
                    icon: Icons.category,
                    color: _colCeladonBlue,
                  ),
                  const SizedBox(width: 24),
                  StatCard(
                    title: 'Stok Menipis (<10)',
                    value: _lowStockItems.toString(),
                    icon: Icons.warning_amber_rounded,
                    color: _colImperialRed,
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
                color: _colPrussianBlue,
              ),
            ),

            const SizedBox(height: 16),

            // --- BAGIAN BAWAH: MENU (MEMENUHI SISA LAYAR) ---
            Expanded(
              child: Row(
                children: [
                  // TOMBOL 1: LIHAT STOK (Celadon Blue)
                  _buildFullCard(
                    label: 'Lihat Stok\n& Barang',
                    icon: Icons.list_alt,
                    color: _colCeladonBlue, // Warna BEDA 1
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

                  // TOMBOL 2: INPUT BARANG (Prussian Blue)
                  _buildFullCard(
                    label: 'Input Barang\nMasuk',
                    icon: Icons.input,
                    color: _colPrussianBlue, // Warna BEDA 2
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

                  // TOMBOL 3: STOCK OPNAME (Imperial Red)
                  _buildFullCard(
                    label: 'Stock Opname\n/ Koreksi',
                    icon: Icons.content_paste_search,
                    color: _colImperialRed, // Warna BEDA 3
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
        backgroundColor: _colCeladonBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Barang Baru'),
      ),
    );
  }

  // Widget Tombol yang Memenuhi Ruang (Expanded)
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
        elevation: 8, // Shadow lebih tebal
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          splashColor: Colors.white24,
          child: Container(
            // Tidak perlu height fix, dia akan ikut tinggi parent (Expanded)
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
                    fontSize: 20, // Font lebih besar
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
