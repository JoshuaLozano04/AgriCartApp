class Product {
  final String productId;
  final String sellerId;
  final String name;
  final String description;
  final String category;
  final double price;
  final int quantity;
  final String unit;
  final String location;
  final double? latitude;
  final double? longitude;
  final List<String> imagePaths;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  Product({
    required this.productId,
    required this.sellerId,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.quantity,
    required this.unit,
    required this.location,
    this.latitude,
    this.longitude,
    required this.imagePaths,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['product_id'] ?? '',
      sellerId: json['seller_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 0,
      unit: json['unit'] ?? 'piece',
      location: json['location'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      imagePaths: (json['image_paths'] ?? []).map<String>((path) => path.toString()).toList(),
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'seller_id': sellerId,
      'name': name,
      'description': description,
      'category': category,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'image_paths': imagePaths,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

