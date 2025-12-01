import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/stat_card.dart'; // Import widget baru tadi
import '../history_page.dart';
import '../partner_list_page.dart';
import 'product_list_page.dart';
import 'barang_masuk_page.dart';
import 'stock_opname_page.dart';

class GudangDashboard extends StatefulWidget {
  const GudangDashboard({super.key});

  @override
  State<GudangDashboard> createState() => _GudangDashboardState();
}

class _GudangDashboardState extends State<GudangDashboard> {
  int _totalItems = 0;
  int _lowStockItems = 0; // Stok Kritis

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final supabase = Supabase.instance.client;

    // Ambil semua produk
    final response = await supabase.from('products').select('stock_quantity');
    final List data = response as List;

    int lowStockCount = 0;
    for (var item in data) {
      if ((item['stock_quantity'] ?? 0) < 10) {
        // BATAS KRITIS: 10
        lowStockCount++;
      }
    }

    if (mounted) {
      setState(() {
        _totalItems = data.length;
        _lowStockItems = lowStockCount;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Gudang'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- STATISTIK ---
            Row(
              children: [
                StatCard(
                  title: 'Total Jenis Barang',
                  value: _totalItems.toString(),
                  icon: Icons.category,
                  color: Colors.blue,
                ),
                const SizedBox(width: 16),
                StatCard(
                  title: 'Stok Menipis (<10)',
                  value: _lowStockItems.toString(),
                  icon: Icons.warning_amber_rounded,
                  color: _lowStockItems > 0
                      ? Colors.red
                      : Colors.green, // Merah kalau ada yg mau habis
                ),
              ],
            ),

            const SizedBox(height: 40),

            // --- MENU UTAMA ---
            const Text(
              'Menu Operasional',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 280,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.inventory),
                        label: const Text('Lihat Stok & Barang'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => const ProductListPage(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: 280,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.input),
                        label: const Text('Input Barang Masuk (Inbound)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => const BarangMasukPage(),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 280,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.content_paste_search,
                        ), // Ikon Inspeksi
                        label: const Text('Stock Opname / Barang Rusak'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[800], // Warna Oranye
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) => const StockOpnamePage(),
                            ),
                          );
                          _fetchStats(); // Refresh statistik stok menipis
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
