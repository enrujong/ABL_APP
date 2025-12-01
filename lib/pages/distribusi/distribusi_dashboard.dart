import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../widgets/stat_card.dart';
import '../history_page.dart';
import '../partner_list_page.dart';
import 'barang_keluar_page.dart';
import 'invoice_page.dart'; // <--- 1. JANGAN LUPA IMPORT INI

class DistribusiDashboard extends StatefulWidget {
  const DistribusiDashboard({super.key});

  @override
  State<DistribusiDashboard> createState() => _DistribusiDashboardState();
}

class _DistribusiDashboardState extends State<DistribusiDashboard> {
  int _pendingInvoices = 0;
  double _todaySales = 0;
  bool _isLoading = false;

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

              // --- MENU OPERASIONAL ---
              const Text(
                'Menu Operasional',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // 2. DI SINI PERUBAHANNYA: Kita pakai Column agar tombol bisa ditumpuk
              Center(
                child: Column(
                  children: [
                    // --- TOMBOL 1: BUAT SURAT JALAN ---
                    SizedBox(
                      width: 280,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.note_add),
                        label: const Text('Buat Surat Jalan Baru'),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) => const BarangKeluarPage(),
                            ),
                          );
                          _fetchStats();
                        },
                      ),
                    ),

                    const SizedBox(height: 15), // Jarak antar tombol
                    // --- TOMBOL 2: CEK TAGIHAN (BARU) ---
                    SizedBox(
                      width: 280,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.orange[800], // Warna Oranye biar beda
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.payments),
                        label: const Text('Cek Tagihan Belum Lunas'),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) => const InvoicePage(),
                            ),
                          );
                          // Refresh Dashboard setelah balik (siapa tau ada yg dilunasi)
                          _fetchStats();
                        },
                      ),
                    ),
                  ],
                ),
              ),

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
