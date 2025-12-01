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

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      // JOIN TABLE: Kita ambil data transaksi + Nama Partnernya
      final response = await Supabase.instance.client
          .from('transactions')
          .select('*, partners(name)') // Syntax ajaib Supabase untuk Join
          .order(
            'transaction_date',
            ascending: false,
          ); // Urutkan dari yang terbaru

      setState(() {
        _transactions = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  // Helper untuk format tanggal & uang
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
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
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
          ? const Center(child: Text('Belum ada transaksi.'))
          : ListView.builder(
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final trx = _transactions[index];

                // Cek apakah ini Barang Masuk (IN) atau Keluar (OUT)
                final isBarangMasuk = trx['transaction_type'] == 'IN';
                final partnerName = trx['partners'] != null
                    ? trx['partners']['name']
                    : 'Unknown';

                // --- LOGIKA WARNA HYBRID ---

                // 1. Logika ICON (Sudut Pandang Stok Barang)
                // Barang Masuk = Hijau (Stok Nambah)
                // Barang Keluar = Merah (Stok Berkurang)
                final iconColor = isBarangMasuk ? Colors.green : Colors.red;
                final iconBgColor = isBarangMasuk
                    ? Colors.green[100]
                    : Colors.red[100];
                final iconData = isBarangMasuk
                    ? Icons.arrow_downward
                    : Icons.arrow_upward; // Panah Bawah (Masuk), Atas (Keluar)

                // 2. Logika UANG (Sudut Pandang Kas/Dompet)
                // Barang Masuk = Kita Bayar Supplier = Merah (Uang Keluar)
                // Barang Keluar = Toko Bayar Kita = Hijau (Uang Masuk)
                final moneyColor = isBarangMasuk ? Colors.red : Colors.green;
                final moneyPrefix = isBarangMasuk ? "- " : "+ ";

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  elevation: 2,
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) =>
                              TransactionDetailPage(transaction: trx),
                        ),
                      );
                    },
                    leading: CircleAvatar(
                      backgroundColor: iconBgColor, // Ikut logika Stok
                      child: Icon(
                        iconData, // Ikut logika Stok
                        color: iconColor,
                      ),
                    ),
                    title: Text(
                      partnerName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${trx['transaction_code'] ?? '-'} • ${_formatDate(trx['transaction_date'])}',
                        ),

                        // Label Status Pembayaran
                        if (!isBarangMasuk && trx['payment_status'] == 'TEMPO')
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Menunggu Pembayaran (Tempo)',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    trailing: Text(
                      // Tampilkan tanda +/- dan Warna sesuai logika Uang
                      '$moneyPrefix${_formatCurrency(trx['total_amount'])}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: moneyColor, // Ikut logika Uang
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
