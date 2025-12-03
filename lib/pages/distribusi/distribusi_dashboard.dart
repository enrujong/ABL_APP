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

  // --- PALET WARNA BARU (PROFESSIONAL) ---
  final Color _colDarkGunmetal = const Color(0xFF2B2D42); // Utama
  final Color _colCoolGrey = const Color(0xFF8D99AE); // Sekunder
  final Color _colWhite = const Color(0xFFEDF2F4); // Background
  final Color _colRed = const Color(0xFFEF233C); // Aksen Merah

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final supabase = Supabase.instance.client;
    final now = DateTime.now();
    final currentMonthStr = DateFormat('yyyy-MM').format(now);

    final response = await supabase
        .from('transactions')
        .select('total_amount, transaction_date, payment_status')
        .eq('transaction_type', 'OUT');

    final List data = response as List;
    int pendingCount = 0;
    double sumSalesMonthly = 0;

    for (var item in data) {
      if (item['payment_status'] == 'TEMPO') pendingCount++;
      if (item['transaction_date'] != null) {
        final trxDate = DateTime.parse(item['transaction_date']).toLocal();
        if (DateFormat('yyyy-MM').format(trxDate) == currentMonthStr) {
          sumSalesMonthly += (item['total_amount'] ?? 0).toDouble();
        }
      }
    }

    if (mounted) {
      setState(() {
        _pendingInvoices = pendingCount;
        _todaySales = sumSalesMonthly;
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
      backgroundColor: _colWhite,
      appBar: AppBar(
        title: const Text('Dashboard Distribusi'),
        backgroundColor: _colDarkGunmetal,
        foregroundColor: _colWhite,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_outlined),
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
                    title: 'Tagihan Tempo (Aktif)',
                    value: _pendingInvoices.toString(),
                    icon: Icons.assignment_late,
                    color:
                        _colCoolGrey, // Abu-abu biar tidak terlalu mengancam, tapi tetap jelas
                  ),
                  const SizedBox(width: 24),
                  StatCard(
                    title: 'Penjualan Bulan Ini',
                    value: _formatCurrency(_todaySales),
                    icon: Icons.monetization_on,
                    color: _colDarkGunmetal, // Warna corporate untuk omzet
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
                  // 1. BUAT SURAT JALAN (Biru Gelap)
                  _buildFullCard(
                    label: 'Buat Surat Jalan\n(Transaksi Baru)',
                    icon: Icons.note_add,
                    color: _colDarkGunmetal,
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

                  const SizedBox(width: 24),

                  // 2. CEK TAGIHAN (Merah Terang)
                  _buildFullCard(
                    label: 'Cek Tagihan\nBelum Lunas',
                    icon: Icons.payments,
                    color:
                        _colRed, // Merah agar terlihat sebagai prioritas penagihan
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
            ),
          ],
        ),
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
