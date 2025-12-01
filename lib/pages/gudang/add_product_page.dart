import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers untuk mengambil teks dari inputan
  final _skuController = TextEditingController();
  final _nameController = TextEditingController();
  final _baseUnitController = TextEditingController(); // misal: Pcs
  final _packUnitController = TextEditingController(); // misal: Karton
  final _conversionController = TextEditingController(text: '1'); // Default 1
  final _sellPriceController = TextEditingController();

  // Fungsi Simpan ke Supabase
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final sku = _skuController.text.trim();
      final name = _nameController.text.trim();
      final baseUnit = _baseUnitController.text.trim();
      final packUnit = _packUnitController.text.trim();
      final conversion = int.tryParse(_conversionController.text) ?? 1;
      final sellPrice =
          int.tryParse(
            _sellPriceController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0;

      // Kirim ke Database
      await Supabase.instance.client.from('products').insert({
        'sku': sku,
        'name': name,
        'base_unit': baseUnit,
        'packaging_unit': packUnit.isEmpty
            ? null
            : packUnit, // Kirim null jika kosong
        'conversion_factor': conversion,
        'stock_quantity': 0, // Barang baru stok pasti 0
        'selling_price': sellPrice,
        'average_cost_price': 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Barang berhasil ditambahkan!')),
        );
        Navigator.pop(context, true); // Kembali ke list & beritahu sukses
      }
    } catch (e) {
      if (mounted) {
        // Cek error spesifik (kode 23505 biasanya Duplicate Key/SKU kembar)
        final msg = e.toString().contains('23505')
            ? 'SKU/Barcode ini sudah terdaftar!'
            : 'Gagal menyimpan: $e';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
      if (mounted) setState(() => _isLoading = false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _baseUnitController.dispose();
    _packUnitController.dispose();
    _conversionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Barang Baru')),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 600,
          ), // Batasi lebar agar rapi di Desktop
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // 1. SKU & Nama
                TextFormField(
                  controller: _skuController,
                  decoration: const InputDecoration(
                    labelText: 'SKU / Barcode',
                    border: OutlineInputBorder(),
                    helperText: 'Scan barcode atau ketik kode unik',
                  ),
                  validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Barang',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _sellPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga Jual (per Pcs/Satuan Kecil)',
                    border: OutlineInputBorder(),
                    prefixText: 'Rp ',
                    helperText: 'Harga yang diberikan ke Toko',
                  ),
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 20),

                // 2. Satuan (Row agar sejajar)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _baseUnitController,
                        decoration: const InputDecoration(
                          labelText: 'Satuan Kecil (Pcs/Btl/Bks)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Wajib diisi' : null,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: TextFormField(
                        controller: _packUnitController,
                        decoration: const InputDecoration(
                          labelText: 'Satuan Besar (Dus/Box)',
                          border: OutlineInputBorder(),
                          hintText: 'Opsional',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 3. Konversi
                TextFormField(
                  controller: _conversionController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Isi per Dus (Konversi)',
                    border: OutlineInputBorder(),
                    helperText: 'Contoh: 1 Dus isi 24 Pcs, maka tulis 24',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Wajib diisi';
                    if (int.tryParse(value) == null) return 'Harus angka';
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // 4. Tombol Simpan
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveProduct,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isLoading ? 'Menyimpan...' : 'SIMPAN BARANG'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
