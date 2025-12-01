import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/product_model.dart';
import 'add_product_page.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  // Variable untuk menyimpan list barang
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  // Fungsi mengambil data dari Supabase
  Future<void> _fetchProducts() async {
    try {
      final response = await Supabase.instance.client
          .from('products')
          .select()
          .order('name', ascending: true); // Urutkan berdasarkan nama

      final data = response as List<dynamic>;

      setState(() {
        // Ubah JSON jadi List<Product> menggunakan Model yang tadi kita buat
        _products = data.map((json) => Product.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Barang & Stok')),

      // --- PERUBAHAN MULAI DI SINI ---
      // Bungkus konten dengan RefreshIndicator
      body: RefreshIndicator(
        onRefresh: _fetchProducts, // Panggil fungsi ambil data saat ditarik
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _products.isEmpty
            ? const Center(child: Text('Belum ada data barang.'))
            // ListView harus punya physics agar bisa ditarik walau datanya sedikit
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _products.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final product = _products[index];
                  return ListTile(
                    // ... (Isi ListTile TETAP SAMA seperti sebelumnya) ...
                    leading: CircleAvatar(
                      backgroundColor: Colors.green[100],
                      child: Text(
                        product.baseUnit.substring(0, 1).toUpperCase(),
                      ),
                    ),
                    title: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('SKU: ${product.sku}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${product.stockQuantity} ${product.baseUnit}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        if (product.packagingUnit != null)
                          Text(
                            '(~ ${(product.stockQuantity / product.conversionFactor).toStringAsFixed(1)} ${product.packagingUnit})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Buka halaman tambah, dan tunggu hasilnya (await)
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductPage()),
          );

          // Jika result == true (berhasil simpan), refresh data
          if (result == true) {
            _fetchProducts();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
