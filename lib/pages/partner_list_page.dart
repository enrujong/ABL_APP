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

  // --- PALET WARNA BARU ---
  final Color _colDarkGunmetal = const Color(0xFF2B2D42);
  final Color _colCoolGrey = const Color(0xFF8D99AE);
  final Color _colWhite = const Color(0xFFEDF2F4);
  final Color _colRed = const Color(0xFFEF233C);

  @override
  void initState() {
    super.initState();
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

  // --- DIALOG TAMBAH / EDIT ---
  void _showPartnerDialog({Partner? partner}) {
    final isEdit = partner != null;
    final nameCtrl = TextEditingController(text: partner?.name ?? '');
    final addressCtrl = TextEditingController(text: partner?.address ?? '');
    final phoneCtrl = TextEditingController(text: partner?.phone ?? '');

    String selectedType = isEdit
        ? partner.type
        : (_tabController.index == 0 ? 'SUPPLIER' : 'CUSTOMER');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 450, // Lebar ideal untuk dialog form
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- HEADER DIALOG ---
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: _colDarkGunmetal,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isEdit ? Icons.edit_note : Icons.person_add,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEdit ? 'Edit Data Mitra' : 'Tambah Mitra Baru',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // --- FORM CONTENT ---
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nama PT / Toko',
                        prefixIcon: Icon(
                          Icons.business,
                          color: _colDarkGunmetal,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: addressCtrl,
                      decoration: InputDecoration(
                        labelText: 'Alamat Lengkap',
                        prefixIcon: Icon(Icons.map, color: _colDarkGunmetal),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'No. HP / Telp',
                              prefixIcon: Icon(
                                Icons.phone,
                                color: _colDarkGunmetal,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: InputDecoration(
                        labelText: 'Tipe Mitra',
                        prefixIcon: Icon(
                          Icons.category,
                          color: _colDarkGunmetal,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'SUPPLIER',
                          child: Text('Supplier (Gudang)'),
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
              ),

              const Divider(height: 1),

              // --- FOOTER BUTTONS ---
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isEdit) ...[
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _deletePartner(partner.id);
                        },
                        icon: Icon(Icons.delete_outline, color: _colRed),
                        label: Text('Hapus', style: TextStyle(color: _colRed)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                    ] else
                      const Spacer(),

                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Batal',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _colDarkGunmetal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.save),
                      label: Text(isEdit ? 'SIMPAN PERUBAHAN' : 'SIMPAN DATA'),
                      onPressed: () async {
                        if (nameCtrl.text.isEmpty) return;
                        try {
                          final data = {
                            'name': nameCtrl.text,
                            'type': selectedType,
                            'address': addressCtrl.text,
                            'phone': phoneCtrl.text,
                          };

                          if (isEdit) {
                            await Supabase.instance.client
                                .from('partners')
                                .update(data)
                                .eq('id', partner.id);
                          } else {
                            await Supabase.instance.client
                                .from('partners')
                                .insert(data);
                          }

                          Navigator.pop(context);
                          _fetchPartners();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEdit ? 'Data Diperbarui' : 'Mitra Disimpan',
                              ),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- LOGIKA HAPUS ---
  Future<void> _deletePartner(int id) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text(
          'Yakin hapus mitra ini? Data tidak bisa dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Hapus Permanen',
              style: TextStyle(color: _colRed, fontWeight: FontWeight.bold),
            ),
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

  Widget _buildList(String type) {
    final filtered = _allPartners.where((p) => p.type == type).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'SUPPLIER'
                  ? Icons.factory_outlined
                  : Icons.storefront_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada data $type',
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (c, i) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final p = filtered[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: _colDarkGunmetal.withOpacity(0.1),
              child: Icon(
                type == 'SUPPLIER' ? Icons.domain : Icons.store,
                color: _colDarkGunmetal,
              ),
            ),
            title: Text(
              p.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.address != null && p.address!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: _colCoolGrey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            p.address!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (p.phone != null && p.phone!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: _colCoolGrey),
                        const SizedBox(width: 4),
                        Text(
                          p.phone!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(
                Icons.edit,
                color: Colors.blue,
              ), // Ikon Pensil Biru
              tooltip: 'Edit / Hapus',
              onPressed: () =>
                  _showPartnerDialog(partner: p), // Buka dialog Edit
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colWhite,
      appBar: AppBar(
        title: const Text('Data Mitra (Supplier & Toko)'),
        backgroundColor: _colDarkGunmetal,
        foregroundColor: _colWhite,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _colRed, // Indikator Merah
          indicatorWeight: 4,
          labelColor: _colWhite,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'SUPPLIER (Gudang)', icon: Icon(Icons.factory)),
            Tab(text: 'CUSTOMER (Toko)', icon: Icon(Icons.store)),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _colDarkGunmetal))
          : TabBarView(
              controller: _tabController,
              children: [_buildList('SUPPLIER'), _buildList('CUSTOMER')],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPartnerDialog(), // Buka dialog Tambah
        backgroundColor: _colDarkGunmetal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Baru'),
      ),
    );
  }
}
