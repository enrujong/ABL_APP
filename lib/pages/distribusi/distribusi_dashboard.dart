import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../widgets/stat_card.dart';
import '../history_page.dart';
import '../partner_list_page.dart';
import 'barang_keluar_page.dart';

class DistribusiDashboard extends StatefulWidget {
  const DistribusiDashboard({super.key});

  @override
  State<DistribusiDashboard> createState() => _DistribusiDashboardState();
}

class _DistribusiDashboardState extends State<DistribusiDashboard> {
  int _pendingInvoices = 0;
  double _todaySales = 0;
  bool _isLoading = false; // Tambahan untuk indikator loading

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;

    // 1. Ambil Penanda Bulan Ini (Format: Tahun-Bulan, misal "2025-11")
    final now = DateTime.now();
    final currentMonthStr = DateFormat('yyyy-MM').format(now);

    // 2. Tarik Transaksi OUT
    final response = await supabase
        .from('transactions')
        .select('total_amount, transaction_date, payment_status')
        .eq('transaction_type', 'OUT');

    final List data = response as List;

    int pendingCount = 0;
    double sumSalesMonthly = 0; // Ubah nama variabel biar jelas

    for (var item in data) {
      // Hitung Tagihan Tempo
      if (item['payment_status'] == 'TEMPO') {
        pendingCount++;
      }

      // Hitung Penjualan BULAN INI
      if (item['transaction_date'] != null) {
        // Tetap pakai .toLocal() agar tanggalnya akurat sesuai jam Indonesia
        final trxDate = DateTime.parse(item['transaction_date']).toLocal();

        // Ubah tanggal transaksi jadi format "yyyy-MM" juga
        final trxMonthStr = DateFormat('yyyy-MM').format(trxDate);

        // Bandingkan: Apakah Bulan & Tahunnya sama?
        if (trxMonthStr == currentMonthStr) {
          sumSalesMonthly += (item['total_amount'] ?? 0).toDouble();
        }
      }
    }

    if (mounted) {
      setState(() {
        _pendingInvoices = pendingCount;
        _todaySales = sumSalesMonthly; // Simpan total bulanan ke variabel ini
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
      appBar: AppBar(
        title: const Text('Dashboard Distribusi'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
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
      // Bungkus dengan RefreshIndicator agar bisa ditarik
      body: RefreshIndicator(
        onRefresh: _fetchStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // --- STATISTIK ---
              Row(
                children: [
                  StatCard(
                    title: 'Tagihan Tempo (Aktif)',
                    value: _pendingInvoices.toString(),
                    icon: Icons.assignment_late,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 16),
                  StatCard(
                    title: 'Penjualan Bulan Ini',
                    value: _formatCurrency(_todaySales),
                    icon: Icons.monetization_on,
                    color: Colors.green,
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

              Center(
                child: SizedBox(
                  width: 280,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.note_add),
                    label: const Text('Buat Surat Jalan Baru'),
                    // --- PERBAIKAN UTAMA ADA DI SINI ---
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => const BarangKeluarPage(),
                        ),
                      );
                      // Refresh data setelah balik dari halaman transaksi
                      _fetchStats();
                    },
                    // -----------------------------------
                  ),
                ),
              ),

              // Teks kecil info update (opsional)
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
