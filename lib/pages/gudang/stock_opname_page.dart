import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/product_model.dart';

class StockOpnamePage extends StatefulWidget {
  const StockOpnamePage({super.key});

  @override
  State<StockOpnamePage> createState() => _StockOpnamePageState();
}

class _StockOpnamePageState extends State<StockOpnamePage> {
  // ... (Logika variabel & fungsi TETAP SAMA, salin dari file lama) ...
  // ...
  // AGAR AMAN, INI FULL CODE UI NYA:

  List<Product> _products = [];
  Product? _selectedProduct;
  String _adjustmentType = 'MINUS';
  final _qtyController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  final Color _colDarkRed = const Color(0xFFD90429); // Warna Warning
  final Color _colWhite = const Color(0xFFEDF2F4);

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final response = await Supabase.instance.client
        .from('products')
        .select()
        .order('name');
    setState(() {
      _products = (response as List).map((e) => Product.fromJson(e)).toList();
    });
  }

  Future<void> _submitAdjustment() async {
    // ... (Logika simpan sama persis seperti sebelumnya) ...
    if (_selectedProduct == null ||
        _qtyController.text.isEmpty ||
        _reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi semua data')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      int qtyInput = int.tryParse(_qtyController.text) ?? 0;
      int qtyChange = _adjustmentType == 'PLUS' ? qtyInput : -qtyInput;
      int newStock = _selectedProduct!.stockQuantity + qtyChange;
      if (newStock < 0) throw 'Stok tidak boleh menjadi negatif!';

      final trxResponse = await supabase
          .from('transactions')
          .insert({
            'transaction_type': 'ADJUST',
            'total_amount': 0,
            'payment_status': 'LUNAS',
            'notes': 'Stock Opname: ${_reasonController.text}',
            'transaction_date': DateTime.now().toUtc().toIso8601String(),
          })
          .select()
          .single();

      await supabase.from('transaction_items').insert({
        'transaction_id': trxResponse['id'],
        'product_id': _selectedProduct!.id,
        'quantity_base': qtyInput,
        'price_per_unit': 0,
        'subtotal': 0,
      });

      await supabase
          .from('products')
          .update({'stock_quantity': newStock})
          .eq('id', _selectedProduct!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stok berhasil disesuaikan!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colWhite,
      appBar: AppBar(
        title: const Text('Stock Opname (Koreksi)'),
        backgroundColor: _colDarkRed, // Merah karena ini hal sensitif
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(32.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 60,
                    color: _colDarkRed,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Formulir Penyesuaian Stok',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),

                  DropdownButtonFormField<Product>(
                    decoration: const InputDecoration(
                      labelText: 'Pilih Barang',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _selectedProduct,
                    items: _products
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text('${p.name} (Sisa: ${p.stockQuantity})'),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedProduct = val),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Jenis Koreksi:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        RadioListTile(
                          title: const Text(
                            'PENGURANGAN (Rusak/Hilang)',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          value: 'MINUS',
                          groupValue: _adjustmentType,
                          onChanged: (v) =>
                              setState(() => _adjustmentType = v!),
                        ),
                        RadioListTile(
                          title: const Text(
                            'PENAMBAHAN (Koreksi Masuk)',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          value: 'PLUS',
                          groupValue: _adjustmentType,
                          onChanged: (v) =>
                              setState(() => _adjustmentType = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah (Satuan Kecil)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Alasan (Wajib)',
                      border: OutlineInputBorder(),
                      hintText: 'Cth: Pecah di gudang',
                    ),
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submitAdjustment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _colDarkRed,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.save_as),
                      label: const Text('SIMPAN KOREKSI STOK'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
