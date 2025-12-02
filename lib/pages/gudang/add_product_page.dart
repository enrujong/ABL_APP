import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/product_model.dart'; // Pastikan import model

class AddProductPage extends StatefulWidget {
  final Product? product; // Tambahan: Terima data produk (Opsional)

  const AddProductPage({super.key, this.product});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controller
  late TextEditingController _skuController;
  late TextEditingController _nameController;
  late TextEditingController _baseUnitController;
  late TextEditingController _packUnitController;
  late TextEditingController _conversionController;
  late TextEditingController _sellPriceController;

  @override
  void initState() {
    super.initState();
    // Jika ada data produk (Mode Edit), isi form dengan data lama
    // Jika tidak (Mode Tambah), isi kosong
    final p = widget.product;
    _skuController = TextEditingController(text: p?.sku ?? '');
    _nameController = TextEditingController(text: p?.name ?? '');
    _baseUnitController = TextEditingController(text: p?.baseUnit ?? '');
    _packUnitController = TextEditingController(text: p?.packagingUnit ?? '');
    _conversionController = TextEditingController(
      text: p?.conversionFactor.toString() ?? '1',
    );
    _sellPriceController = TextEditingController(
      text: p != null ? p.sellingPrice.toStringAsFixed(0) : '',
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final sellPrice =
          int.tryParse(
            _sellPriceController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0;
      final conversion = int.tryParse(_conversionController.text) ?? 1;

      final data = {
        'sku': _skuController.text.trim(),
        'name': _nameController.text.trim(),
        'base_unit': _baseUnitController.text.trim(),
        'packaging_unit': _packUnitController.text.trim().isEmpty
            ? null
            : _packUnitController.text.trim(),
        'conversion_factor': conversion,
        'selling_price': sellPrice,
      };

      if (widget.product == null) {
        // --- MODE INSERT (TAMBAH BARU) ---
        // Tambahan field default untuk barang baru
        data['stock_quantity'] = 0;
        data['average_cost_price'] = 0;

        await Supabase.instance.client.from('products').insert(data);
      } else {
        // --- MODE UPDATE (EDIT DATA) ---
        // Kita update berdasarkan ID
        await Supabase.instance.client
            .from('products')
            .update(data)
            .eq('id', widget.product!.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product == null
                  ? 'Barang Ditambahkan!'
                  : 'Barang Diperbarui!',
            ),
          ),
        );
        Navigator.pop(context, true); // Kembali & Refresh
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

  // Jangan lupa dispose controller biar hemat memori
  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _baseUnitController.dispose();
    _packUnitController.dispose();
    _conversionController.dispose();
    _sellPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ubah Judul Halaman sesuai mode
    final isEdit = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Barang' : 'Tambah Barang Baru'),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _skuController,
                  decoration: const InputDecoration(
                    labelText: 'SKU / Barcode',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                  // Jika Edit, SKU biasanya dikunci agar tidak kacau, tapi kalau mau dibuka boleh saja
                  // readOnly: isEdit,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Barang',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _sellPriceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga Jual',
                    border: OutlineInputBorder(),
                    prefixText: 'Rp ',
                  ),
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _baseUnitController,
                        decoration: const InputDecoration(
                          labelText: 'Satuan Kecil',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: TextFormField(
                        controller: _packUnitController,
                        decoration: const InputDecoration(
                          labelText: 'Satuan Besar',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _conversionController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Isi per Dus',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? 'Harus angka' : null,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveProduct,
                    icon: Icon(isEdit ? Icons.edit : Icons.save),
                    label: Text(isEdit ? 'UPDATE DATA' : 'SIMPAN BARANG'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEdit ? Colors.orange : Colors.green,
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
