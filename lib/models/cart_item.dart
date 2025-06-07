class CartItem {
  final int id;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final int quantity;

  CartItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.quantity = 1,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    // If product details are nested under 'product', use those
    final product = json['product'] as Map<String, dynamic>?;
    final name = product != null ? product['name'] as String? : json['name'] as String?;
    final description = product != null ? product['description'] as String? : json['description'] as String?;
    final imageUrl = product != null ? product['image_url'] as String? : json['image_url'] as String?;
    final priceRaw = product != null ? product['price'] : json['price'];
    double price = 0.0;
    if (priceRaw is String) {
      price = double.tryParse(priceRaw) ?? 0.0;
    } else if (priceRaw is num) {
      price = priceRaw.toDouble();
    }
    return CartItem(
      id: json['id'] as int,
      name: name ?? '',
      description: description,
      price: price,
      imageUrl: imageUrl,
      quantity: json['quantity'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'quantity': quantity,
    };
  }

  int get productId {
    // If product details are nested, use their id, else fallback to this id
    return id;
  }
}
