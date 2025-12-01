class Product {
  final int id;
  final String sku;
  final String name;
  final String baseUnit;
  final String? packagingUnit; // Bisa null
  final int conversionFactor;
  final int stockQuantity;
  final double averageCostPrice;
  final double sellingPrice;

  Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.baseUnit,
    this.packagingUnit,
    required this.conversionFactor,
    required this.stockQuantity,
    required this.averageCostPrice,
    required this.sellingPrice,
  });

  // Fungsi untuk mengubah JSON dari Supabase menjadi Object Dart
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      sku: json['sku'],
      name: json['name'],
      baseUnit:
          json['base_unit'], // Perhatikan nama kolom di DB pakai underscore
      packagingUnit: json['packaging_unit'],
      conversionFactor: json['conversion_factor'] ?? 1,
      stockQuantity: json['stock_quantity'] ?? 0,
      averageCostPrice: (json['average_cost_price'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['selling_price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
