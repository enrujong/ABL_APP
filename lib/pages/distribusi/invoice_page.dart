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
          .eq('payment_status', 'TEMPO') // Hanya ambil yang belum lunas
          .order(
            'due_date',
            ascending: true,
          ); // Urutkan dari yang paling mendesak (jatuh tempo duluan)

      setState(() {
        _invoices = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsPaid(int id) async {
    // Konfirmasi dulu
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
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Lunas'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await Supabase.instance.client
            .from('transactions')
            .update({'payment_status': 'LUNAS'}) // Update jadi LUNAS
            .eq('id', id);

        // Refresh list
        _fetchInvoices();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pembayaran Berhasil Dicatat!')),
          );
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
      appBar: AppBar(title: const Text('Tagihan Belum Lunas')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _invoices.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 80,
                    color: Colors.green,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Tidak ada tagihan tertunggak!',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _invoices.length,
              itemBuilder: (context, index) {
                final invoice = _invoices[index];
                final partnerName = invoice['partners'] != null
                    ? invoice['partners']['name']
                    : 'Unknown';

                // Cek apakah sudah lewat jatuh tempo?
                final dueDate = DateTime.parse(invoice['due_date']);
                final isOverdue = DateTime.now().isAfter(dueDate);

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  // Kalau telat bayar, kasih border merah biar Admin aware
                  shape: isOverdue
                      ? RoundedRectangleBorder(
                          side: const BorderSide(color: Colors.red, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        )
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              partnerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Chip(
                              label: Text(
                                isOverdue
                                    ? 'Telat Jarak Tempo'
                                    : 'Belum Jatuh Tempo',
                              ),
                              backgroundColor: isOverdue
                                  ? Colors.red[100]
                                  : Colors.orange[100],
                              labelStyle: TextStyle(
                                color: isOverdue
                                    ? Colors.red
                                    : Colors.deepOrange,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Tagihan:',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatCurrency(invoice['total_amount']),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Jatuh Tempo:',
                                  style: TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(invoice['due_date']),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isOverdue
                                        ? Colors.red
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _markAsPaid(invoice['id']),
                            icon: const Icon(Icons.payment),
                            label: const Text('TERIMA PEMBAYARAN (LUNAS)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
