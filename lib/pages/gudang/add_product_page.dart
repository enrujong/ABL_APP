import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/product_model.dart';

class AddProductPage extends StatefulWidget {
  final Product? product;

  const AddProductPage({super.key, this.product});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _skuController;
  late TextEditingController _nameController;
  late TextEditingController _baseUnitController;
  late TextEditingController _packUnitController;
  late TextEditingController _conversionController;
  late TextEditingController _sellPriceController;

  // --- PALET WARNA ---
  final Color _colDarkGunmetal = const Color(0xFF2B2D42);
  final Color _colWhite = const Color(0xFFEDF2F4);
  final Color _colRed = const Color(0xFFEF233C);

  @override
  void initState() {
    super.initState();
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
        data['stock_quantity'] = 0;
        data['average_cost_price'] = 0;
        await Supabase.instance.client.from('products').insert(data);
      } else {
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
            backgroundColor: _colDarkGunmetal,
          ),
        );
        Navigator.pop(context, true);
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
    final isEdit = widget.product != null;

    return Scaffold(
      backgroundColor: _colWhite, // Background Putih Tulang
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Data Barang' : 'Tambah Barang Baru'),
        backgroundColor: _colDarkGunmetal,
        foregroundColor: _colWhite,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 600,
            ), // Batasi lebar agar rapi di Desktop
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- HEADER FORM ---
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _colDarkGunmetal.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isEdit ? Icons.edit_note : Icons.add_box,
                            size: 40,
                            color: _colDarkGunmetal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- SECTION 1: IDENTITAS ---
                      _buildSectionTitle('Identitas Barang'),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _skuController,
                        decoration: const InputDecoration(
                          labelText: 'SKU / Kode Barcode',
                          prefixIcon: Icon(Icons.qr_code),
                          hintText: 'Scan atau ketik kode unik',
                        ),
                        validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Produk',
                          prefixIcon: Icon(Icons.inventory_2),
                          hintText: 'Contoh: Indomie Goreng',
                        ),
                        validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                      ),

                      const SizedBox(height: 24),

                      // --- SECTION 2: HARGA ---
                      _buildSectionTitle('Harga Jual'),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _sellPriceController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          color: _colDarkGunmetal,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Harga Jual per Satuan Kecil',
                          prefixIcon: Icon(Icons.monetization_on),
                          prefixText: 'Rp ',
                          suffixText: ',00',
                        ),
                        validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                      ),

                      const SizedBox(height: 24),

                      // --- SECTION 3: SATUAN & KONVERSI ---
                      _buildSectionTitle('Satuan & Konversi'),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _baseUnitController,
                              decoration: const InputDecoration(
                                labelText: 'Satuan Kecil',
                                prefixIcon: Icon(Icons.widgets),
                                hintText: 'Pcs/Btl',
                              ),
                              validator: (v) =>
                                  v!.isEmpty ? 'Wajib diisi' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _packUnitController,
                              decoration: const InputDecoration(
                                labelText: 'Satuan Besar',
                                prefixIcon: Icon(Icons.inbox),
                                hintText: 'Dus/Box',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _conversionController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Isi per Dus (Konversi)',
                          prefixIcon: Icon(Icons.calculate),
                          helperText: '1 Dus isi berapa Pcs?',
                        ),
                        validator: (v) => v!.isEmpty ? 'Harus angka' : null,
                      ),

                      const SizedBox(height: 40),

                      // --- TOMBOL SIMPAN ---
                      SizedBox(
                        height: 55,
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _saveProduct,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(isEdit ? Icons.update : Icons.save),
                          label: Text(
                            isEdit
                                ? 'UPDATE DATA BARANG'
                                : 'SIMPAN BARANG BARU',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isEdit
                                ? Colors.orange[800]
                                : _colDarkGunmetal,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget Helper untuk Judul Section
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: _colRed,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _colDarkGunmetal,
          ),
        ),
      ],
    );
  }
}
