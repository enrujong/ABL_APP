import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../widgets/stat_card.dart';
import '../history_page.dart';
import '../partner_list_page.dart';
import 'barang_keluar_page.dart';
import 'invoice_page.dart';

class DistribusiDashboard extends StatefulWidget {
  const DistribusiDashboard({super.key});

  @override
  State<DistribusiDashboard> createState() => _DistribusiDashboardState();
}

class _DistribusiDashboardState extends State<DistribusiDashboard> {
  int _pendingInvoices = 0;
  double _todaySales = 0;
  bool _isLoading = false;

  // --- PALET WARNA BARU ---
  final Color _colPrussianBlue = const Color(0xFF1D3557); // Dominan
  final Color _colCeladonBlue = const Color(0xFF457B9D); // Aksen Biru
  final Color _colHoneydew = const Color(0xFFF1FAEE); // Background
  final Color _colImperialRed = const Color(
    0xFFE63946,
  ); // Aksen Merah (Penting)

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;

    // 1. Ambil Penanda Bulan Ini (yyyy-MM)
    final now = DateTime.now();
    final currentMonthStr = DateFormat('yyyy-MM').format(now);

    // 2. Tarik Transaksi OUT
    final response = await supabase
        .from('transactions')
        .select('total_amount, transaction_date, payment_status')
        .eq('transaction_type', 'OUT');

    final List data = response as List;

    int pendingCount = 0;
    double sumSalesMonthly = 0;

    for (var item in data) {
      // Hitung Tagihan Tempo
      if (item['payment_status'] == 'TEMPO') {
        pendingCount++;
      }

      // Hitung Penjualan BULAN INI
      if (item['transaction_date'] != null) {
        final trxDate = DateTime.parse(item['transaction_date']).toLocal();
        final trxMonthStr = DateFormat('yyyy-MM').format(trxDate);

        if (trxMonthStr == currentMonthStr) {
          sumSalesMonthly += (item['total_amount'] ?? 0).toDouble();
        }
      }
    }

    if (mounted) {
      setState(() {
        _pendingInvoices = pendingCount;
        _todaySales = sumSalesMonthly;
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colHoneydew, // Background Bersih
      appBar: AppBar(
        title: const Text('Dashboard Distribusi'),
        backgroundColor: _colPrussianBlue,
        foregroundColor: _colHoneydew,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_outlined),
            tooltip: 'Data Toko',
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- STATISTIK ---
              Row(
                children: [
                  StatCard(
                    title: 'Tagihan Tempo (Aktif)',
                    value: _pendingInvoices.toString(),
                    icon: Icons.assignment_late,
                    color:
                        Colors.orange, // Tetap orange agar ikon warning jelas
                  ),
                  const SizedBox(width: 20),
                  StatCard(
                    title: 'Penjualan Bulan Ini',
                    value: _formatCurrency(_todaySales),
                    icon: Icons.monetization_on,
                    color: Colors.green, // Hijau untuk uang
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

              // --- MENU BUTTONS (HORIZONTAL) ---
              // Row + Expanded agar tombol membagi lebar layar
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TOMBOL 1: BUAT SURAT JALAN
                  _buildMenuCard(
                    label: 'Buat Surat Jalan\n(Transaksi Baru)',
                    icon: Icons.note_add,
                    color: _colPrussianBlue, // Warna Utama
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => const BarangKeluarPage(),
                        ),
                      );
                      _fetchStats();
                    },
                  ),

                  const SizedBox(width: 20), // Jarak
                  // TOMBOL 2: CEK TAGIHAN
                  _buildMenuCard(
                    label: 'Cek Tagihan\nBelum Lunas',
                    icon: Icons.payments,
                    color: _colImperialRed, // Warna Merah (Urgensi Uang)
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (c) => const InvoicePage()),
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
    );
  }

  // WIDGET KARTU MENU BESAR (Sama persis dengan Gudang agar konsisten)
  Widget _buildMenuCard({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(20),
        elevation: 6,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.white24,
          child: Container(
            height: 180, // Tinggi tombol besar
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon dalam lingkaran
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 20),
                // Teks
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
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
