import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/product_model.dart';
import 'package:intl/intl.dart';

class BarangKeluarPage extends StatefulWidget {
  const BarangKeluarPage({super.key});

  @override
  State<BarangKeluarPage> createState() => _BarangKeluarPageState();
}

class _BarangKeluarPageState extends State<BarangKeluarPage> {
  // --- VARIABLES ---
  List<Product> _products = [];
  List<Map<String, dynamic>> _customers = [];
  String? _selectedCustomerId;
  Product? _selectedProduct;
  final _qtyController = TextEditingController();
  final List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = false;
  String _paymentType = 'LUNAS';

  // --- PALET WARNA ---
  final Color _colDarkGunmetal = const Color(0xFF2B2D42);
  final Color _colWhite = const Color(0xFFEDF2F4);
  final Color _colRed = const Color(0xFFEF233C);
  final Color _colCoolGrey = const Color(0xFF8D99AE);

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
        .gt('stock_quantity', 0)
        .order('name');
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
    final int qtyDus = int.parse(_qtyController.text);
    final int qtyPcs = qtyDus * _selectedProduct!.conversionFactor;

    if (qtyPcs > _selectedProduct!.stockQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stok tidak cukup!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _cartItems.add({
        'product': _selectedProduct,
        'qty_dus': qtyDus,
        'qty_pcs': qtyPcs,
        'price': _selectedProduct!.sellingPrice,
        'subtotal': _selectedProduct!.sellingPrice * qtyPcs,
      });
      _qtyController.clear();
      _selectedProduct = null;
    });
  }

  Future<void> _submitTransaction() async {
    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih Customer dulu!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_cartItems.isEmpty) return;

    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;

    try {
      double totalAmount = _cartItems.fold(
        0,
        (sum, item) => sum + item['subtotal'],
      );
      DateTime? dueDate = _paymentType == 'TEMPO'
          ? DateTime.now().add(const Duration(days: 7))
          : null;

      final txnResponse = await supabase
          .from('transactions')
          .insert({
            'partner_id': int.parse(_selectedCustomerId!),
            'transaction_type': 'OUT',
            'total_amount': totalAmount,
            'payment_status': _paymentType,
            'due_date': dueDate?.toIso8601String(),
            'transaction_date': DateTime.now().toUtc().toIso8601String(),
          })
          .select()
          .single();

      final txnId = txnResponse['id'];

      for (var item in _cartItems) {
        Product p = item['product'];
        int qtyKeluar = item['qty_pcs'];
        int sisaStok = p.stockQuantity - qtyKeluar;

        await supabase
            .from('products')
            .update({'stock_quantity': sisaStok})
            .eq('id', p.id);
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Transaksi Berhasil!')));
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
      backgroundColor: _colWhite,
      appBar: AppBar(
        title: const Text('Buat Surat Jalan / Penjualan'),
        backgroundColor: _colDarkGunmetal,
        foregroundColor: _colWhite,
        elevation: 0,
      ),
      body: Row(
        children: [
          // --- PANEL KIRI: FORM ---
          Expanded(
            flex: 4, // 40% Lebar Layar
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Colors.black12)),
              ),
              child: ListView(
                children: [
                  const Text(
                    'Data Pelanggan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Pilih Toko/Customer',
                      prefixIcon: Icon(Icons.store),
                    ),
                    initialValue: _selectedCustomerId,
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

                  const SizedBox(height: 24),
                  const Text(
                    'Metode Pembayaran',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),

                  // Radio Button dalam Card
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        RadioListTile(
                          title: const Text(
                            'Cash / Lunas',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          value: 'LUNAS',
                          groupValue: _paymentType,
                          activeColor: _colDarkGunmetal,
                          onChanged: (v) => setState(() => _paymentType = v!),
                        ),
                        const Divider(height: 1),
                        RadioListTile(
                          title: const Text(
                            'Tempo (7 Hari)',
                            style: TextStyle(
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          value: 'TEMPO',
                          groupValue: _paymentType,
                          activeColor: Colors.deepOrange,
                          onChanged: (v) => setState(() => _paymentType = v!),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  const Text(
                    'Tambah Barang',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<Product>(
                    decoration: const InputDecoration(
                      labelText: 'Pilih Barang',
                      prefixIcon: Icon(Icons.inventory_2),
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
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah (Satuan Besar)',
                      prefixIcon: Icon(Icons.onetwothree),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _addToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _colDarkGunmetal,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('TAMBAH KE KERANJANG'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- PANEL KANAN: RINGKASAN ORDER ---
          Expanded(
            flex: 6, // 60% Lebar Layar
            child: Container(
              color: _colWhite, // Background sedikit abu
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Daftar Barang Keluar',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Chip(
                        label: Text('${_cartItems.length} Item'),
                        backgroundColor: _colCoolGrey.withOpacity(0.2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // LIST ITEM
                  Expanded(
                    child: _cartItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.remove_shopping_cart,
                                  size: 60,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Keranjang masih kosong',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _cartItems.length,
                            separatorBuilder: (c, i) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _cartItems[index];
                              final Product p = item['product'];
                              return Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _colCoolGrey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.inventory,
                                      color: _colDarkGunmetal,
                                    ),
                                  ),
                                  title: Text(
                                    p.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${item['qty_dus']} ${p.packagingUnit ?? "Dus"} x ${_formatCurrency(item['price'])}',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _formatCurrency(item['subtotal']),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => setState(
                                          () => _cartItems.removeAt(index),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(thickness: 2),
                  const SizedBox(height: 20),

                  // FOOTER: TOTAL & ACTION
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Tagihan:',
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
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _colDarkGunmetal,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      SizedBox(
                        height: 55,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _colRed, // Tombol Merah (Penting)
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
                                  ),
                                )
                              : const Icon(Icons.print),
                          label: Text(
                            _isLoading ? 'MEMPROSES...' : 'CETAK SURAT JALAN',
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
