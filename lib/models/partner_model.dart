class Partner {
  final int id;
  final String name;
  final String type; // 'SUPPLIER' atau 'CUSTOMER'
  final String? address;
  final String? phone;

  Partner({
    required this.id,
    required this.name,
    required this.type,
    this.address,
    this.phone,
  });

  factory Partner.fromJson(Map<String, dynamic> json) {
    return Partner(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      address: json['address'],
      phone: json['phone'],
    );
  }
}
