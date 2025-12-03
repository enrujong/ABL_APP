import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/product_model.dart';
import 'package:intl/intl.dart';

class BarangMasukPage extends StatefulWidget {
  const BarangMasukPage({super.key});

  @override
  State<BarangMasukPage> createState() => _BarangMasukPageState();
}

class _BarangMasukPageState extends State<BarangMasukPage> {
  // ... (Bagian Variabel & Fungsi Logika TETAP SAMA, tidak perlu diubah) ...
  // Salin logika initState, _loadInitialData, _addToCart, _submitTransaction dari file lama
  // KARENA PANJANG, SAYA HANYA TULIS BAGIAN UI (BUILD) DI BAWAH INI.
  // PASTIKAN KAMU MENYALIN LOGIKANYA JUGA JIKA KAMU REPLACE ALL.

  // AGAR AMAN, INI SAYA TULIS FULL CODE-NYA:

  List<Product> _products = [];
  List<Map<String, dynamic>> _suppliers = [];
  String? _selectedSupplierId;
  Product? _selectedProduct;
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  final List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = false;

  final Color _colDarkGunmetal = const Color(0xFF2B2D42);
  final Color _colWhite = const Color(0xFFEDF2F4);
  final Color _colGreen = const Color(0xFF2A9D8F);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final supabase = Supabase.instance.client;
    final productResponse = await supabase
        .from('products')
        .select()
        .order('name');
    final supplierResponse = await supabase
        .from('partners')
        .select()
        .eq('type', 'SUPPLIER');

    setState(() {
      _products = (productResponse as List)
          .map((e) => Product.fromJson(e))
          .toList();
      _suppliers = List<Map<String, dynamic>>.from(supplierResponse);
    });
  }

  void _addToCart() {
    if (_selectedProduct == null ||
        _qtyController.text.isEmpty ||
        _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi data barang dulu')),
      );
      return;
    }
    final int qtyDus = int.parse(_qtyController.text);
    final double priceDus = double.parse(_priceController.text);
    final int qtyPcs = qtyDus * _selectedProduct!.conversionFactor;
    final double pricePcs = priceDus / _selectedProduct!.conversionFactor;

    setState(() {
      _cartItems.add({
        'product': _selectedProduct,
        'qty_dus': qtyDus,
        'price_dus': priceDus,
        'qty_pcs': qtyPcs,
        'price_pcs': pricePcs,
        'subtotal': priceDus * qtyDus,
      });
      _selectedProduct = null;
      _qtyController.clear();
      _priceController.clear();
    });
  }

  Future<void> _submitTransaction() async {
    if (_selectedSupplierId == null || _cartItems.isEmpty) return;
    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;

    try {
      double totalTransaction = _cartItems.fold(
        0,
        (sum, item) => sum + item['subtotal'],
      );
      final txnResponse = await supabase
          .from('transactions')
          .insert({
            'partner_id': int.parse(_selectedSupplierId!),
            'transaction_type': 'IN',
            'total_amount': totalTransaction,
            'payment_status': 'LUNAS',
            'transaction_date': DateTime.now().toUtc().toIso8601String(),
          })
          .select()
          .single();

      final txnId = txnResponse['id'];

      for (var item in _cartItems) {
        Product p = item['product'];
        int newQty = item['qty_pcs'];
        double newPrice = item['price_pcs'];
        double oldTotalValue = p.stockQuantity * p.averageCostPrice;
        double newTotalValue = oldTotalValue + (newQty * newPrice);
        int totalQty = p.stockQuantity + newQty;
        double newAvgCost = totalQty > 0 ? newTotalValue / totalQty : 0;

        await supabase
            .from('products')
            .update({
              'stock_quantity': totalQty,
              'average_cost_price': newAvgCost,
            })
            .eq('id', p.id);

        await supabase.from('transaction_items').insert({
          'transaction_id': txnId,
          'product_id': p.id,
          'quantity_packaging': item['qty_dus'],
          'quantity_base': newQty,
          'price_per_unit': newPrice,
          'subtotal': item['subtotal'],
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Stok Berhasil Masuk!')));
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
      appBar: AppBar(
        title: const Text('Input Barang Masuk (Inbound)'),
        backgroundColor: _colDarkGunmetal,
        foregroundColor: _colWhite,
      ),
      body: Row(
        children: [
          // --- KIRI: FORM INPUT ---
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24.0),
              child: ListView(
                children: [
                  const Text(
                    'Data Supplier',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Pilih Supplier',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _selectedSupplierId,
                    items: _suppliers
                        .map(
                          (s) => DropdownMenuItem(
                            value: s['id'].toString(),
                            child: Text(s['name']),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedSupplierId = val),
                  ),
                  const Divider(height: 40),

                  const Text(
                    'Rincian Barang',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
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
                            child: Text(
                              '${p.name} (Satuan: ${p.packagingUnit ?? p.baseUnit})',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedProduct = val),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _qtyController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Jumlah (Satuan Besar)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Harga Beli / Satuan Besar',
                            border: OutlineInputBorder(),
                            prefixText: 'Rp ',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _addToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _colDarkGunmetal,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('TAMBAH KE LIST'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- KANAN: KERANJANG ---
          Expanded(
            flex: 3,
            child: Container(
              color: _colWhite,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'List Barang Masuk:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: ListView.separated(
                        itemCount: _cartItems.length,
                        separatorBuilder: (c, i) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _cartItems[index];
                          final Product p = item['product'];
                          return ListTile(
                            title: Text(
                              p.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${item['qty_dus']} ${p.packagingUnit ?? "Unit"} @ ${_formatCurrency(item['price_dus'])}',
                            ),
                            trailing: Text(
                              _formatCurrency(item['subtotal']),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            leading: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  setState(() => _cartItems.removeAt(index)),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Total & Button Simpan
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Pembelian:',
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            _formatCurrency(
                              _cartItems.fold(
                                0.0,
                                (sum, item) =>
                                    sum + (item['subtotal'] as double),
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _colGreen, // Tombol Hijau Sukses
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            elevation: 4,
                          ),
                          onPressed: (_isLoading || _cartItems.isEmpty)
                              ? null
                              : _submitTransaction,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_circle),
                          label: Text(
                            _isLoading ? 'MENYIMPAN...' : 'PROSES STOK MASUK',
                          ),
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
    );
  }
}
