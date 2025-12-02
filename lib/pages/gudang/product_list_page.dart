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
  // Dua variabel List: Satu untuk Master, Satu untuk Hasil Filter
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];

  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await Supabase.instance.client
          .from('products')
          .select()
          .order('name', ascending: true);

      final data = response as List<dynamic>;
      final products = data.map((json) => Product.fromJson(json)).toList();

      setState(() {
        _allProducts = products;
        _filteredProducts = products; // Awalnya tampilkan semua
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  // LOGIKA PENCARIAN
  void _runFilter(String keyword) {
    List<Product> results = [];
    if (keyword.isEmpty) {
      // Kalau kosong, kembalikan semua data
      results = _allProducts;
    } else {
      // Filter berdasarkan Nama ATAU SKU (Case Insensitive)
      results = _allProducts
          .where(
            (product) =>
                product.name.toLowerCase().contains(keyword.toLowerCase()) ||
                product.sku.toLowerCase().contains(keyword.toLowerCase()),
          )
          .toList();
    }

    // Update tampilan
    setState(() {
      _filteredProducts = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Barang & Stok'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  _runFilter(value), // Panggil fungsi filter tiap ngetik
              decoration: InputDecoration(
                hintText: 'Cari Nama Barang atau SKU...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _runFilter('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchProducts,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _filteredProducts.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 60, color: Colors.grey),
                    SizedBox(height: 10),
                    Text('Barang tidak ditemukan'),
                  ],
                ),
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _filteredProducts.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  // Warnai stok merah jika menipis
                  final isLowStock = product.stockQuantity < 10;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isLowStock
                          ? Colors.red[100]
                          : Colors.green[100],
                      child: Text(
                        product.baseUnit.substring(0, 1).toUpperCase(),
                      ),
                    ),
                    title: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'SKU: ${product.sku}\nHarga Jual: Rp ${product.sellingPrice}',
                    ), // Info tambahan
                    // --- UBAH BAGIAN TRAILING JADI ROW KECIL ---
                    trailing: Row(
                      mainAxisSize:
                          MainAxisSize.min, // Agar tidak memakan semua tempat
                      children: [
                        // Info Stok (Teks)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${product.stockQuantity} ${product.baseUnit}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isLowStock ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),

                        // Tombol Edit (Pensil)
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () async {
                            // Buka Halaman Form dengan membawa data produk (Mode Edit)
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddProductPage(product: product),
                              ),
                            );
                            if (result == true) {
                              _fetchProducts(); // Refresh list jika ada perubahan
                            }
                          },
                        ),

                        // Tombol Hapus (Sampah)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.grey),
                          onPressed: () async {
                            // Konfirmasi Hapus
                            final confirm = await showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Hapus Barang?'),
                                content: Text(
                                  'Yakin hapus ${product.name}? Data stok akan hilang.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Batal'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text(
                                      'Hapus',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              // Hapus dari Supabase
                              try {
                                await Supabase.instance.client
                                    .from('products')
                                    .delete()
                                    .eq('id', product.id);
                                _fetchProducts(); // Refresh
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Barang dihapus'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Gagal hapus (Mungkin sudah pernah dipakai transaksi)',
                                      ),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductPage()),
          );
          if (result == true) {
            _fetchProducts();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
