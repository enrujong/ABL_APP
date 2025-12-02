import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/partner_model.dart';

class PartnerListPage extends StatefulWidget {
  const PartnerListPage({super.key});

  @override
  State<PartnerListPage> createState() => _PartnerListPageState();
}

class _PartnerListPageState extends State<PartnerListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Partner> _allPartners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Kita punya 2 Tab: Supplier & Customer
    _tabController = TabController(length: 2, vsync: this);
    _fetchPartners();
  }

  Future<void> _fetchPartners() async {
    try {
      final response = await Supabase.instance.client
          .from('partners')
          .select()
          .order('name');

      setState(() {
        _allPartners = (response as List)
            .map((e) => Partner.fromJson(e))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // --- LOGIKA TAMBAH DATA (POP-UP) ---
  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    // Default tipe mengikuti tab yang sedang aktif (0=Supplier, 1=Customer)
    String selectedType = _tabController.index == 0 ? 'SUPPLIER' : 'CUSTOMER';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Mitra Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama PT / Toko'),
            ),
            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(labelText: 'Alamat'),
            ),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'No. HP / Telp'),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: selectedType,
              decoration: const InputDecoration(
                labelText: 'Tipe Mitra',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'SUPPLIER',
                  child: Text('Supplier (Penyedia)'),
                ),
                DropdownMenuItem(
                  value: 'CUSTOMER',
                  child: Text('Customer (Toko)'),
                ),
              ],
              onChanged: (val) => selectedType = val!,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              try {
                await Supabase.instance.client.from('partners').insert({
                  'name': nameCtrl.text,
                  'type': selectedType,
                  'address': addressCtrl.text,
                  'phone': phoneCtrl.text,
                });
                Navigator.pop(context); // Tutup dialog
                _fetchPartners(); // Refresh list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mitra Berhasil Disimpan')),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
              }
            },
            child: const Text('SIMPAN'),
          ),
        ],
      ),
    );
  }

  // --- LOGIKA HAPUS DATA ---
  Future<void> _deletePartner(int id) async {
    // Tanya user dulu yakin atau nggak
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Mitra?'),
        content: const Text(
          'Data yang sudah ada transaksi tidak bisa dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.from('partners').delete().eq('id', id);
        _fetchPartners();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal Hapus (Mungkin ada transaksi terkait)'),
            ),
          );
        }
      }
    }
  }

  // Widget untuk List
  Widget _buildList(String type) {
    final filtered = _allPartners.where((p) => p.type == type).toList();
    if (filtered.isEmpty) return Center(child: Text('Belum ada data $type'));

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final p = filtered[index];
        return ListTile(
          leading: Icon(
            type == 'SUPPLIER' ? Icons.factory : Icons.store,
            color: Colors.blue,
          ),
          title: Text(
            p.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('${p.address ?? "-"} • ${p.phone ?? "-"}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.grey),
            onPressed: () => _deletePartner(p.id),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Mitra (Supplier & Toko)'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'SUPPLIER (Gudang)', icon: Icon(Icons.factory)),
            Tab(text: 'CUSTOMER (Toko)', icon: Icon(Icons.store)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildList('SUPPLIER'), _buildList('CUSTOMER')],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        label: const Text('Tambah Baru'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
