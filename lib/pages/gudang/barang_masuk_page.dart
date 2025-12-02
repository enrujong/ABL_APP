import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/product_model.dart';

class BarangMasukPage extends StatefulWidget {
  const BarangMasukPage({super.key});

  @override
  State<BarangMasukPage> createState() => _BarangMasukPageState();
}

class _BarangMasukPageState extends State<BarangMasukPage> {
  // Data dari Database
  List<Product> _products = [];
  List<Map<String, dynamic>> _suppliers = [];

  // Pilihan User
  String? _selectedSupplierId;
  Product? _selectedProduct;

  // Inputan Form
  final _qtyController = TextEditingController(); // Jumlah Karton/Dus
  final _priceController = TextEditingController(); // Harga Beli per Karton/Dus

  // Keranjang Sementara (Barang yang mau disimpan)
  final List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // 1. Ambil data Produk & Supplier
  Future<void> _loadInitialData() async {
    final supabase = Supabase.instance.client;

    // Ambil Produk
    final productResponse = await supabase
        .from('products')
        .select()
        .order('name');
    final productsData = (productResponse as List)
        .map((e) => Product.fromJson(e))
        .toList();

    // Ambil Supplier
    final supplierResponse = await supabase
        .from('partners')
        .select()
        .eq('type', 'SUPPLIER');

    setState(() {
      _products = productsData;
      _suppliers = List<Map<String, dynamic>>.from(supplierResponse);
    });
  }

  // 2. Logika Tambah ke Keranjang
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

    // Konversi ke Satuan Kecil (Pcs) untuk Database
    final int qtyPcs = qtyDus * _selectedProduct!.conversionFactor;
    final double pricePcs = priceDus / _selectedProduct!.conversionFactor;

    setState(() {
      _cartItems.add({
        'product': _selectedProduct,
        'qty_dus': qtyDus, // Untuk tampilan user
        'price_dus': priceDus, // Untuk tampilan user
        'qty_pcs': qtyPcs, // Untuk database
        'price_pcs': pricePcs, // Untuk database
        'subtotal': priceDus * qtyDus,
      });

      // Reset input form kecil
      _selectedProduct = null;
      _qtyController.clear();
      _priceController.clear();
    });
  }

  // 3. Logika SIMPAN KE DATABASE (Update Stok & Average Cost)
  Future<void> _submitTransaction() async {
    if (_selectedSupplierId == null || _cartItems.isEmpty) return;

    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;

    try {
      // A. Hitung Total Transaksi
      double totalTransaction = _cartItems.fold(
        0,
        (sum, item) => sum + item['subtotal'],
      );

      // B. Simpan Header Transaksi
      final txnResponse = await supabase
          .from('transactions')
          .insert({
            'partner_id': int.parse(_selectedSupplierId!),
            'transaction_type': 'IN',
            'total_amount': totalTransaction,
            'payment_status': 'LUNAS', // Anggap lunas dulu
            'transaction_date': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final txnId = txnResponse['id'];

      // C. Loop setiap barang di keranjang
      for (var item in _cartItems) {
        Product p = item['product'];
        int newQty = item['qty_pcs'];
        double newPrice = item['price_pcs'];

        // --- RUMUS AVERAGE COST ---
        // (Stok Lama * Harga Lama) + (Stok Baru * Harga Baru) / (Total Stok)
        double oldTotalValue =
            p.stockQuantity * p.averageCostPrice; // Handle null
        double newTotalValue = oldTotalValue + (newQty * newPrice);
        int totalQty = p.stockQuantity + newQty;

        double newAvgCost = totalQty > 0 ? newTotalValue / totalQty : 0;

        // D. Update Produk (Stok & Harga Rata2)
        await supabase
            .from('products')
            .update({
              'stock_quantity': totalQty,
              'average_cost_price': newAvgCost,
            })
            .eq('id', p.id);

        // E. Simpan Detail Transaksi
        await supabase.from('transaction_items').insert({
          'transaction_id': txnId,
          'product_id': p.id,
          'quantity_packaging': item['qty_dus'], // History input user (Dus)
          'quantity_base': newQty, // Data real (Pcs)
          'price_per_unit': newPrice, // Harga modal per Pcs saat beli
          'subtotal': item['subtotal'],
        });
      }

      // ... kodingan update database di atas ...

      if (mounted) {
        // <--- TAMBAHKAN INI
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Stok Berhasil Masuk!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        // <--- TAMBAHKAN INI JUGA DI CATCH
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false); // <--- DAN DI SINI
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Input Barang Masuk (Inbound)')),
      body: Row(
        children: [
          // --- BAGIAN KIRI: Form Input ---
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pilih Supplier
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

                  // Form Barang
                  const Text(
                    'Tambah Barang ke List:',
                    style: TextStyle(fontWeight: FontWeight.bold),
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _qtyController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Jml (Dus/Krt)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Harga Beli per Dus',
                            border: OutlineInputBorder(),
                            prefixText: 'Rp ',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addToCart,
                      child: const Text('Masukkan ke List'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- BAGIAN KANAN: Keranjang / List Sementara ---
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'List Barang Masuk:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _cartItems.length,
                      separatorBuilder: (c, i) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = _cartItems[index];
                        final Product p = item['product'];
                        return ListTile(
                          title: Text(p.name),
                          subtitle: Text(
                            '${item['qty_dus']} ${p.packagingUnit ?? "Unit"} @ Rp ${item['price_dus']}',
                          ),
                          trailing: Text(
                            'Rp ${item['subtotal']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
                  const Divider(thickness: 2),
                  // Total & Button Simpan
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: Rp ${_cartItems.fold(0.0, (sum, item) => sum + (item['subtotal'] as double)).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                        onPressed: (_isLoading || _cartItems.isEmpty)
                            ? null
                            : _submitTransaction,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_alt),
                        label: const Text('PROSES STOK MASUK'),
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
