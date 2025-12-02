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
  bool _isLoading = false;

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
    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;

    try {
      // 1. Hitung Total Jenis Barang
      final productRes = await supabase
          .from('products')
          .select('id')
          .count(CountOption.exact);

      final productCount = productRes.count;

      // 2. Hitung Barang Stok Menipis (< 10)
      final lowStockRes = await supabase
          .from('products')
          .select('id')
          .lt('stock_quantity', 10)
          .count(CountOption.exact);

      final lowStockCount = lowStockRes.count;

      if (mounted) {
        setState(() {
          _totalProducts = productCount;
          _lowStockItems = lowStockCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colHoneydew,
      appBar: AppBar(
        title: const Text('Dashboard Gudang'),
        backgroundColor: _colPrussianBlue,
        foregroundColor: _colHoneydew,
        elevation: 4,
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
      body: RefreshIndicator(
        onRefresh: _fetchStats,
        color: _colPrussianBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // Memenuhi lebar layar
            children: [
              // --- STATISTIK CARDS ---
              Row(
                children: [
                  StatCard(
                    title: 'Total Jenis Barang',
                    value: _totalProducts.toString(),
                    icon: Icons.category,
                    color: _colCeladonBlue,
                  ),
                  const SizedBox(width: 20),
                  StatCard(
                    title: 'Stok Menipis (<10)',
                    value: _lowStockItems.toString(),
                    icon: Icons.warning_amber_rounded,
                    color: _colImperialRed,
                  ),
                ],
              ),

              const SizedBox(height: 50),

              // --- TITLE MENU ---
              Text(
                'Menu Operasional',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _colPrussianBlue,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 20),

              // --- MENU BUTTONS (HORIZONTAL & BESAR) ---
              // Menggunakan Row + Expanded agar tombol membagi rata lebar layar
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TOMBOL 1: LIHAT STOK
                  _buildMenuCard(
                    label: 'Lihat Stok\n& Barang',
                    icon: Icons.list_alt,
                    color: _colCeladonBlue,
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

                  const SizedBox(width: 20), // Jarak horizontal antar tombol
                  // TOMBOL 2: INPUT BARANG MASUK
                  _buildMenuCard(
                    label: 'Input Barang\nMasuk (Inbound)',
                    icon: Icons.input,
                    color: _colPrussianBlue,
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

                  const SizedBox(width: 20),

                  // TOMBOL 3: STOCK OPNAME
                  _buildMenuCard(
                    label: 'Stock Opname\n/ Koreksi',
                    icon: Icons.content_paste_search,
                    color:
                        _colPrussianBlue, // Bisa diganti _colImperialRed kalau mau beda
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

              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: Center(
                    child: CircularProgressIndicator(color: _colPrussianBlue),
                  ),
                ),
            ],
          ),
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
        elevation: 4,
        icon: const Icon(Icons.add, size: 28),
        label: const Text(
          'Barang Baru',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // WIDGET BARU: KARTU MENU BESAR
  Widget _buildMenuCard({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      // Agar memenuhi ruang horizontal
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(20), // Sudut lebih bulat
        elevation: 6, // Shadow lebih tebal
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.white24,
          child: Container(
            height: 180, // Tinggi tombol diperbesar (agar tidak gepeng)
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Besar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(
                      0.2,
                    ), // Lingkaran transparan
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 20),
                // Text
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2, // Spasi antar baris teks
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
