import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'transaction_detail_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  // --- PALET WARNA ---
  final Color _colDarkGunmetal = const Color(0xFF2B2D42);
  final Color _colWhite = const Color(0xFFEDF2F4);
  final Color _colRed = const Color(0xFFEF233C);
  final Color _colGreen = const Color(0xFF2A9D8F); // Warna Sukses
  final Color _colBlue = const Color(0xFF457B9D); // Warna Info

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final response = await Supabase.instance.client
          .from('transactions')
          .select('*, partners(name)')
          .order('transaction_date', ascending: false);

      setState(() {
        _transactions = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatCurrency(num amount) {
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
        title: const Text('Riwayat Transaksi'),
        backgroundColor: _colDarkGunmetal,
        foregroundColor: _colWhite,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _colDarkGunmetal))
          : _transactions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada transaksi.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final trx = _transactions[index];
                return _buildTransactionCard(trx);
              },
            ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> trx) {
    final isMasuk = trx['transaction_type'] == 'IN';
    final isAdjust = trx['transaction_type'] == 'ADJUST';
    final isTempo = trx['payment_status'] == 'TEMPO';

    final partnerName = trx['partners'] != null
        ? trx['partners']['name']
        : (isAdjust ? 'Penyesuaian Stok' : 'Unknown');

    // Tentukan Warna Striping & Icon berdasarkan tipe
    Color statusColor;
    IconData statusIcon;

    if (isMasuk) {
      statusColor = _colGreen; // Barang Masuk = Hijau
      statusIcon = Icons.arrow_downward;
    } else if (isAdjust) {
      statusColor = Colors.orange; // Adjust = Orange
      statusIcon = Icons.build;
    } else {
      // Barang Keluar (Jual)
      if (isTempo) {
        statusColor = _colRed; // Belum Lunas = Merah
        statusIcon = Icons.warning_amber_rounded;
      } else {
        statusColor = _colBlue; // Lunas = Biru
        statusIcon = Icons.check_circle_outline;
      }
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => TransactionDetailPage(transaction: trx),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          // Agar tinggi container striping mengikuti tinggi card
          child: Row(
            children: [
              // --- STRIP WARNA KIRI ---
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),

              // --- KONTEN UTAMA ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Baris Atas: No Faktur & Tanggal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '#${trx['id']}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatDate(trx['transaction_date']),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Baris Tengah: Nama Mitra
                      Row(
                        children: [
                          Icon(
                            statusIcon,
                            size: 18,
                            color: statusColor,
                          ), // Ikon kecil indikator
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              partnerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      const Divider(height: 1, thickness: 0.5),
                      const SizedBox(height: 12),

                      // Baris Bawah: Total Harga & Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Badge Status
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: statusColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              isAdjust
                                  ? 'ADJUSTMENT'
                                  : (trx['payment_status'] ??
                                        (isMasuk ? 'BELI STOK' : '-')),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // Nominal Uang
                          Text(
                            _formatCurrency(trx['total_amount']),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _colDarkGunmetal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
