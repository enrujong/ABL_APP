import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  List<Map<String, dynamic>> _invoices = [];
  bool _isLoading = true;

  // --- WARNA ---
  final Color _colDarkGunmetal = const Color(0xFF2B2D42);
  final Color _colWhite = const Color(0xFFEDF2F4);
  final Color _colRed = const Color(0xFFEF233C);
  final Color _colGreen = const Color(0xFF2A9D8F);

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
  }

  Future<void> _fetchInvoices() async {
    try {
      final response = await Supabase.instance.client
          .from('transactions')
          .select('*, partners(name)')
          .eq('transaction_type', 'OUT')
          .eq('payment_status', 'TEMPO')
          .order('due_date', ascending: true);

      setState(() {
        _invoices = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsPaid(int id) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Pelunasan'),
        content: const Text('Tandai faktur ini sudah dibayar LUNAS?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _colGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('YA, LUNAS'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await Supabase.instance.client
            .from('transactions')
            .update({'payment_status': 'LUNAS'})
            .eq('id', id);

        _fetchInvoices();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pembayaran Berhasil Dicatat!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatCurrency(num amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    return DateFormat('dd MMM yyyy').format(DateTime.parse(dateStr));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colWhite,
      appBar: AppBar(
        title: const Text('Tagihan Belum Lunas'),
        backgroundColor: _colDarkGunmetal,
        foregroundColor: _colWhite,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _colDarkGunmetal))
          : _invoices.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada tagihan tertunggak!',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _invoices.length,
              separatorBuilder: (c, i) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final invoice = _invoices[index];
                final partnerName = invoice['partners'] != null
                    ? invoice['partners']['name']
                    : 'Unknown';

                final dueDate = DateTime.parse(invoice['due_date']);
                final isOverdue = DateTime.now().isAfter(dueDate);

                return Card(
                  elevation: 4,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // --- HEADER KARTU ---
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isOverdue
                              ? _colRed.withOpacity(0.1)
                              : Colors.grey[100],
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.store,
                                  color: _colDarkGunmetal,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  partnerName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: _colDarkGunmetal,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isOverdue ? _colRed : Colors.orange,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isOverdue ? 'JATUH TEMPO' : 'MENUNGGU',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // --- BODY KARTU ---
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Info Tagihan
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Tagihan',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatCurrency(invoice['total_amount']),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                    color: _colDarkGunmetal,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: isOverdue ? _colRed : Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Batas: ${_formatDate(invoice['due_date'])}',
                                      style: TextStyle(
                                        color: isOverdue
                                            ? _colRed
                                            : Colors.grey[600],
                                        fontWeight: isOverdue
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Tombol Aksi (Bulat / Ikon)
                            SizedBox(
                              height: 45,
                              child: ElevatedButton.icon(
                                onPressed: () => _markAsPaid(invoice['id']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _colGreen,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                ),
                                icon: const Icon(Icons.check, size: 18),
                                label: const Text(
                                  'LUNAS',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
