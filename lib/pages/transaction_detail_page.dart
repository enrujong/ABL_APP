import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../utils/pdf_helper.dart';

class TransactionDetailPage extends StatefulWidget {
  final Map<String, dynamic>
  transaction; // Kita lempar data header transaksinya

  const TransactionDetailPage({super.key, required this.transaction});

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    try {
      final trxId = widget.transaction['id'];

      // JOIN TABLE: Ambil detail item + Nama Produknya
      final response = await Supabase.instance.client
          .from('transaction_items')
          .select('*, products(name, base_unit, packaging_unit)')
          .eq('transaction_id', trxId);

      setState(() {
        _items = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(num amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String _formatDate(String dateStr) {
    return DateFormat(
      'dd MMM yyyy, HH:mm',
    ).format(DateTime.parse(dateStr).toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final trx = widget.transaction;
    final partnerName = trx['partners'] != null
        ? trx['partners']['name']
        : 'Unknown';
    final isMasuk = trx['transaction_type'] == 'IN';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        backgroundColor: isMasuk ? Colors.green : Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // Tombol Print Pura-pura (Nanti kita aktifkan fitur PDF di sini)
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Cetak Struk/Faktur',
            onPressed: () async {
              // Panggil Fungsi PDF Helper
              await PdfHelper.printInvoice(widget.transaction, _items);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // --- HEADER STRUK ---
          Container(
            padding: const EdgeInsets.all(20),
            color: isMasuk ? Colors.green[50] : Colors.blue[50],
            child: Column(
              children: [
                Text(
                  isMasuk ? 'BUKTI BARANG MASUK' : 'SURAT JALAN / INVOICE',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _formatCurrency(trx['total_amount']),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Mitra:', style: TextStyle(color: Colors.grey)),
                    Text(
                      partnerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tanggal:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      _formatDate(trx['transaction_date']),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Status:', style: TextStyle(color: Colors.grey)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: trx['payment_status'] == 'LUNAS'
                            ? Colors.green
                            : Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        trx['payment_status'] ?? '-',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // --- LIST BARANG ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (c, i) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final prod = item['products'];
                      final prodName = prod != null
                          ? prod['name']
                          : 'Unknown Product';
                      final unit = prod != null
                          ? (prod['packaging_unit'] ?? prod['base_unit'])
                          : '';

                      return ListTile(
                        title: Text(
                          prodName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${item['quantity_packaging']} $unit  x  ${_formatCurrency(item['price_per_unit'])}',
                        ),
                        trailing: Text(
                          _formatCurrency(item['subtotal']),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
