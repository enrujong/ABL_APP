import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/product_model.dart';

class BarangKeluarPage extends StatefulWidget {
  const BarangKeluarPage({super.key});

  @override
  State<BarangKeluarPage> createState() => _BarangKeluarPageState();
}

class _BarangKeluarPageState extends State<BarangKeluarPage> {
  // Data
  List<Product> _products = [];
  List<Map<String, dynamic>> _customers = [];

  // Inputan
  String? _selectedCustomerId;
  Product? _selectedProduct;
  final _qtyController = TextEditingController();

  // Keranjang & Status
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = false;
  String _paymentType = 'LUNAS'; // Default Cash

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final supabase = Supabase.instance.client;

    // 1. Ambil Produk yang Stoknya > 0 saja
    final productResponse = await supabase
        .from('products')
        .select()
        .gt('stock_quantity', 0) // Hanya tampilkan yg ada stok
        .order('name');

    // 2. Ambil Customer (Toko)
    final customerResponse = await supabase
        .from('partners')
        .select()
        .eq('type', 'CUSTOMER');

    if (mounted) {
      setState(() {
        _products = (productResponse as List)
            .map((e) => Product.fromJson(e))
            .toList();
        _customers = List<Map<String, dynamic>>.from(customerResponse);
      });
    }
  }

  void _addToCart() {
    if (_selectedProduct == null || _qtyController.text.isEmpty) return;

    final int qtyDusRequest = int.parse(_qtyController.text);
    final int qtyPcsRequest =
        qtyDusRequest * _selectedProduct!.conversionFactor;

    // --- VALIDASI STOK KRUSIAL ---
    if (qtyPcsRequest > _selectedProduct!.stockQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stok tidak cukup!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Cek apakah barang ini sudah ada di keranjang?
    // (Sederhananya kita skip dulu validasi keranjang ganda utk tutorial ini)

    setState(() {
      _cartItems.add({
        'product': _selectedProduct,
        'qty_dus': qtyDusRequest,
        'qty_pcs': qtyPcsRequest,
        'price':
            _selectedProduct!.sellingPrice, // Pakai Harga Jual bukan Harga Beli
        'subtotal':
            _selectedProduct!.sellingPrice *
            qtyPcsRequest, // Asumsi harga jual per Pcs
      });

      _qtyController.clear();
      _selectedProduct = null;
    });
  }

  Future<void> _submitTransaction() async {
    if (_selectedCustomerId == null || _cartItems.isEmpty) return;

    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;

    try {
      double totalAmount = _cartItems.fold(
        0,
        (sum, item) => sum + item['subtotal'],
      );

      // Tentukan Jatuh Tempo (Kalau Tempo +7 hari)
      DateTime? dueDate;
      if (_paymentType == 'TEMPO') {
        dueDate = DateTime.now().add(const Duration(days: 7));
      } else {
        dueDate = DateTime.now();
      }

      // 1. Simpan Header Transaksi
      final txnResponse = await supabase
          .from('transactions')
          .insert({
            'partner_id': int.parse(_selectedCustomerId!),
            'transaction_type': 'OUT', // PENTING: OUT
            'total_amount': totalAmount,
            'payment_status': _paymentType,
            'due_date': dueDate.toIso8601String(),
            'transaction_date': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final txnId = txnResponse['id'];

      // 2. Loop Keranjang
      for (var item in _cartItems) {
        Product p = item['product'];
        int qtyKeluar = item['qty_pcs']; // integer

        // A. Kurangi Stok
        int sisaStok = p.stockQuantity - qtyKeluar;

        await supabase
            .from('products')
            .update({'stock_quantity': sisaStok})
            .eq('id', p.id);

        // B. Simpan Detail
        await supabase.from('transaction_items').insert({
          'transaction_id': txnId,
          'product_id': p.id,
          'quantity_packaging': item['qty_dus'],
          'quantity_base': qtyKeluar,
          'price_per_unit': item['price'],
          'subtotal': item['subtotal'],
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaksi Berhasil! Stok Terpotong.')),
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
        title: const Text('Buat Surat Jalan / Penjualan'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          // KIRI: Form
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Pilih Toko/Customer',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedCustomerId,
                    items: _customers
                        .map(
                          (c) => DropdownMenuItem(
                            value: c['id'].toString(),
                            child: Text(c['name']),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedCustomerId = val),
                  ),
                  const SizedBox(height: 20),

                  // Radio Button Pembayaran
                  Row(
                    children: [
                      const Text(
                        'Pembayaran: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Radio(
                        value: 'LUNAS',
                        groupValue: _paymentType,
                        onChanged: (v) => setState(() => _paymentType = v!),
                      ),
                      const Text('Cash/Lunas'),
                      Radio(
                        value: 'TEMPO',
                        groupValue: _paymentType,
                        onChanged: (v) => setState(() => _paymentType = v!),
                      ),
                      const Text('Tempo (7 Hari)'),
                    ],
                  ),
                  const Divider(height: 30),

                  // Pilih Barang
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
                              '${p.name} (Sisa: ${p.stockQuantity} ${p.baseUnit})',
                            ), // Tampilkan sisa stok di dropdown
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedProduct = val),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah (Dus/Karton)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addToCart,
                      child: const Text('Tambah ke Keranjang'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // KANAN: Keranjang
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.blue[50],
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Daftar Barang Keluar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
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
                            '${item['qty_dus']} ${p.packagingUnit} (= ${item['qty_pcs']} ${p.baseUnit})',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                setState(() => _cartItems.removeAt(index)),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      onPressed: (_isLoading || _cartItems.isEmpty)
                          ? null
                          : _submitTransaction,
                      icon: const Icon(Icons.print, color: Colors.white),
                      label: const Text(
                        'CETAK SURAT JALAN & KURANGI STOK',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
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
