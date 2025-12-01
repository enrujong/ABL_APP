import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/product_model.dart';

class StockOpnamePage extends StatefulWidget {
  const StockOpnamePage({super.key});

  @override
  State<StockOpnamePage> createState() => _StockOpnamePageState();
}

class _StockOpnamePageState extends State<StockOpnamePage> {
  List<Product> _products = [];
  Product? _selectedProduct;

  // 'PLUS' = Nemu barang (Tambah), 'MINUS' = Barang rusak/hilang (Kurang)
  String _adjustmentType = 'MINUS';
  final _qtyController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isLoading = false;

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

      // Jika jenisnya MINUS, jadikan negatif
      int qtyChange = _adjustmentType == 'PLUS' ? qtyInput : -qtyInput;

      // Hitung stok baru
      int newStock = _selectedProduct!.stockQuantity + qtyChange;
      if (newStock < 0) {
        throw 'Stok tidak boleh menjadi negatif!';
      }

      // 1. Catat di Transaksi (Header)
      // Kita pakai total_amount 0 karena ini bukan jual beli, tapi kerugian/koreksi
      final trxResponse = await supabase
          .from('transactions')
          .insert({
            'transaction_type': 'ADJUST',
            'total_amount': 0,
            'payment_status': 'LUNAS',
            'notes':
                'Stock Opname: ${_reasonController.text}', // Simpan alasan di notes
            'transaction_date': DateTime.now().toUtc().toIso8601String(),
          })
          .select()
          .single();

      // 2. Catat Detail Item
      await supabase.from('transaction_items').insert({
        'transaction_id': trxResponse['id'],
        'product_id': _selectedProduct!.id,
        'quantity_base': qtyInput, // Catat jumlah fisiknya
        'price_per_unit': 0,
        'subtotal': 0,
      });

      // 3. Update Stok Produk
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
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Opname (Penyesuaian)'),
        backgroundColor: Colors.orange, // Warna peringatan
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            const Icon(Icons.build_circle, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              'Gunakan fitur ini jika ada selisih stok fisik, barang rusak, atau hilang.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // 1. Pilih Barang
            DropdownButtonFormField<Product>(
              decoration: const InputDecoration(
                labelText: 'Pilih Barang',
                border: OutlineInputBorder(),
              ),
              value: _selectedProduct,
              items: _products
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(
                        '${p.name} (Stok Komputer: ${p.stockQuantity} ${p.baseUnit})',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedProduct = val),
            ),
            const SizedBox(height: 20),

            // 2. Jenis Penyesuaian (Radio)
            const Text(
              'Jenis Penyesuaian:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Radio(
                  value: 'MINUS',
                  groupValue: _adjustmentType,
                  onChanged: (v) => setState(() => _adjustmentType = v!),
                ),
                const Text(
                  'PENGURANGAN (Rusak/Hilang)',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
            Row(
              children: [
                Radio(
                  value: 'PLUS',
                  groupValue: _adjustmentType,
                  onChanged: (v) => setState(() => _adjustmentType = v!),
                ),
                const Text(
                  'PENAMBAHAN (Koreksi Masuk)',
                  style: TextStyle(color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. Jumlah & Alasan
            TextFormField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah Fisik (Satuan Kecil/Pcs)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Alasan Penyesuaian (Wajib)',
                border: OutlineInputBorder(),
                hintText: 'Contoh: Pecah saat bongkar muat',
              ),
            ),
            const SizedBox(height: 40),

            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitAdjustment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.update),
                label: const Text('UPDATE STOK'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
